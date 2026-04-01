*This project has been created as part of the 42 curriculum by natrodri.*

## 📌 Project Overview
Inception is a System Administration project focused on Docker. The goal is to build a complete infrastructure from scratch, using custom Dockerfiles based on **Debian**, ensuring that each service (NGINX, WordPress, MariaDB) runs in its own isolated container.

## 🛠️ Design Choices (The "Why")
During the evaluation, you might be asked to justify these:

* **Virtual Machines vs Docker**: VMs virtualize hardware (heavy, slow boot), while Docker virtualizes the OS kernel (lightweight, fast, shares resources with the host).
* **PID 1 & Init Systems**: Each container runs only one service. We avoid "hacky" scripts like `tail -f` to keep the process running. The service itself must run in the foreground to be managed correctly by Docker as PID 1.
* **Docker Network**: A dedicated bridge network is used for internal communication. Using `network: host` or `--link` is strictly forbidden to ensure proper isolation.
* **Volumes**: We use **Named Volumes** mapped to `/home/natrodri/data/`. This ensures data persists even if containers are deleted. **Bind mounts** were avoided for persistent data as per the subject's constraints.
* **Secrets vs .env**: Sensitive data (DB passwords) should be handled via Docker Secrets. The `.env` file is used for general environment variables.

## 🤖 AI Usage & Learning
AI was used as a tutor to explain networking concepts (like how `php-fpm` listens on port 9000) and to help debug Dockerfile syntax. Every line of code was manually written and tested to ensure 100% understanding, avoiding "copy-paste" traps that lead to project failure.