# 👤 User Documentation

## 🚀 How to Run
1.  **Preparation**: Ensure your `/etc/hosts` has the entry: `127.0.0.1 natrodri.42.fr`.
2.  **Deployment**: Simply run `make` at the root. This will create the data folders, build the images, and start the services.
3.  **Shut down**: Run `make down` to stop everything.
4.  **Clean Up**: Run `make fclean` to wipe all images, containers, and volumes.

## 🌐 Accessing the Services
* **WordPress Site**: [https://natrodri.42.fr](https://natrodri.42.fr)
* **WP-Admin**: [https://natrodri.42.fr/wp-admin](https://natrodri.42.fr/wp-admin)

## 🔐 Credentials
* **Admin**: Cannot be named "admin" or "administrator" (Security rule).
* **Database**: Check the `srcs/.env` file. **Note**: No passwords are hardcoded in Dockerfiles.

## ✅ Health Check
To verify if the stack is healthy:
* `docker ps`: All containers should show "Up".
* `docker network inspect inception`: Verify all 3 containers are on the same network.