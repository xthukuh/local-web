# local-web

An alpine apache PHP local server with CA self-sign SSL and build-in easy site setup command.

> _**♠️ Developed By [Thuku](https://github.com/xthukuh)**_

### Components
- Apache2
- PHP83
- Composer
- Certificate Authority selfsign

### Example `docker-compose.yml`

```yml
name: local-web
services:
  web:
    image: xthukuh/local-web:latest
    container_name: web
    hostname: testing
    ports:
      - 80:80
      - 443:443
    volumes:
      # (required) dev home
      - ./www/:/etc/www/
      # (optional) expose apache2 and php config to host
      - ./docker/etc/:/docker/etc/
      # (optional) expose logs to host
      - ./docker/log/:/var/log/
```

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
