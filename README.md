# local-web

An alpine apache PHP local server with CA self-sign SSL and build-in easy site setup command.

> _**♠️ Developed By [Thuku](https://github.com/xthukuh)**_

### Components
- Apache2
- php83
- composer
- Certificate Authority selfsign

### Docker Container

```sh
cd local-web

# container: run - verbose
# docker compose up --build
docker compose up

# container: run - daemon
# docker compose up --build -d
docker compose up -d

# container: shutdown
docker compose down

# container: show runtime logs
docker compose logs -f

# docker show all containers
docker ps -a
```

### Docker Shell

To access running container shell terminal run:

```sh
# docker exec -it web sh
# docker exec -it web zsh
docker exec -it web bash
```

While in shell run for built-in commands help docs:

```sh
setup --help
selfsign --help
```

### Docker Build & Push

Build and push to docker hub  [xthukuh/local-web](https://hub.docker.com/repository/docker/xthukuh/local-web/general)

```sh
# build image
docker build -t xthukuh/local-web:latest .
docker build -t xthukuh/local-web:v1.0.0 .

# push image to repo
docker push xthukuh/local-web:latest
docker push xthukuh/local-web:v1.0.0
```

### Setup

`./www/` mounts to working directory `/etc/www/` on the container.
- auto-created on container start-up if not exists
- `./www/logs` Contains website access and error logs
- `./www/config` Contains vhosts config SSL files
- `./www/html` Contains server website files

`./docker/*` mirrors container `/etc/` files:
- `/etc/apache2/*`
- `/etc/php83/`

Edit the `docker-container.cfg`

Install the `./www/config/ssl/ca/certificate_authority.pem` to your Trusted Root Certificates
- References: [getting-chrome-to-accept-self-signed-localhost-certificate](https://stackoverflow.com/questions/7580508/getting-chrome-to-accept-self-signed-localhost-certificate)
- Chrome settings (Settings > Manage certificates > Authorities > Import).

Install CA using Administrator PowerShell:
```PowerShell
cd local-web
Import-Certificate -FilePath "www\config\ssl\ca\certificate_authority.pem" -CertStoreLocation "Cert:\LocalMachine\Root"
```

> **Edit `./www/config/sites.sh` to setup websites**

---

# v1.0.0
