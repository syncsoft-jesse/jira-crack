.PHONY: up down shell java jar clean logs

# Start Java container
up:
	docker compose up -d

# Stop Java container
down:
	docker compose down

# Get interactive shell
shell:
	docker compose exec java bash

# Run Java command (usage: make java ARGS="-version")
java:
	docker compose exec java java $(ARGS)

# Run JAR file (usage: make jar FILE=myapp.jar)
jar:
	docker compose exec java java -jar $(FILE)

# Run JAR with debug (usage: make debug FILE=myapp.jar)
debug:
	docker compose exec java java -agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=*:5005 -jar $(FILE)

# Show Java version
version:
	docker compose exec java java -version

# View logs
logs:
	docker compose logs -f

# Clean up volumes
clean:
	docker compose down -v

# Rebuild container
rebuild:
	docker compose down
	docker compose up -d --build
