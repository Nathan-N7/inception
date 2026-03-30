# 💻 Developer Documentation

## 📂 Project Structure
* `srcs/`: Main configuration files.
* `srcs/requirements/`: Contains Dockerfiles and setup scripts for each service.
* `srcs/docker-compose.yml`: The orchestrator of the infrastructure.

## 🏗️ Technical Specifications
* **Base OS**: Debian (Penultimate stable version).
* **NGINX**: Configured with **TLSv1.2/v1.3 only**. Port 443 is the only entry point.
* **WordPress + PHP-FPM**: PHP-FPM is configured to listen on port 9000 to communicate with NGINX.
* **MariaDB**: The database engine, isolated from the web server.

## 💾 Persistence Layer
Data is stored on the host at:
* `/home/natrodri/data/wordpress`
* `/home/natrodri/data/mariadb`

## 🛠️ Useful Commands for Evaluation
If the evaluator asks for a "brief modification":
* Check logs: `docker logs <container_name>`
* Enter a container: `docker exec -it <container_name> sh`
* Rebuild a single service: `docker-compose build <service_name>`