ARG PYTHON_BASE_IMAGE=3.8-slim-buster

FROM ubuntu AS s6build
ARG S6_RELEASE
ENV S6_VERSION ${S6_RELEASE:-v2.1.0.0}
RUN apt-get update && apt-get install -y curl
RUN echo "$(dpkg --print-architecture)"
WORKDIR /tmp
RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
  amd64) ARCH='amd64';; \
  arm64) ARCH='aarch64';; \
  armhf) ARCH='armhf';; \
  *) echo "unsupported architecture: $(dpkg --print-architecture)"; exit 1 ;; \
  esac \
  && set -ex \
  && echo $S6_VERSION \
  && curl -fsSLO "https://github.com/just-containers/s6-overlay/releases/download/$S6_VERSION/s6-overlay-$ARCH.tar.gz"


FROM python:${PYTHON_BASE_IMAGE} AS build

ARG octoprint_ref
ENV octoprint_ref ${octoprint_ref:-master}

RUN apt-get update && apt-get install -y \
  avrdude \
  build-essential \
  cmake \
  curl \
  imagemagick \
  ffmpeg \
  fontconfig \
  g++ \
  git \
  haproxy \
  libjpeg-dev \
  libjpeg62-turbo \
  libprotobuf-dev \
  libv4l-dev \
  openssh-client \
  v4l-utils \
  xz-utils \
  zlib1g-dev \
  python2 \
  python-dev \
  libffi-dev \
  virtualenv

# unpack s6
COPY --from=s6build /tmp /tmp
RUN s6tar=$(find /tmp -name "s6-overlay-*.tar.gz") \
  && tar xzf $s6tar -C / \
  && rm /tmp/s6-overlay-*.tar.gz

# Install octoprint
RUN	curl -fsSLO --compressed --retry 3 --retry-delay 10 \
  https://github.com/OctoPrint/OctoPrint/archive/${octoprint_ref}.tar.gz \
	&& mkdir -p /opt/octoprint \
  && tar xzf ${octoprint_ref}.tar.gz --strip-components 1 -C /opt/octoprint --no-same-owner \
  && rm ${octoprint_ref}.tar.gz

WORKDIR /opt/octoprint
RUN pip --disable-pip-version-check --no-cache-dir install .
RUN mkdir -p /octoprint/octoprint /octoprint/plugins /octoprint/klipper

# Install mjpg-streamer
RUN curl -fsSLO --compressed --retry 3 --retry-delay 10 \
  https://github.com/jacksonliam/mjpg-streamer/archive/master.tar.gz \
  && mkdir /mjpg \
  && tar xzf master.tar.gz -C /mjpg \
  && rm master.tar.gz

WORKDIR /mjpg/mjpg-streamer-master/mjpg-streamer-experimental
RUN make
RUN make install

# Copy services into s6 servicedir
COPY root /

# set WORKDIR
WORKDIR /opt
# Clone Klipper repo
RUN git clone https://github.com/Klipper3d/klipper
# Create Klipper environment
RUN virtualenv -p python2 ./klipper/klippy-env
# Install Klipper dependencies
RUN ./klipper/klippy-env/bin/pip --disable-pip-version-check install --no-cache-dir -r ./klipper/scripts/klippy-requirements.txt

# set WORKDIR 
WORKDIR /octoprint

# Set default ENV vars
ENV CAMERA_DEV /dev/video0
ENV MJPG_STREAMER_INPUT -n -r 640x480
ENV PIP_USER true
ENV PYTHONUSERBASE /octoprint/plugins
ENV PATH "${PYTHONUSERBASE}/bin:${PATH}"
ENV KLIPPER_LOG /tmp/klippy.log

# Copy printer.cfg file
COPY printer.cfg /octoprint/klipper/printer.cfg

# Install extra plugins for Octoprint
RUN /usr/local/bin/python -m pip --disable-pip-version-check --no-cache-dir install \
  https://github.com/thelastWallE/OctoprintKlipperPlugin/archive/master.zip

WORKDIR /octoprint
VOLUME /octoprint

# port to access haproxy frontend
EXPOSE 80
ENTRYPOINT ["/init"]
