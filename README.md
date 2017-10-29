# bboehmke/isp-mail:latest

- [Introduction](#introduction)
    - [Differences to the tutorial](#differences-to-the-tutorial)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
    - [Data Store](#data-store)
    - [Ports](#ports)
    - [Database](#database)
        - [PostgreSQL (Recommended)](#postgresql)
            - [External PostgreSQL Server](#external-postgresql-server)
            - [Linking to PostgreSQL Container](#linking-to-postgresql-container)
        - [MySQL](#mysql)
            - [External MySQL Server](#external-mysql-server)
            - [Linking to MySQL Container](#linking-to-mysql-container)
    - [SSL](#ssl)
    - [Available Configuration Parameters](#available-configuration-parameters)
- [Database Structure](#database-structure)
- [Administration](#administration)
- [Upgrading](#upgrading)
- [ToDo](#todo)


# Introduction

Dockerfile to build a multiple domain mail server using Postfix and 
Dovecot with IMAP and POP3 (like the one of a hosting provider).

This image is based on the [ISPmail tutorial](https://workaround.org/ispmail) 
of Christoph Haas.

Additional the entrypoint of this images is based on 
[GitLab Image](https://github.com/sameersbn/docker-gitlab) of Sameer Naik.


## Differences to the tutorial
There are some differences to the tutorial:

- **Different MySQL tables**: Usage of joins to reduce repetitions.
  (incompatible databases! see [Database Structure](#database-structure))
- **Improved SSL security**: Deactivated SSLv3 and SSLv2 and enabled elliptic
  curve cryptography
- **User defined alias address**: enabled GMail like alias address with + separator

# Quick Start
**TODO: Docker compose**

# Configuration

## Data Store

To avoid losing any data, you should mount a volume at:

* `/data`

There you will find 3 subdirectories:

* `/data/maildir` - contains received and send emails
* `/data/log` - contains logs of mail server
* `/data/ssl` - contains SSL certificates of mail server

Volumes can be mounted in docker by specifying the `-v` option in the docker run command.

```bash
docker run --name isp-mail -d \
    -v /srv/docker/isp-mail:/data \
    bboehmke/isp-mail:latest
```

## Ports

If the server should be reachable from outside the host system, there are some 
ports that must be forwarded. 

- **SMTP (25 & 465)**: Send and receive mails. (communication between mail servers)
- **POP3 (110 & 995)**: Access received mails on the server. (Delete on server)
- **IMAP (143 & 993)**: Access received mails on the server. (No delete on server + folder support)
- **Sieve (4190)**: Manage filter rules for received mails.

## Database

This mail server uses a database to store existing mail address and redirection.
You can configure this image to use either MySQL or PostgreSQL.

*Note: The structure of the database is shown in [Database Structure](#database-structure)*

### PostgreSQL

*Assuming that the PostgreSQL server host is 192.168.1.42 with user `mail`, 
password `password` and the dtabase name `mailDB`*

```bash
docker run --name isp-mail -d \
    -e DB_TYPE=postgresql \
    -e DB_HOST=192.168.1.42 \
    -e DB_NAME=mailDB \
    -e DB_USER=mail \
    -e DB_PASS=password \
    -v /srv/docker/isp-mail:/data \
    bboehmke/isp-mail:latest
```

#### Linking to PostgreSQL Container

If a postgresql container is linked, only the `DB_TYPE`, `DB_HOST` and 
`DB_PORT` settings are automatically retrieved using the linkage. You may 
still need to set other database connection parameters such as the `DB_NAME`, 
`DB_USER`, `DB_PASS` and so on.

To illustrate linking with a postgresql container, 
we will use the official postgresql image. When using postgresql image in 
production you should mount a volume for the postgresql data store. 
Please refer the postgresql image for details.

First, start the postgresql container:
```bash
docker run --name mail-postgresql \
    -e POSTGRES_PASSWORD=password \
    -e POSTGRES_DB=mailDB \
    -e POSTGRES_USER=mail \
    postgres
```

The above command will create a database named `mailDB` and also create a user 
named `mail` with the password `password` with full/remote access to the 
`mailDB` database.

Now start the mail container:

```bash
docker run --name isp-mail -d \
    --link mail-postgresql:postgresql \
    -v /srv/docker/isp-mail:/data \
    bboehmke/isp-mail:latest
```

Here the image will also automatically fetch the `DB_NAME`, `DB_USER` and 
`DB_PASS` variables from the postgresql container as they are specified in the 
`docker run` command for the postgresql container. This is made possible using 
the magic of docker links and works with the following images:

 - [postgresql](https://hub.docker.com/_/postgresql/)
 - [sameersbn/postgresql](https://quay.io/repository/sameersbn/postgresql/)
 - [orchardup/postgresql](https://hub.docker.com/r/orchardup/postgresql/)
 - [paintedfox/postgresql](https://hub.docker.com/r/paintedfox/postgresql/)
 
### MySQL

#### External MySQL Server

*Assuming that the MySQL server host is 192.168.1.42 with user `mail`, 
password `password` and the dtabase name `mailDB`*

```bash
docker run --name isp-mail -d \
    -e DB_TYPE=mysql \
    -e DB_HOST=192.168.1.42 \
    -e DB_NAME=mailDB \
    -e DB_USER=mail \
    -e DB_PASS=password \
    -v /srv/docker/isp-mail:/data \
    bboehmke/isp-mail:latest
```

#### Linking to MySQL Container

If a mysql container is linked, only the `DB_TYPE`, `DB_HOST` and `DB_PORT` 
settings are automatically retrieved using the linkage. You may still need 
to set other database connection parameters such as the `DB_NAME`, `DB_USER`, 
`DB_PASS` and so on.

To illustrate linking with a mysql container, we will use the official mysql
image. When using mysql image in production you should mount a volume for the 
mysql data store. 
Please refer the README of the mysql image for details.

First, start the mysql container:
```bash
docker run --name mail-mysql \
    -e MYSQL_PASSWORD=password \
    -e MYSQL_DATABASE=mailDB \
    -e MYSQL_USER=mail \
    -e MYSQL_RANDOM_ROOT_PASSWORD=true \
    mysql
```

The above command will create a database named `mailDB` and also create a user 
named `mail` with the password `password` with full/remote access to the 
`mailDB` database.

Now start the mail container:

```bash
docker run --name isp-mail -d \
    --link mail-mysql:mysql \
    -v /srv/docker/isp-mail:/data \
    bboehmke/isp-mail:latest
```

Here the image will also automatically fetch the `DB_NAME`, `DB_USER` and 
`DB_PASS` variables from the mysql container as they are specified in the 
`docker run` command for the mysql container. This is made possible using the 
magic of docker links and works with the following images:

 - [mysql](https://hub.docker.com/_/mysql/)
 - [sameersbn/mysql](https://quay.io/repository/sameersbn/mysql/)
 - [centurylink/mysql](https://hub.docker.com/r/centurylink/mysql/)
 - [orchardup/mysql](https://hub.docker.com/r/orchardup/mysql/)


### SSL

This images requires a SSL certificate to secure the communication with the 
mail server.

The key file and the certificate should be stored in the `/data/ssl` directory 
with the name `mail.key` and `mail.crt`. Note: The name of the files can changed 
with `SSL_KEY` and `SSL_CRT`.

The SSL of this image is configured to use perfect forward security. This 
requires a dhparam file wich is automatically recreated on each container start.
The default size of this file is *1024 bits* but you can increase this with 
`SSL_DH_PARAM_LENGTH`.


### Available Configuration Parameters

*Please refer the docker run command options for the `--env-file` flag where 
you can specify all required environment variables in a single file. 
This will save you from writing a potentially long docker run command. 
Alternatively you can use docker-compose.*

- **DEBUG**: Set this to `true` to enable entrypoint debugging.
- **DB_TYPE**: Which type of database should be used: mysql or postgresql (Default: mysql).
- **DB_HOST**: Host name for database connection.
- **DB_PORT**: Database for database connection. (Default: 3306 for mysql & 5432 for postgresql)
- **DB_NAME**: Database for database connection.
- **DB_USER**: User name for database connection.
- **DB_PASS**: Password for database connection.
- **MAIL_POSTMASTER_ADDRESS**: Address of the postmaster of this server.
- **MAIL_SERVER_HOSTNAME**: Name used as mail server host name. (Default: host name of container).
- **QUOTA_STORAGE**: Default quota for new mailboxes (Default: 0 = unlimited).
- **QUOTA_WARNING**: Quota level (in %) at which a warning message will be sent to the user (Default: 90)
- **QUTOA_GRACE**: Quota grace limit (Default: 10%%)
  - **NOTE:** Percentage values MUST be extended by two percentage signs [%%]!
- **SSL_CERT**: Name of the SSL/TLS certificate file in /data/ssl/. (Default: mail.crt)
- **SSL_KEY**: Name of the SSL/TLS key file in /data/ssl/. (Default: mail.key)
- **SSL_DH_PARAM_LENGTH**: Length of the DH parameters. (Default: 1024)


# Database Structure

**Note: This structure differs from the one of the tutorial!**

The database of this mail server contains of 3 tables:

| Table           | Description                                          |
|-----------------|------------------------------------------------------|
| virtual_domains | List of domains that are handled by this mail server |
| virtual_users   | List of users (mail accounts)                        |
| virtual_aliases | List of mail redirection                             |

## virtual_domains

| Column | Description                             |
|--------|-----------------------------------------|
| id     | Id of this domain (automatic created)   |
| name   | Name of the domain (eg `mail.com` |

## virtual_users

| Column       | Description                                                                |
|--------------|----------------------------------------------------------------------------|
| id           | Id of this user (automatic created)                                        |
| domain_id    | Id of the domain this user is for (must exist in `virtual_domains`)        |
| name         | Name of the user (eg if the address is `user@mail.com` the name is `user`) |
| password     | Hash of the user password                                                  |
| quota_limit  | User's Quota Limit [KByte] (0 = unlimited)                                 |

## virtual_aliases

| Column      | Description                                                                                      |
|-------------|--------------------------------------------------------------------------------------------------|
| id          | Id of this alias (automatic created)                                                             |
| domain_id   | Id of the domain this user is for (must exist in `virtual_domains`)                              |
| source      | Local name of the email address (eg if the address is `admin@mail.com` the source is `admin`)    |
| destination | Destination of the redirection (eg `user@mail.com` or an external address like `user@gmail.com`) |

# Administration

The database can be administered directly via a Web-based interface like [**phpPgAdmin** (PostgreSQL)](https://hub.docker.com/r/maxexcloo/phppgadmin/) or [**phpMyAdmin** (MySQL)](https://hub.docker.com/r/phpmyadmin/phpmyadmin/) or via a set of integrated shell-scripts.

All shell-scripts can be executed in an existing container:
```bash
docker exec -it <container> <...>
```
Or by a temporary container:
```bash
docker run -it --rm --link database:<mysql|postgresql> bboehmke/isp-mail <...>
```
Possible commands are described in the following sub-sections.

## Domains 
```bash
domains -l | -a <domain.xx> | -d <domain.xx>
```
  - Options:
    - `-l`
      - List Domains
    - `-a <domain.xx>`
      - Add Domain
    - `-d <domain.xx>`
      - Delete Domain
    - Example: `docker exec -it <container> domains -a domain.xx`

## Users
```bash
users -l | -a <name@domain.xx[:password]> | -d <name@domain.xx>
```
  - Options:
    - `-l`
      - List all Users
    - `-a <name@domain.xx[:password]>`
      - Add User Account `name` for `domain.xx`
      - If `password` is omitted, the script will ask for a password.
      - Quota is set to 'unlimited' (change with `-q`)
    - `-p <name@domain.xx[:password]>`
      - Change a User's Password
      - If `password` is omitted, the script will ask for a password.
    - `-q <name@domain.xx:quota>`
      - Change a User's Quota [KByte]
      - 0 = unlimited
    - `-d <name@domain.xx>`
      - Delete User Account `name` for `domain.xx`
    - `-D <name@domain.xx>`
      - Delete User's Mailbox Directory
      - **NOTE:** This command doesn't check for existing user accounts!
    - Example: `docker exec -it <container> users -a name@domain.xx:password`

## Aliases 
```bash
forwards -l | -a <source@domain.xx:destination@domain.yy> | -d <source@domain.xx>
```
 - Options:
    - `-l`
      - List Aliases
    - `-a <source@domain.xx:destination@domain.yy>`
      - Add mail-forward from `source@domain.xx` to destination `destination@domain.yy`
    - `-d <source@domain.xx>`
      - Delete mail-forwards for `source@domain.xx`
    - Example: `docker exec -it <container> forwards -a source@domain.xx:destination@domain.yy`

# Upgrading

Before you upgrade the image you should create a backup of the `/data` volume 
and the database.

To upgrade to a newer version of the image follow this steps:

- **Step 1**: Get the new docker image.

```bash
docker pull bboehmke/isp-mail:latest
```

- **Step 2**: Stop and remove the old container.

```bash
docker stop isp-mail
docker rm isp-mail
```

- **Step 3**: Start the new image.

```bash
docker run --name isp-mail -h isp-mail -d \
    [OPTIONS] \
    bboehmke/isp-mail:latest
```

# ToDo

*The following features are planned for the future*

- Automatic backup of mailboxes and database with a single command
- Automatic creation of self signed certificates if required
- Send only mail user
