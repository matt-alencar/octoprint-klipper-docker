FROM octoprint/octoprint:latest

ARG KLIPPER_BRANCH="v0.11.0"
ARG KLIPPER_VENV_DIR=/opt/klipper/klippy-env

#RUN apt-get update && apt-get install -y \
#  virtualenv

# Copy services
COPY root /

ENV PIP_USER false

# set WORKDIR
WORKDIR /opt
RUN git clone --single-branch --branch ${KLIPPER_BRANCH} https://github.com/Klipper3d/klipper.git klipper
RUN python3 -m venv ${KLIPPER_VENV_DIR}
RUN ${KLIPPER_VENV_DIR}/bin/pip --disable-pip-version-check install --no-cache-dir -r /opt/klipper/scripts/klippy-requirements.txt

ENV KLIPPER_LOG_FILE /octoprint/klipper/klippy.log
ENV KLIPPER_PRINTER_FILE /octoprint/klipper/printer.cfg

# Copy dummy printer.cfg file
COPY printer.cfg ${KLIPPER_PRINTER_FILE}

ENV PIP_USER true

# Install extra plugins for Octoprint
RUN /usr/local/bin/python -m pip --disable-pip-version-check --no-cache-dir install \
  https://github.com/thelastWallE/OctoprintKlipperPlugin/archive/master.zip


WORKDIR /octoprint
VOLUME /octoprint

# port to access haproxy frontend
EXPOSE 80
ENTRYPOINT ["/init"]
