#!/bin/bash

# TODO: Add app information here.

# Some things to remember
# TODO: Tell the user afterwards all the changes that was made. Like new users and their passwords
# TODO: Remove OS checks from many of the functions. Initial os_check() should suffice.
# TODO: Uninstaller?
# TODO: Logging

###################################################
#                  GREENLIGHT                     #
#                Install Script                   #
#                                                 #
#        Created by Samuel Hearn as partial       #
#         fulfilment for masters program.         #
###################################################

# curl -sSL https://raw.githubusercontent.com/scchearn/greenlight/master/install.sh | sudo bash

# =================================================
#   DO THESE THINGS FIRST
# =================================================

# This is the name of the app, set it as a variable.
readonly APPNAME="greenlight"
# Make a directory for files to go.
if ! [[ -d /tmp/$APPNAME ]]; then
  mkdir /tmp/$APPNAME
fi
# Generate password for environment
if [[ -f /tmp/$APPNAME/app.cache ]]; then
  # Check if there's an existing file, store the contents in a variable if there is.
  readonly ENV_PASSWORD=$(cat /tmp/$APPNAME/app.cache)
else
  # Create temporary files.
  touch /tmp/$APPNAME/app.cache
  touch /tmp/$APPNAME/app.log
  # Generate a random string to use as a password and assign it to a variable.
  readonly ENV_PASSWORD=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | head -c${1:-32};echo;)
  # Save that password to a file for temporary safeguarding and, 
  echo $ENV_PASSWORD >> /tmp/$APPNAME/app.cache
  # set permissions so only the owner can read and write (600) to it, which is root in this case.
  chmod 600 /tmp/$APPNAME/app.cache
fi
# Get environment details, like the distribution
source /etc/os-release
# OS detection
readonly ENV_DISTRO=$ID
readonly ENV_DISTRO_NAME=$NAME
readonly ENV_DISTRO_VERSION_FULL=$VERSION
readonly ENV_DISTRO_VERSION_ID=$VERSION_ID
readonly APP_LOG="/tmp/$APPNAME/app.log"
readonly HOSTIP=$(hostname -I | awk -F ' ' '{print $1}')
sntp_sleep_time=1

# Set package manager
case $ENV_DISTRO in
  'fedora' )
    readonly ENV_PKGMGR='dnf'
    ;;
  'centos' )
    readonly ENV_PKGMGR='yum'
    ;;
  'ubuntu' )
    readonly ENV_PKGMGR='apt'
    ;;
esac

# -e option instructs bash to exit immediately if a simple command
#  exits with a non-zero status, unless the command that fails is
#  part of an until or while loop, part of an if statement, part of
#  a && or || list, or if the command's return status is being
#  inverted using !.  -o errexit
#  set -e

# -e option instructs bash to print a trace of simple commands and their
#  arguments after they are expanded and before they are executed. -o xtrace
# set -x

# Bash matches patterns in a case-insensitive fashion when
# performing matching while executing case or [[
# conditional commands.
shopt -s nocasematch

# =================================================
#   DECORATIONS
# =================================================

# ASCII Logo
show_ascii_logo() {
  echo -e "
╱╱╱╱╱╱╱╱╱╱╱╱╱╱$COLOUR_GREEN╭╮$COLOUR_NC╱╱╱╱$COLOUR_GREEN╭╮$COLOUR_NC╱$COLOUR_GREEN╭╮$COLOUR_NC
╱╱╱╱╱╱╱╱╱╱╱╱╱╱$COLOUR_GREEN┃┃$COLOUR_NC╱╱╱╱$COLOUR_GREEN┃┃╭╯╰╮$COLOUR_NC
$COLOUR_GREEN╭━━┳━┳━━┳━━┳━╮┃┃╭┳━━┫╰┻╮╭╯$COLOUR_NC
$COLOUR_GREEN┃╭╮┃╭┫┃━┫┃━┫╭╮┫┃┣┫╭╮┃╭╮┃┃$COLOUR_NC
$COLOUR_GREEN┃╰╯┃┃┃┃━┫┃━┫┃┃┃╰┫┃╰╯┃┃┃┃╰╮$COLOUR_NC
$COLOUR_GREEN╰━╮┣╯╰━━┻━━┻╯╰┻━┻┻━╮┣╯╰┻━╯$COLOUR_NC
$COLOUR_GREEN╭━╯┃$COLOUR_NC╱╱╱╱╱╱╱╱╱╱╱╱╱$COLOUR_GREEN╭━╯┃$COLOUR_NC
$COLOUR_GREEN╰━━╯$COLOUR_NC╱╱╱╱╱╱╱╱╱╱╱╱╱$COLOUR_GREEN╰━━╯$COLOUR_NC
  "
}

# Set some colours we can use throughout the script.
COLOUR_NC='\e[0m'         # No Colour
COLOUR_RED='\e[1;31m'     # Red
COLOUR_GREEN='\e[1;32m'   # Green
COLOUR_YELLOW='\e[1;33m'  # Yellow
COLOUR_PURPLE='\e[1;35m'  # Purple

# Creates a box with a green tick [✓]
TICK="[${COLOUR_GREEN}\u2713${COLOUR_NC}]"
# Creates a box with a red cross [✗]
ERROR="[${COLOUR_RED}\u2717${COLOUR_NC}]"
# Box with an yellow [i], for information
INFO="[${COLOUR_YELLOW}i${COLOUR_NC}]"
# Box with an purple [?], for validation
CHECK="[${COLOUR_PURPLE}\u2753${COLOUR_NC}]"
# Creates a box with a green dotted circle [◌]
BUSY="[${COLOUR_GREEN}\u25cc${COLOUR_NC}]"

# Formatting
F_BOLD='\033[1m'  # Bold formatting
F_ITAL='\033[3m'  # Italics
F_END='\033[0m'   # Ends formatting
F_CR='\\r'        # Carriage return

spinner () {
  # Show a fun spinner to indicate that the script is busy.
  printf "   "

  # Spinners
  local spin='[-] [\\] [|] [/]'
  # local spin='[⠁] [⠂] [⠄] [⡀] [⢀] [⠠] [⠐] [⠈]'
  # local spin='[⣾] [⣽] [⣻] [⢿] [⡿] [⣟] [⣯] [⣷]'

  # This function should be called right after the process
  # we want to show as busy. So, we get the 'pid'
  # of the last executed command.
  ppid=$(jobs -p)
  # `kill -0` lets us check if the process is still running.
  while kill -0 $ppid > /dev/null 2>&1; do
    # While the process is still going, print the spinner.
    for i in $spin; do
      printf  "\b\b\b$i"
      sleep 0.25
    done
  done
  echo -ne "\\b\\b\\bdone\\n"
}

# =================================================
#   FUNCTIONS
# =================================================

show_welcome () {
  # Show a nice welcome message.
  local text="${COLOUR_GREEN}This is Greenlight. Greenlight saves you time.\\n\\nThis script will install three free and open-source applications to create a software toolchain. The different software, when used together, is meant to provide a framework for information technology service management (ITSM).\\n\\nHopefully, using this script will save you the time and headaches of finding, installing, and testing the thousands of different software solutions out there. It's all in one place and easily accessible. Find out more at ${COLOUR_PURPLE}https://github.com/scchearn/greenlight\\n\\n${COLOUR_YELLOW}Note: ${COLOUR_GREEN}Although this script installs applications in directories reserved for software packages and uses temporary folders, it is not made to avoid breaking production servers. It is, therefore, better to run this script on a fresh installation.${COLOUR_NC}"
  # Check if we're running a shell.
  if ! [[ -z $(stty size > /dev/null 2>&1) ]]; then
    # Let's find the width of the terminal we're running.
    width=$(stty size | awk 'END { print $NF }')
    # If the terminal is wider than 80 columns,
    if [[ $width -ge 80 ]]; then
      # divide the width by two.
      width=$(( width / 2 ))
    fi
  else
    # If we don't know the shell's width, set it to 80.
    width="80"
  fi
  # Display text that takes up half the screen, or not
  # depending on width.
    echo -e $text | fold -w $width -s
    echo -e ""
}

clean_up () {
  # Check if the temporary folder exists, if it does
  if [[ -d /tmp/$APPNAME ]]; then
    # then remove it.
    rm -rf /tmp/$APPNAME
  fi
}

install_script_deps () {
  # Install dependencies required by this script

  # Run the function inside itself, so we can show a busy spinner.
  __run () {
    local packages='git wget unzip tar'
    case $ENV_DISTRO in
      'fedora' | 'ubuntu' )
        # Fedora and Ubuntu needs 'sntp'
        packages="$packages sntp"
        for p in $packages; do
          # Ubuntu works differently when checking if a package is
          # installed. Assign the exit code of the command to `$ec`.
          case $ENV_DISTRO in
            # If we're on Ubuntu,
            'ubuntu')
              # use `dpkg`.
              ec=$(dpkg -s $p > /dev/null 2>&1;echo $?)
              ;;
            *)
              # Otherwise, use the distros package manager.
              ec=$($ENV_PKGMGR list installed $p > /dev/null 2>&1;echo $?)
              ;;
          esac
          # Check `$ec` for the exit code. If the package is not
          # installed (exit code=1),
          if [[ $ec == 1 ]]; then
            # install it.
            $($ENV_PKGMGR install -y $p > /dev/null 2>&1)
          fi
        done
        ;;
      'centos' )
        # Install Extra Packages for Enterprise Linux (EPEL)
        yum install -y epel-release > /dev/null 2>&1
        for p in $packages; do
          ec=$($ENV_PKGMGR list installed $p > /dev/null 2>&1;echo $?)
          # Check `$ec` for the exit code. If the package is not
          # installed (exit code=1),
          if [[ $ec == 1 ]]; then
            # install it.
            $($ENV_PKGMGR install -y $p > /dev/null 2>&1)
          fi
        done
        ;;
    esac
  }

  printf "$BUSY Getting things ready to run... "
    __run &
    spinner

}

unfinished_install () { 
  # Check for aborted or failed installations
  # TODO: Tell the user how to restore an unfinished install
  if [[ $@ == "lock" && -f !/tmp/$APPNAME/app.lock ]]; then
    # touch /tmp/$APPNAME/app.lock
    # return 0
    echo "Locking with file not present"
  elif [[ $@ == "unlock" && -f /tmp/$APPNAME/app.lock ]]; then
    # rm /tmp/$APPNAME/app.lock
    # return 0
    echo "Unlocking, file present"
  else [[ -f /tmp/$APPNAME/app.lock ]]
    printf "%b" \\n "$ERROR" "$COLOUR_YELLOW" " Unfinished install found." "$COLOUR_NC" \\n\\n
    # exit 0
  fi
}

run_as_user () {
  # Run command as user
  su -c "$@" $APP_USER
}

# WRITE STUFF HERE
# #########################################################
execute_and_log () {
  eval "$@" | tee -a $APP_LOG
}

check_privileges () {
  # Check if we have root privileges. 
  # If ID of current user is not 0
  if [[ "$(id -u)" != "0" ]]; then
    # then ask for the script to be executed with root privileges.
    printf "%b %s\\n%4s%s\\n%4s%s\\n\\n" "$INFO" "Super user privileges." "" "Please execute this script with elevated privileges." "" "Exiting..."
    exit 0
  fi
}

check_os () {
  # Let's check if we're running a supported OS.
  case $ENV_DISTRO in
    # If it's Fedora
    'fedora' )
      # and greater than version 32
      if [[ "$ENV_DISTRO_VERSION_ID" -gt "32" ]]; then
        # we exit. There is an issue with incorrect versions of packages in the repositories.
        printf "%b %s\\n%4s%s\\n%4s%s\\n%4s%s\\n%4s%s\\n\\n" "$ERROR" "OS not supported." "" "Versions greater than Fedora 32 has trouble" "" "installing parts of this framework. Please use a supported" "" "version. Check https://github.com/scchearn/greenlight for more information." "" "Exiting..."
        clean_up
        exit
      fi
      ;;
    # If it's Ubuntu
    'ubuntu' )
      # we're good to go.
      :
      ;;
    # If it's Centos,
    'centos' )
      # check that we're on version 8. 
      if [[ "$ENV_DISTRO_VERSION_ID" -ge "8" ]]; then
        :
      fi
      ;;
    # Anything else,
    * )
      # we exit.
      printf "%b %s\\n%4s%s\\n%4s%s\\n%4s%s\\n\\n" "$ERROR" "OS not supported." "" "Only Fedora and Ubuntu is currently" "" "supported. Check https://github.com/scchearn/greenlight for more information." "" "Exiting..."
      clean_up
      exit
      ;;
  esac
}

get_timezone () {
  # Get the time zone, some of the software we
  # install needs this information. 
  local curlResult=$(curl 'https://ipapi.co/timezone' 2>&1;printf \\n$?)
  local curlExitCode="${curlResult##*$'\n'}"
  # Check if we can get a time zone from ipapi.co
  if [[ "$curlExitCode" -eq 0 ]]; then
    # if we can, assign it to a variable
    ENV_TIMEZONE=$(echo "$curlResult" | awk 'NR==4{ print $0 }')
    return 0
  else
    # otherwise, get it locally.
    case $ENV_DISTRO in
      'fedora' | 'centos' )
        ENV_TIMEZONE=$(timedatectl | grep "Time zone" | sed -E "s/.*Time zone: (.*) \(.*/\1/")
        return 0
        ;;
      'ubuntu' )
        ENV_TIMEZONE=$(cat /etc/timezone)
        return 0
        ;;
    esac
    exit 1
  fi
  return 1
}

set_ntp () {
  # Checks that NTP is syncing, using `sntp` or `chronyd`. Parts of
  # the installation steps need to have the correct time and date
  # set. PHP composer and `curl` fail when the system clock is
  # not within tolerable range.

  # Run the function inside itself, so we can show a busy spinner.
  __run () {
    case $ENV_DISTRO in
      'centos' )
        # Centos uses `chronyd` to set time.
        chronyd -q 'server 0.europe.pool.ntp.org iburst' > /dev/null 2>&1
        ;;
      'fedora' | 'ubuntu' )
        # Check if the 'sntp' command is installed,
        if type sntp > /dev/null 2>&1; then
          # and then get the difference between the local clock and 'pool.ntp.org'.
          # The difference is in seconds and displayed in either negative or
          # positive (ahead or behind). Using some awk magic, get this
          # value and strip the +/- symbol from the front. 
          clock_diff=$(sntp pool.ntp.org | awk -F' ' 'END{ print $4 }'| awk '{ print substr($1,2) }')
          # We only care if this value is more than 2m (120) either
          # way. Use basic calculator (bc) to check this.
          while (( $(echo "$clock_diff >= 120" | bc -l) )); do
            timedatectl set-ntp false
            timedatectl set-ntp true
            sleep $sntp_sleep_time
            ((sntp_sleep_time=sntp_sleep_time+1))
            __run
          done
        fi
        ;;
    esac
  }
  
  printf " $BUSY Checking system clock... "
    __run &
    spinner

}

write_homepage () {
  # Writes a welcome page at Apache document root.
  local docroot='/var/www/html'
  local url='https://raw.githubusercontent.com/scchearn/greenlight/master/greenlight.html'
  curl -sS $url | tee $docroot/index.html > /dev/null
  sed -E -i 's/(\{PASSWD\})/'$ENV_PASSWORD'/' $docroot/index.html

  # Gzipped
  # local url='https://raw.githubusercontent.com/scchearn/greenlight/master/greenlight.html.gz'
  # wget -q -nc -P /tmp/$APPNAME/ $url
  # gunzip /tmp/$APPNAME/greenlight.html.gz
  # mv /tmp/$APPNAME/greenlight.html $docroot/index.html
  # sed -E -i 's/(\{PASSWD\})/'$ENV_PASSWORD'/' $docroot/index.html
}

secure_database () {
  # -q, --quiet     Quiet (no output)
  # Secures a fresh install of MySQL/MariaDB.
  
  # Get installation specific variables from log file.
  source /tmp/$APPNAME/app.log
  # Check if we've run the script before.
  if ! [[ $greenlight_executed == true ]]; then
    if ! [[ "$@" =~ "-q" ||  "$@" =~ "--quiet" ]]; then printf "  $BUSY Securing database... "; fi
      # Set the root mysql password and,
      mysqladmin -u root password "$ENV_PASSWORD" > /dev/null 2>&1
      # secure the database. Based on the mysql_secure_installation command.
      mysql -u root -p"$ENV_PASSWORD" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')" > /dev/null 2>&1
      mysql -u root -p"$ENV_PASSWORD" -e "DELETE FROM mysql.user WHERE User=''" > /dev/null 2>&1
      mysql -u root -p"$ENV_PASSWORD" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'" > /dev/null 2>&1
      mysql -u root -p"$ENV_PASSWORD" -e "FLUSH PRIVILEGES" > /dev/null 2>&1
      if ! [[ "$@" =~ "-q" || "$@" =~ "--quiet" ]]; then printf "done\\n"; fi
      echo "${APPNAME}_executed=true" >> /tmp/$APPNAME/app.log
  else
    # Database already secured, we've executed script before.
    printf "  $TICK Database secured.\\n"
  fi
}

prepare_database () {
  # Prepare the database for the application being installed.
  local APP_DBNAME=${APP_USER}
  printf "  $BUSY Creating database for $APP_NAME... "
  # Create databases, users and grant privileges
  mysql -u root -p"$ENV_PASSWORD" -e "CREATE USER '$APP_USER'@localhost IDENTIFIED BY '$ENV_PASSWORD'" > /dev/null 2>&1
  mysql -u root -p"$ENV_PASSWORD" -e "CREATE DATABASE $APP_DBNAME character set utf8 collate utf8_bin" > /dev/null 2>&1
  mysql -u root -p"$ENV_PASSWORD" -e "GRANT ALL PRIVILEGES ON $APP_DBNAME.* TO $APP_USER@localhost" > /dev/null 2>&1
  printf "done\\n"
}

set_selinux () {
  # SELinux, only present on RPM based distributions (Ubuntu prefers AppArmor),
  # secures Linux through mandatory access control architecture patched into
  # the kernel. However, it interferes with the functioning of the software
  # packages we're installing here, so we disable it.
  if [[ "$ENV_DISTRO" == "fedora" || "$ENV_DISTRO" == "centos" ]]; then
    printf " $INFO SELinux\\n"
    # Check if SELinux is enforcing.
    # if [[ $(awk -F = -e '/^SELINUX=/ {print $2}' /etc/selinux/config) == "enforcing" ]]; then
    if [[ $(getenforce) == "enforcing" ]]; then
      printf "  $TICK SELinux is enabled, disabling... "
      # Temporary disable SELinux with 'setenforce',
      setenforce 0
      # and set the SELINUX option to disabled in the config file.
      sed -E -c -i 's/(^SELINUX*=)(.*)/\1disabled/' /etc/selinux/config
      printf "done\\n\\n"
    else
      printf "  $TICK SELinux already disabled.\\n\\n"
    fi
  fi
}

start_services () {
  # --enable      Enables and starts services
  # --restart     Restarts services
  # This function is used by the script to enable services on
  # boot and start them. Passing the restart parameter 
  # only restart services. Services are passed
  # to the function as a list.
  if [[ "$ENV_DISTRO" == "fedora" ||  "$ENV_DISTRO" == "centos" ||  "$ENV_DISTRO" == "ubuntu" ]]; then
    # While passed parameters are more than 0
    while [[ "$#" -gt 0 ]]; do
      # check if
      case $1 in
        # the string '--enable' is present
        --enable )
          # if it is, set the param variable to 'enable'.
          local param="enable"
          ;;
        # Or if --restart is passed,
        --restart )
          # set the param variable to 'restart'.
          local param="restart"
          ;;
        # Everything else should be services, 
        * )
          # so add them to a 'services' array.
          local services+=($1)
          ;;
      esac
      # Shift $1 to $2 and so on.
      shift
    done

    case $param in
      # If we're enabling services,
      enable )
        # use `systemctl` to enable and start each.
        for service in "${services[@]}"; do
          printf "   $TICK Enabling $service..."
          systemctl enable $service > /dev/null 2>&1
          systemctl start $service > /dev/null 2>&1
          # If starting the service succeeded 
          if [[ $? -eq 0 ]]; then
            # then tell us.
            echo -e " done"
          else
            # Otherwise, make it obvious that it failed.
            echo -e "$COLOUR_RED failed.$COLOUR_NC"
          fi
        done
        ;;
      # If we're restarting services
      restart )
        # do that for each using `systemctl`.
        for service in "${services[@]}"; do
          printf "   $TICK Reloading $service..."
          systemctl restart $service > /dev/null 2>&1
          # Again, if that succeeded, let us know.
          if [[ $? -eq 0 ]]; then
            echo -e " done"
          else
            # Else, show us a bright red 'failed'.
            echo -e "$COLOUR_RED failed.$COLOUR_NC"
          fi
        done
        ;;
    esac
  fi
}

config_firewall () {
  # Add firewall rules to open the necessary ports.
  case $ENV_DISTRO in
    'fedora' | 'centos')
      printf "  $TICK Adding firewall rules... "
        firewall-cmd --permanent --add-service=http --add-service=https > /dev/null 2>&1
        firewall-cmd --permanent --add-port=10050-10051/tcp > /dev/null 2>&1
        firewall-cmd --reload  > /dev/null 2>&1
      printf "done\\n" 
      ;;
    'ubuntu')
      printf "  $TICK Adding firewall rules... "
        ufw allow 80/tcp > /dev/null 2>&1
        ufw allow 443/tcp > /dev/null 2>&1
        ufw allow 10050/tcp > /dev/null 2>&1
        ufw allow 10051/tcp > /dev/null 2>&1
      printf "done\\n"
      ;;
  esac
}

check_dpkg_lock () {
  # `apt` locks the package manager while its busy. Sometimes the process
  # finishes, but stays busy in the background and keeps the lock file
  # in place. Here we just make sure that the lock file is removed
  # before we continue.
  if fuser /var/lib/dpkg/lock > /dev/null 2>&1 || fuser /var/lib/dpkg/lock-frontend > /dev/null 2>&1 || fuser /var/lib/apt/lists/lock > /dev/null 2>&1; then
    printf "%1s%b %s" "" $BUSY "Waiting for dpkg to finish... "
    while fuser /var/lib/dpkg/lock > /dev/null 2>&1; do
      sleep 0.5
    done
    while fuser /var/lib/dpkg/lock-frontend > /dev/null 2>&1; do
      sleep 0.5
    done
    while fuser /var/lib/apt/lists/lock > /dev/null 2>&1; do
      sleep 0.5
    done
    printf "done\\n"
  fi
}

# VARIABLES
# Get some important information
get_org_var () {
  read -e -p "What is your domain name: " ORG_DOMAIN
  read -e -p "What's the email address of the administrator: " ORG_ADMIN_EMAIL

  printf "\\nPlease check that all the information below is correct:\\n"
  printf " $CHECK Domain name: $COLOUR_GREEN$ORG_DOMAIN$COLOUR_NC\\n"
  printf " $CHECK Administrator email: $COLOUR_GREEN$ORG_ADMIN_EMAIL$COLOUR_NC\\n"
  read -e -p "Is this information correct? [y/n] " reponse
  
  # Give the user a chance to check if the data is correct
  if [[ "$reponse" != [yY] ]]; then
    # if not, ask again
    get_org_var
  else
    printf " $TICK Cool, continuing...\\n"
  fi
}

# Get information about the environment 
get_env_var () {
  printf "Choose a password that will be used across all systems\\n"
  printf "Password:\\n"
  read -s ORG_ENV_PASSWORD
  if [[ -z "$ORG_ENV_PASSWORD" ]]; then
    printf " $ERROR"" Oops, it looks like you didn't enter a password.\\n That's okay, lets try again:\\n"
    # get_env_var
    printf "Password:\\n"
    read -s ORG_ENV_PASSWORD
  fi
  printf " $TICK Got it, moving on...\\n"
}

# SOFTWARE DEPENDENCIES
install_software_deps () {
  # With this function, we install all the dependencies required
  # by the different software packages we are using. 

  # Dependencies differ between distributions, define them here.
  local packages_fedora='fping httpd libssh2 mariadb mariadb-devel mariadb-server net-snmp-libs OpenIPMI-libs parallel php php-bcmath php-cli php-common php-embedded php-fpm php-gd php-imap php-intl php-json php-ldap php-mbstring php-mcrypt php-mysqlnd php-pdo php-pear-CAS php-pecl-apcu php-simplexml php-xml php-xmlrpc php-zip unixODBC'
  local packages_centos='dejavu-sans-fonts fping httpd libssh2 mariadb mariadb-devel mariadb-server net-snmp-libs OpenIPMI-libs parallel php php-bcmath php-cli php-common php-embedded php-fpm php-gd php-intl php-json php-ldap php-mbstring php-mysqlnd php-pdo php-pecl-apcu php-simplexml php-xml php-xmlrpc php-zip unixODBC'
  local packages_ubuntu_18='apache2 apache2-bin apache2-data apache2-utils fonts-dejavu fonts-dejavu-extra fping libapache2-mod-php7.4 libapr1 libaprutil1 libaprutil1-dbd-sqlite3 libaprutil1-ldap libgd3 libltdl7 libmysqlclient20 libodbc1 libopenipmi0 libsnmp-base libsnmp30 libssh-4 mariadb-client mariadb-common mariadb-server parallel php7.4 php7.4-bcmath php7.4-bz2 php7.4-cli php7.4-common php7.4-curl php7.4-gd php7.4-intl php7.4-json php7.4-ldap php7.4-mbstring php7.4-mysql php7.4-opcache php7.4-apcu php7.4-readline php7.4-xml php7.4-xmlrpc php7.4-zip snmpd ssl-cert'
  local packages_ubuntu_20='apache2 apache2-bin apache2-data apache2-utils fonts-dejavu fonts-dejavu-extra fping libapache2-mod-php libapr1 libaprutil1 libaprutil1-dbd-sqlite3 libaprutil1-ldap libgd3 libltdl7 libmysqlclient21 libodbc1 libopenipmi0 libsnmp-base libsnmp35 libssh-4 mariadb-client mariadb-server parallel php php-bcmath php-bz2 php-cli php-common php-curl php-gd php-intl php-json php-ldap php-mbstring php-mysql php-opcache php-cas php-apcu php-readline php-xml php-xmlrpc php-zip snmpd ssl-cert'

  # Fedora & Centos Install
  if [[ "$ENV_DISTRO" == "fedora" || "$ENV_DISTRO" == "centos" ]]; then
    # List of packages
    case $ENV_DISTRO in
      'fedora' )
        local packages=${packages_fedora}
        ;;
      'centos' )
        local packages=${packages_centos}
        ;;
    esac
    
    printf " $INFO Updating package lists... "
      # Do a `dnf update`
      yes n 2>/dev/null | dnf update > /dev/null 2>&1 &
      spinner
    
    # Get the download size of all the packages to be installed.
    local download_size=$(yes n 2>/dev/null | dnf install $packages 2>&1 | grep "Total download size" | sed "s/Total download size: \(.*\)/\1/")
    
    # If the download size is zero, there is nothing to install.
    if [[ -z $download_size ]]; then
      printf " $TICK All dependencies installed.\\n"
    # Not zero, then we continue installing each package.
    else
      printf " $INFO Dependencies download size: $download_size\\n"

      # Loop through the list above and install each package
      for p in $packages; do
        printf "  $BUSY Installing ${COLOUR_GREEN}${p}${COLOUR_NC}... "
        # Check if the package isn't already installed.
        if dnf list installed "$p" > /dev/null 2>&1; then
          printf "already installed\\n"
        else
          # If not, run the `dnf` install command in a subshell
          # and save the results to a variable,
          local execute=$(dnf install -y $p 2>&1)
          # then check the output for information. 
          if [[ $execute =~ "no match for argument" ]]; then
            # Package not available
            printf "can't find "${COLOUR_RED}${p}${COLOUR_NC}".\\n"
          elif [[ $execute =~ "complete" ]]; then
            # Installed!
            printf "done\\n"
          else
            # Any errors will go here.
            printf " $ERROR Yikes, something broke. Better investigate.\\n$COLOUR_YELLOW$execute$COLOUR_NC\\n\\n"
          fi
        fi
      done
    fi
  
  # Ubuntu Install
  elif [[ "$ENV_DISTRO" == "ubuntu" ]]; then
    # We have to check our OS version, packages are different
    # and some needs extra repositories.

    case $ENV_DISTRO_VERSION_ID in
      '20.04' )
        # Reassign 'packages' variable
        local packages=${packages_ubuntu_20}
        ;;
      '18.04' )
        # Reassign 'packages' variable
        local packages=${packages_ubuntu_18}
        # Add PHP7.4 repository for 18.04
        printf " $INFO Adding PHP7.4 repository... "
        # Confirm that no process is busy using `apt`
        check_dpkg_lock > /dev/nul
        apt -y install software-properties-common  > /dev/null 2>&1
        # Installing 'software-properties-common' above holds
        # on to the lists lock file. So we wait for
        # it to finish.
        check_dpkg_lock > /dev/nul
        add-apt-repository -y ppa:ondrej/php  > /dev/null 2>&1
        printf "done\\n"
        ;;
    esac

    printf " $INFO Updating package lists... "
      # Do a quick `apt update`
      apt update > /dev/null 2>&1 &
      spinner

    check_dpkg_lock
    # Get the download size of all the packages to be installed.
    local download_size=$(yes n 2>/dev/null | apt install $packages 2>&1 | grep "Need to get" | sed "s/Need to get \(.*\) of archives./\1/")

      # If the download size is zero, there is nothing to install.
      if [[ -z $download_size ]]; then
        printf " $TICK All dependencies installed.\\n"
      # Not zero, then we continue installing each package.
      else
        printf " $INFO Dependencies download size: $download_size\\n"
        
        for p in $packages; do
        # Loop through the list above and install each package
          printf "  $BUSY Installing ${COLOUR_GREEN}${p}${COLOUR_NC}... "
          # Is the package already installed.
          if dpkg -s "$p" > /dev/null 2>&1; then
            printf "already installed\\n"
          else
            # Else, run the command in a subshell and save the
            # results to a variable,
            local execute=$(apt install -y $p 2>&1)
            # then check the output for information. 
            if [[ $execute =~ "unable to locate package" ]]; then
              # Package not available
              printf "can't find "${COLOUR_RED}${p}${COLOUR_NC}".\\n"
            elif [[ $execute =~ "newly installed" ]]; then
              # Installed!
              printf "done\\n"
            else
              # Any errors will go here.
              printf " $ERROR Yikes, something broke. Better investigate.\\n$COLOUR_YELLOW$execute$COLOUR_NC\\n\\n"
            fi
          fi
        done
      fi
  
  # If there the distribution does not match any of the above, apologise and exit.
  else
    printf " $ERROR Sorry, can't install on this distribution. [$COLOUR_GREEN$NAME $VERSION$COLOUR_NC]. Exiting...\\n"
    exit 1
  fi

}

install_zabbix () {
  # Recipe for installing Zabbix.

    # Temporary variables for things like the install
    # directory, application user and services.
      local APP_USER="zabbix"
      local APP_NAME="Zabbix"
      local APP_VER="5.2.6"
      local APP_TMP_DIR="/tmp/$APPNAME/zabbix"
      local APP_INSTALL_DIR="/usr/share/zabbix/" # Only used for error checking.
      local URL_SLUG_ALT="monitoring"
      case $ENV_DISTRO in
        'fedora' | 'centos' )
          local APP_SERVICES="zabbix-server zabbix-agent"
          local HTTPD_SERVICE="httpd"
          ;;
        'ubuntu' )
          local APP_SERVICES="zabbix-server zabbix-agent"
          local HTTPD_SERVICE="apache2"
          ;;
      esac
    
    # Give some space
    printf \\n
    # let the user know we're ready
    printf "%1s %b %b%s %s%b\\n" "" $INFO $COLOUR_GREEN "Installing" $APP_NAME $COLOUR_NC

    # Is the application already installed?
    if ! [[ -d $APP_INSTALL_DIR ]]; then

    # Download and install Zabbix
      printf "  $INFO Downloading and installing Zabbix...\\n"
      # for Fedora
        if [[ "$ENV_DISTRO" == "fedora" || "$ENV_DISTRO" == "centos" ]]; then
          printf "   $BUSY Downloading... "
          # Wget the install files from the Zabbix repository.
          wget -q -nc -P $APP_TMP_DIR https://repo.zabbix.com/zabbix/5.2/rhel/8/x86_64/zabbix-agent-$APP_VER-1.el8.x86_64.rpm https://repo.zabbix.com/zabbix/5.2/rhel/8/x86_64/zabbix-apache-conf-$APP_VER-1.el8.noarch.rpm https://repo.zabbix.com/zabbix/5.2/rhel/8/x86_64/zabbix-server-mysql-$APP_VER-1.el8.x86_64.rpm https://repo.zabbix.com/zabbix/5.2/rhel/8/x86_64/zabbix-web-mysql-$APP_VER-1.el8.noarch.rpm https://repo.zabbix.com/zabbix/5.2/rhel/8/x86_64/zabbix-web-deps-$APP_VER-1.el8.noarch.rpm https://repo.zabbix.com/zabbix/5.2/rhel/8/x86_64/zabbix-web-$APP_VER-1.el8.noarch.rpm
          printf "done\\n"
          printf "   $BUSY Installing...\\n"
          # Import the GPG key from Zabbix 
          rpm -import https://repo.zabbix.com/RPM-GPG-KEY-ZABBIX-A14FE591
          # and then install the application with `rpm`.
          rpm -ivh $APP_TMP_DIR"/zabbix-*" > /dev/stdout
        fi
      # for Ubuntu
        if [[ "$ENV_DISTRO" == "ubuntu" ]]; then
          # Get the deb package from the Zabbix repo
          local url='https://repo.zabbix.com/zabbix/5.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.2-1+ubuntu'$ENV_DISTRO_VERSION_ID'_all.deb'
          printf "   $BUSY Downloading... "
          local wgetResult=$(wget -v -nc -P $APP_TMP_DIR $url 2>&1; echo $?)
          local wgetExitCode="${wgetResult##*$'\n'}"
            if [[ $wgetExitCode != 0 ]]; then
              printf "   $ERROR [$wgetExitCode] Error occurred, couldn't download Zabbix at:\\n  -> $url\\n"
              exit 1
            fi
          printf "done\\n"

          printf "   $BUSY Installing... "
          local filename=$(ls /tmp/$APPNAME/zabbix/zabbix-*)
          local dpkgResult=$(dpkg -i $filename 2>&1; echo $?)
          local dpkgExitCode="${dpkgResult##*$'\n'}"
            if [[ $dpkgExitCode != 0 ]]; then
              printf "   $ERROR [$dpkgExitCode] Error occurred, couldn't install Zabbix.\\n"
              exit 1
            fi
          apt update -y > /dev/null 2>&1
          apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-agent > /dev/null 2>&1
          printf "done\\n"
          # Set time zone information in /etc/zabbix/apache.conf file.
          printf "   $INFO Setting installation time zone to: $COLOUR_PURPLE$ENV_TIMEZONE$COLOUR_NC\\n"
          sed -E -i 's/(^.*)(# php_value date.timezone).*/\1php_value date.timezone '$(echo $ENV_TIMEZONE | sed 's/\//\\\//g')'/' /etc/zabbix/apache.conf
        fi
    # done

    # Prepare SQL database
      # Secure the database,
      printf "  $INFO Preparing database...\\n"
        prepare_database
        # printf "   $TICK$F_BOLD Database password [keep it in a safe place]$F_END: $COLOUR_PURPLE$ENV_PASSWORD$COLOUR_NC\\n"
      printf "   $TICK Done preparing database.\\n"
    # done

    # Configuring 
      printf "  $INFO Configuring... \\n"
      # Add the database password to zabbix_server.conf file with some regex magic
        printf "   $BUSY Checking conf file... "
        sed -E -i 's/(^# DBPassword*=)/DBPassword='$ENV_PASSWORD'/' /etc/zabbix/zabbix_server.conf
        printf "done\\n"
    # done

    # Load Zabbix schema from file
      printf "   $BUSY Loading Zabbix DB schema (this might take a while)... "
      # Check if the schema file exists,
      if [[ -f /usr/share/doc/zabbix-server-mysql/create.sql.gz ]]; then
        # and pipe the contents to MySQL.
        zcat /usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql -u zabbix -D zabbix -p"$ENV_PASSWORD" > /dev/null 2>&1
        printf "done\\n"
      else
        printf "already loaded.\\n"
      fi

      # Add alternative alias to the web server configuration file.
      case $ENV_DISTRO in
        'fedora' | 'centos' )
          sed -E -i 's/(^Alias.+)/\1\nAlias \/'$URL_SLUG_ALT' \/usr\/share\/zabbix/' /etc/httpd/conf.d/zabbix.conf
          ;;
        'ubuntu' )
          sed -E -i 's/(^.+)(Alias.+)/\1\2\n\1Alias \/'$URL_SLUG_ALT' \/usr\/share\/zabbix/' /etc/apache2/conf-available/zabbix.conf
          ;;
      esac
    # done

    printf "   $TICK Configuration complete.\\n"

    # Enable and start services
      printf "  $INFO Starting services...\\n"
        start_services --restart $HTTPD_SERVICE
        start_services --enable $APP_SERVICES
    # done

    # Clean up
      rm -R $APP_TMP_DIR
  
    else
      printf "   $TICK Already installed\\n"
    fi

}

install_snipeit () {
  # Snipe-IT recipe

  create_host () {
    {
      echo "  Alias /$URL_SLUG \"$APP_INSTALL_DIR/public\""
      echo "  Alias /$URL_SLUG_ALT \"$APP_INSTALL_DIR/public\""
      echo ""
      echo "  <Directory \"$APP_INSTALL_DIR/public\">"
      echo "      Allow From All"
      echo "      AllowOverride All"
      echo "      Require all granted"
      echo "      Options -Indexes"
      echo "  </Directory>"
    } > $APACHE_CONF_LOCATION/$APP_USER.conf
  }

  # Temporary variables for things like the install
  # directory, application user and services.
  local APP_TMP_DIR="/tmp/$APPNAME/snipe-it"
  local APP_INSTALL_DIR="/opt/snipe-it"
  local APP_USER="snipeit"
  local APP_NAME="Snipe-IT"
  local URL_SLUG="snipe-it"
  local URL_SLUG_ALT="assets"
  case $ENV_DISTRO in
    'fedora' | 'centos' )
      local APP_SERVICES="httpd"
      local APACHE_USER="apache"
      local APACHE_CONF_LOCATION="/etc/httpd/conf.d"
      ;;
    'ubuntu' )
      local APP_SERVICES="apache2"
      local APACHE_USER="www-data"
      local APACHE_CONF_LOCATION="/etc/apache2/sites-available"
      ;;
  esac

  # Give some space
  printf \\n
  # let the user know we're ready
  printf "%1s %b %b%s %s%b\\n" "" $INFO $COLOUR_GREEN "Installing" $APP_NAME $COLOUR_NC
  
  # Is the application already installed?
  if ! [[ -d $APP_INSTALL_DIR ]]; then
    
  # Prepare database
    printf "  $INFO Preparing database...\\n"
      prepare_database
    printf "  $TICK Done preparing database.\\n"
  # done

  # Configuring 
    printf "  $INFO Configuring... \\n"
      # add user
      case $ENV_DISTRO in
        'fedora' | 'centos' )
          printf "   $BUSY Adding user [${COLOUR_YELLOW}${APP_USER}${COLOUR_NC}]... "
            adduser --home-dir $APP_INSTALL_DIR $APP_USER > /dev/null 2>&1
          printf "done\\n"
          ;;
        'ubuntu' )
          printf "   $BUSY Adding user [${COLOUR_YELLOW}${APP_USER}${COLOUR_NC}]... "
            adduser --quiet --gecos \"\" --home $APP_INSTALL_DIR --disabled-password $APP_USER > /dev/null 2>&1
          printf "done\\n"
          ;;
      esac
      # set directory permissions
      chmod 755 $APP_INSTALL_DIR
      # set user password
      yes $ENV_PASSWORD 2>/dev/null | passwd $APP_USER > /dev/null 2>&1
      # set user group
      usermod -aG $APACHE_USER $APP_USER
  # done
  
  # Download and install Snipe-IT
    printf "  $INFO Downloading and installing Snipe-IT...\\n"
      
      printf "   $BUSY Downloading Snipe-IT... "
        # git clone
        git clone https://github.com/snipe/snipe-it $APP_TMP_DIR > /dev/null 2>&1
      printf "done\\n"

      printf "   $BUSY Moving files... "
        # move files
        # Set shell option 'dotglod' to move hidden (dot files) files.
        shopt -s dotglob
        mv $APP_TMP_DIR/* $APP_INSTALL_DIR 
        shopt -u dotglob
        rm $APP_INSTALL_DIR/{install,snipeit}.sh
        # change ownership
        chown -R $APP_USER:$APACHE_USER $APP_INSTALL_DIR
      printf "done\\n"
  # done

  # Application configuration
    printf "  $INFO Configuring ... \\n"
      
      printf "   $BUSY Configuring .env file... "
        # cp .env.example .env
        run_as_user "cd ~/; cp .env.example .env"
        # set config file options
        sed -E -i "s/(^APP_TIMEZONE=)(.*)/\1'"$(echo $ENV_TIMEZONE | sed 's/\//\\\//g')"'/" $APP_INSTALL_DIR/.env
        sed -E -i "s/(^DB_DATABASE=)(.*)/\1$APP_USER/" $APP_INSTALL_DIR/.env
        sed -E -i "s/(^DB_USERNAME=)(.*)/\1$APP_USER/" $APP_INSTALL_DIR/.env
        sed -E -i "s/(^DB_PASSWORD=)(.*)/\1$ENV_PASSWORD/" $APP_INSTALL_DIR/.env
      printf "done\\n"

      printf "   $BUSY Running PHP Composer (this will take a while, grab a coffee while you wait)... "
        # get php composer
        run_as_user "cd ~/; curl -sS https://getcomposer.org/installer | php > /dev/null 2>&1"
        # run php composer
        run_as_user "cd ~/; php composer.phar install --no-dev --prefer-source > /dev/null 2>&1" &
        spinner

      printf "   $BUSY Populating database... "
        # generate APP_KEY
        run_as_user "cd ~/; yes y 2>/dev/null | php artisan key:generate > /dev/null 2>&1"
        # migrate
        run_as_user "cd ~/; yes y 2>/dev/null | php artisan migrate > /dev/null 2>&1"
      printf "done\\n"

      printf "   $BUSY Setting permissions... "
        # change ownership
        chmod -R 755 $APP_INSTALL_DIR/storage
        chmod -R 755 $APP_INSTALL_DIR/public/uploads
        chown -R $APACHE_USER $APP_INSTALL_DIR/{storage,vendor,public}
      printf "done\\n"
      
      # Create virtual host file
      printf "   $BUSY Creating site configuration... "
        create_host
        if [[ "$ENV_DISTRO" == "ubuntu" ]]; then
          a2ensite $APP_USER.conf > /dev/null 2>&1
          a2enmod rewrite > /dev/null 2>&1
        fi
      printf "done\\n"
  # done
  
  # Start and/or restart services
    printf "   $INFO Starting services...\\n"
      start_services --restart $APP_SERVICES
  # done

  # Clean up
    rm -R $APP_TMP_DIR
  
  else
    printf "   $TICK Already installed\\n"
  fi

}

install_glpi () {
  # GLPi recipe

  local APP_USER="glpi"
  local APP_NAME="GLPi"
  local APP_VER="9.5.5"
  local APP_TMP_DIR="/tmp/$APPNAME/glpi"
  local APP_INSTALL_DIR="/opt/glpi"
  local APP_INSTALL_ROOT="/opt"
  local URL_SLUG="glpi"
  local URL_SLUG_ALT="service-desk"
  case $ENV_DISTRO in
    'fedora' | 'centos')
      local APP_SERVICES="httpd mariadb"
      local APACHE_USER="apache"
      local APACHE_CONF_LOCATION="/etc/httpd/conf.d"
      ;;
    'ubuntu' )
      local APP_SERVICES="apache2 mariadb"
      local APACHE_USER="www-data"
      local APACHE_CONF_LOCATION="/etc/apache2/sites-available"
      ;;
  esac

  create_host () {
      {
        echo "  Alias /$URL_SLUG \"$APP_INSTALL_DIR\""
        echo "  Alias /$URL_SLUG_ALT \"$APP_INSTALL_DIR\""
        echo ""
        echo "  <Directory \"$APP_INSTALL_DIR\">"
        echo "      Allow From All"
        echo "      AllowOverride All"
        echo "      Require all granted"
        echo "      Options -Indexes"
        echo "  </Directory>"
      } > $APACHE_CONF_LOCATION/$APP_USER.conf
    }

  # Give some space
  printf \\n
  # Let the user know we're ready
  printf "%1s %b %b%s %s%b\\n" "" $INFO $COLOUR_GREEN "Installing" $APP_NAME $COLOUR_NC
  
  # Is the application already installed?
  if ! [[ -d $APP_INSTALL_DIR ]]; then
  
  # Configuring 
    printf "  $INFO Getting things ready before installation... \\n"
      # add user
      case $ENV_DISTRO in
        'fedora' | 'centos' )
          printf "  $BUSY Adding user [${COLOUR_YELLOW}${APP_USER}${COLOUR_NC}]... "
            adduser --home-dir $APP_INSTALL_DIR $APP_USER > /dev/null 2>&1
          printf "done\\n"
          ;;
        'ubuntu' )
          printf "  $BUSY Adding user [${COLOUR_YELLOW}${APP_USER}${COLOUR_NC}]... "
            adduser --quiet --gecos \"\" --home $APP_INSTALL_DIR --disabled-password $APP_USER > /dev/null 2>&1
          printf "done\\n"
          ;;
      esac
      # set directory permissions
      chmod 755 $APP_INSTALL_DIR
      # set user password
      yes $ENV_PASSWORD 2>/dev/null | passwd $APP_USER > /dev/null 2>&1
      # set user group
      usermod -aG $APACHE_USER $APP_USER
  # done

  # Download and install
    printf "  $INFO Downloading and installing GLPi...\\n"
      printf "   $BUSY Downloading GLPi... "
        # Download application archive.
        wget -q -nc -P $APP_TMP_DIR https://github.com/glpi-project/glpi/releases/download/$APP_VER/glpi-$APP_VER.tgz
      printf "done\\n"

      printf "   $BUSY Moving files... "
        tar -xf $APP_TMP_DIR/glpi-$APP_VER.tgz -C $APP_INSTALL_ROOT
        chown -R $APACHE_USER:$APACHE_USER $APP_INSTALL_DIR
      printf "done\\n"
  # done

  # Prepare database
    printf "  $INFO Preparing database...\\n"
      prepare_database
  # done

  # Initialise time zone data
    printf "  $BUSY Initialising time zone data..."
      mysql_tzinfo_to_sql /usr/share/zoneinfo > /dev/null 2>&1 | mysql -u root -D mysql -p"$ENV_PASSWORD" > /dev/null 2>&1
      mysql -u root -p"$ENV_PASSWORD" -e "GRANT ALL PRIVILEGES ON mysql.time_zone_name TO $APP_USER@localhost" > /dev/null 2>&1
    printf "done\\n"
  # done

  # Create virtual host 
    printf "  $BUSY Creating site configuration... "
      create_host
      if [[ "$ENV_DISTRO" == "ubuntu" ]]; then
        a2ensite $APP_USER.conf > /dev/null 2>&1
        a2enmod rewrite > /dev/null 2>&1
      fi
    printf "done\\n"
  # done

  # Enable and start services
    printf "   $INFO Starting services...\\n"
    start_services --restart $APP_SERVICES
  # done
  
  # Clean up
    rm -R $APP_TMP_DIR
  
  else
    printf "   $TICK Already installed\\n"
  fi

}

main () {
  # Here we call all the functions
  # defined above in the correct
  # order.
  
      clear
  # - SHOW LOGO AND WELCOME
        show_ascii_logo
        show_welcome
  # - CHECK PRIVILEGES AND SUPPORTED OS
        check_privileges
        check_os
  # - INSTALL SCRIPT DEPENDENCIES
        install_script_deps
  # - SELINUX
        set_selinux
  # - TIME AND TIMEZONE
        get_timezone
        set_ntp
  # - INSTALL SOFTWARE DEPENDENCIES
        install_software_deps
  # - START SERVICES FOR FEDORA (dependency cycle)
        if [[ "$ENV_DISTRO" == "fedora" || "$ENV_DISTRO" == "centos" ]]; then start_services --enable httpd php-fpm mariadb; fi
  # - FIREWALL RULES
        write_homepage
  # - FIREWALL RULES
        config_firewall
  # - SECURE DATABASE
        secure_database
  # - INSTALL SOFTWARE (from recipes/functions)
        install_glpi
        install_zabbix
        install_snipeit
  # - DONE
      printf "\\n $TICK Access ${COLOUR_GREEN}${APPNAME}${COLOUR_NC} at ${COLOUR_PURPLE}http://${HOSTIP}${COLOUR_NC}\\n\\n"

  }

# =================================================
#   RUN SCRIPT
# =================================================

main
