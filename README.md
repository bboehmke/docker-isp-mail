# ISP-style mail server
Based on the tutorial of Christoph Haas: 
[ISPmail tutorials](https://workaround.org/ispmail)

## Differences to the tutorial
There are some differents to the tutorial:
- **Improved MySQL tables**: Usage of joins to reduce repetitions. (incompatible databases)
- **Improved SSL securety**: Deactivated SSLv3 and SSLv2 and enabled elliptic curve cryptography
- **User defined alias address**: enabled GMail like alias address with + separator

## Usage

This mail server use a MySQL database to store the virtual mail addresses.
The database connection is configured using environment variables. The server 
will create the tables if they do not exist (See 
[mail.sql](https://github.com/bboehmke/docker-isp-mail/blob/master/config/postfix/mail.sql)).

*Assuming that the MySQL server host is 192.168.1.42*

```bash
docker run --name isp-mail -h isp-mail -d \
    -e MYSQL_HOST=192.168.1.42 \
    -e MYSQL_DATABASE=mailserver \
    -e MYSQL_USER=mail \
    -e MYSQL_PASSWORD=password \
    -v /srv/docker/mail-data:/data \
    bboehmke/isp-mail:latest
```

## Ports

If the server should be reachable from outside the host system, there are some 
ports that must be forwarded. 

- **SMTP (25 & 465)**: Send and receive mails. (communication between mail servers)
- **POP3 (110 & 995)**: Access received mails on the server. (Delete on server)
- **IMAP (143 & 993)**: Access received mails on the server. (No delete on server + folder support)
- **Sieve (4190)**: Manage filter rules for received mails.


## Upgrading

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
    [OPTIONS]
    bboehmke/isp-mail:latest
```


## Available Configuration Parameters

- **MYSQL_DATABASE**: Database for MySQL connection.
- **MYSQL_HOST**: Host name for MySQL connection.
- **MYSQL_PASSWORD**: Password for MySQL connection.
- **MYSQL_PORT**: Database for MySQL connection. (Default: 3306)
- **MYSQL_USER**: User name for MySQL connection.
- **POSTMASTER_ADDRESS**: Address of the postmaster of this server.
- **SERVER_HOSTNAME**: Name used as mail server host name. (Default: host name of container).
- **SSL_CERT**: Name of the SSL/TLS certificate file in /data/ssl/. (Default: mail.crt)
- **SSL_DH_PARAM_LENGTH**: Length of the DH parameters. (Default: 1024)
- **SSL_KEY**: Name of the SSL/TLS key file in /data/ssl/. (Default: mail.key)