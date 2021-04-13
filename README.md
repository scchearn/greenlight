# Greenlight

ITSM for FOSS project. Installs free and open-source software to manage ICT operations.

## Testing
### 0.8.0:
- [x] **Zabbix** :: Fedora Builds
- ~~**Zabbix** :: 18.04 Builds~~
- ~~**Zabbix** :: 20.04 Builds~~

- [x] **Snipe-IT** :: Fedora Builds
- ~~**Snipe-IT** :: 18.04 Builds~~
- ~~**Snipe-IT** :: 20.04 Builds~~

### 0.7.0:
- ~~**Zabbix** :: 18.04 Builds~~
- ~~**Zabbix** :: 20.04 Builds~~
- [x] **Zabbix** :: Fedora Builds
  - NOTES: ```./test/script.sh: line 741: unexpected EOF while looking for matching `"'```

> Snipe-IT in progress
> - [ ] **Snipe-IT** :: Fedora Builds
> - [ ] **Snipe-IT** :: 18.04 Builds
> - [ ] **Snipe-IT** :: 20.04 Builds

### 0.0.5:

- [x] **Zabbix** :: Fedora Builds
- [x] **Zabbix** :: 18.04 Builds
- [x] **Zabbix** :: 20.04 Builds

### 0.0.4:

- [x] **Zabbix** :: Fedora Builds
- [x] **Zabbix** :: 18.04 Builds
- [x] **Zabbix** :: 20.04 Builds

## Dependencies

### Fedora
```sh
  fping
  git
  httpd
  libssh2
  mariadb
  mariadb-devel
  mariadb-server
  net-snmp-libs
  OpenIPMI-libs
  php
  php-bcmath
  php-cli
  php-common
  php-embedded
  php-fpm
  php-gd
  php-json
  php-ldap
  php-mbstring
  php-mcrypt
  php-mysqlnd
  php-pdo
  php-simplexml
  php-xml
  php-zip
  unixODBC
  unzip
```

### Ubuntu 18.04
```sh
  apache2
  apache2-bin
  apache2-data
  apache2-utils
  fonts-dejavu
  fonts-dejavu-extra
  fping
  libapache2-mod-php7.4
  libapr1
  libaprutil1
  libaprutil1-dbd-sqlite3
  libaprutil1-ldap
  libgd3
  libltdl7
  libmysqlclient20
  libodbc1
  libopenipmi0
  libsnmp-base
  libsnmp30
  libssh-4
  mysql-client
  mysql-client-5.7
  mysql-client-core-5.7
  mysql-common
  mysql-server
  php7.4
  php7.4-bcmath
  php7.4-cli
  php7.4-common
  php7.4-curl
  php7.4-gd
  php7.4-json
  php7.4-ldap
  php7.4-mbstring
  php7.4-mysql
  php7.4-opcache
  php7.4-readline
  php7.4-xml
  php7.4-zip
  snmpd
  ssl-cert
```

### Ubuntu 20.04
```sh
  apache2
  apache2-bin
  apache2-data
  apache2-utils
  fonts-dejavu
  fonts-dejavu-extra
  fping
  libapache2-mod-php
  libapr1
  libaprutil1
  libaprutil1-dbd-sqlite3
  libaprutil1-ldap
  libgd3
  libltdl7
  libmysqlclient21
  libodbc1
  libopenipmi0
  libsnmp-base
  libsnmp35
  libssh-4
  mariadb-client
  mariadb-server
  php
  php-bcmath
  php-cli
  php-common
  php-gd
  php-json
  php-ldap
  php-mbstring
  php-mysql
  php-opcache
  php-readline
  php-xml
  snmpd
  ssl-cert
```