build:
	docker compose build

down:
	docker compose down

up:
	docker compose up

clean:
	docker volume rm octoprint_data
