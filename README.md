# Greenlight
This is Greenlight. It saves you time. Greenlight is a FOSS for ITSM project.

## Purpose
Installs free and open-source software (FOSS) to manage ICT operations.

This script installs three FOSS applications to create a framework for information technology management. The different software, when used together, is intended to provide a software toolchain for ITSM, based on the seventeen service management practices of the Information Technology Infrastructure Library. 

Hopefully, using this script will save you time and trouble finding, installing, and testing hundreds of different software packages. It's all in one place and easily accessible.

#### Note
Please do not run this script on production servers or any other installation that you do not want to be broken. Although this script tries to keep installing the different packages clean, it is not (yet) created to avoid breaking production type servers. Therefore, it is better to run this script on a fresh installation of any supported operating system. **Also**, feel free to change, modify, or adapt this script to your needs or suggest changes and improvements.  

## Supported Operating Systems
The following operating systems are currently supported. **Fedora 32**, **Centos 8**, **Ubuntu 18.04** (Bionic Beaver) and **20.04** (Focal Fossa).

## Installing
Use either of the following options (executing script requires elevated privileges):

### Option 1
```sh
curl -sSL https://raw.githubusercontent.com/scchearn/greenlight/master/install.sh | sudo bash
```

### Option 2
```sh
wget https://raw.githubusercontent.com/scchearn/greenlight/master/install.sh
sudo bash install.sh
```

### Latest Stable Build
**0.8.17**

|OS                |GLPi   |Zabbix    |Snipe-IT   |
|------------------|:-----:|:--------:|:---------:|
|Centos 8          |✓      |✓         |✓          |
|Fedora 34         |✓      |✗ [#7][1] |✓          |
|Fedora 33         |✓      |✗ [#7][1] |✓          |
|Fedora 32         |✓      |✓         |✓          |
|Ubuntu 20.04 LTS  |✓      |✓         |✓          |
|Ubuntu 18.04 LTS  |✓      |✓         |✓          |


[1]: https://github.com/scchearn/greenlight/issues/7