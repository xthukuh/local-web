# local-web

A docker container for apache web server.

> _**♠️ Developed By [Thuku](https://github.com/xthukuh)**_

### Components
- Apache2
- PHP83
- Composer
- Certificate Authority selfsign

### Docker Container

```sh
# verbose
docker compose up --build

# daemon
docker compose up -d

# shutdown
docker compose down
```

### Docker Shell

To access running container shell terminal run:

```sh
docker exec -it web bash
# docker exec -it web sh
# docker exec -it web zsh
```

While in shell run for built-in commands help docs:

```sh
setup --help
selfsign --help
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

**Edit `./www/config/sites.sh` to setup websites**
