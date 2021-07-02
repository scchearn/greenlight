# Greenlight
This is Greenlight. It saves you time. Greenlight is a FOSS for ITSM project part of a masters degree programme.

## Purpose
Installs free and open-source software (FOSS) packages to manage ICT operations.

This script installs three FOSS applications to create a framework for information technology management (ITSM). The different software, when used together, provides a software toolchain for ITSM. The seventeen service management practices of the Information Technology Infrastructure Library provides the baseline of what features such a toolchain should implement.

Hopefully, using this script will save you time and a lot of trouble finding, installing, and testing hundreds of different software packages. Now, it's all in one place and easily accessible.

#### Please Note
This software toolchain is only a prototype and not meant as fully-fledged software. Furthermore, please do not run this script on production servers or any other installation that you do not want to be broken. Although this script won't overwrite other software, it is not (yet) built to avoid breaking production servers. Therefore, it is better to run it on a fresh installation of the supported operating systems. **Lastly**, feel free to change, modify, or adapt this script to your needs or suggest changes and improvements.

## Supported Operating Systems
The following operating systems are currently supported. **Fedora 32**, **Centos 8**, **Ubuntu 18.04** (Bionic Beaver) and **20.04** (Focal Fossa).

## Installing
Use either of the following installation options (executing the script requires elevated privileges):

### Option 1
```sh
curl -sSL https://raw.githubusercontent.com/scchearn/greenlight/master/install.sh | sudo bash
```
Piping into bash is a little controversial — you do not know what the script does. Therefore, please feel free to [inspect the code][2] first before running it. This should be standard practice.

### Option 2
```sh
wget https://raw.githubusercontent.com/scchearn/greenlight/master/install.sh
sudo bash install.sh
```

## Latest Stable Build
**0.9.4**

|OS                |GLPi   |Zabbix    |Snipe-IT   |
|------------------|:-----:|:--------:|:---------:|
|Centos 8          |✓      |✓         |✓          |
|Fedora 34         |✓      |✗ [#7][1] |✓          |
|Fedora 33         |✓      |✗ [#7][1] |✓          |
|Fedora 32         |✓      |✓         |✓          |
|Ubuntu 20.04 LTS  |✓      |✓         |✓          |
|Ubuntu 18.04 LTS  |✓      |✓         |✓          |


[1]: https://github.com/scchearn/greenlight/issues/7
[2]: https://github.com/scchearn/greenlight/blob/master/install.sh