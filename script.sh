#!/bin/bash
# TODO: Add app information and license here.

# Some things to remember
# TODO: Check how to work with coltable.
# TODO: Build a mechanism to check lowest supported versions of OS.
# TODO: Think about clean up
# TODO: Mail server, what to do?

# =================================================
#   DO THESE THINGS FIRST
# =================================================

# Check if we have root privileges
if [[ "$(id -u)" != "0" ]]; then
  # TODO: Make this a bit prettier with more information.
  # TODO: Add comments.
  printf "$COLOUR_LIGHT_RED""Please execute his script as root or sudo\\n""$COLOUR_NC"
  exit 0
fi
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

# -e option instructs bash to exit immediately if a simple command exits with a non-zero
# status, unless the command that fails is part of an until or while loop, part of an
# if statement, part of a && or || list, or if the command's return status
# is being inverted using !.  -o errexit
# set -echo

# -e option instructs bash to print a trace of simple commands and their arguments
# after they are expanded and before they are executed. -o xtrace
# set -x

# Bash matches patterns in a case-insensitive fashion when performing matching
# while executing case or [[ conditional commands.
shopt -s nocasematch

# =================================================
#   DECORATIONS
# =================================================

# ASCII Logo
show_ascii_logo() {
  echo -e "
╱╱╱╱╱╱╱╱╱╱╱╱╱╱$COLOUR_LIGHT_GREEN╭╮$COLOUR_NC╱╱╱╱$COLOUR_LIGHT_GREEN╭╮$COLOUR_NC╱$COLOUR_LIGHT_GREEN╭╮$COLOUR_NC
╱╱╱╱╱╱╱╱╱╱╱╱╱╱$COLOUR_LIGHT_GREEN┃┃$COLOUR_NC╱╱╱╱$COLOUR_LIGHT_GREEN┃┃╭╯╰╮$COLOUR_NC
$COLOUR_LIGHT_GREEN╭━━┳━┳━━┳━━┳━╮┃┃╭┳━━┫╰┻╮╭╯$COLOUR_NC
$COLOUR_LIGHT_GREEN┃╭╮┃╭┫┃━┫┃━┫╭╮┫┃┣┫╭╮┃╭╮┃┃$COLOUR_NC
$COLOUR_LIGHT_GREEN┃╰╯┃┃┃┃━┫┃━┫┃┃┃╰┫┃╰╯┃┃┃┃╰╮$COLOUR_NC
$COLOUR_LIGHT_GREEN╰━╮┣╯╰━━┻━━┻╯╰┻━┻┻━╮┣╯╰┻━╯$COLOUR_NC
$COLOUR_LIGHT_GREEN╭━╯┃$COLOUR_NC╱╱╱╱╱╱╱╱╱╱╱╱╱$COLOUR_LIGHT_GREEN╭━╯┃$COLOUR_NC
$COLOUR_LIGHT_GREEN╰━━╯$COLOUR_NC╱╱╱╱╱╱╱╱╱╱╱╱╱$COLOUR_LIGHT_GREEN╰━━╯$COLOUR_NC
  "
}

# Set some colours we can use throughout the script.
COLOUR_NC='\e[0m' # No Colour
COLOUR_LIGHT_RED='\e[1;31m' # Red
COLOUR_LIGHT_GREEN='\e[1;32m' # Green
COLOUR_LIGHT_YELLOW='\e[1;33m' # Yellow
COLOUR_LIGHT_PURPLE='\e[1;35m' # Purple
# Useful little boxes for display.
TICK="[${COLOUR_LIGHT_GREEN}✓${COLOUR_NC}]" # Creates a box with a tick [✓]
ERROR="[${COLOUR_LIGHT_RED}✗${COLOUR_NC}]" # Creates a box with a cross [✗]
INFO="[${COLOUR_LIGHT_YELLOW}i${COLOUR_NC}]" # Box with an [i], for information.
CHECK="[${COLOUR_LIGHT_PURPLE}\033[1m?\033[0m${COLOUR_NC}]" # Box with an [?], for validation.
BUSY="[${COLOUR_LIGHT_GREEN}◌${COLOUR_NC}]"
# Formatting
F_BOLD='\033[1m' # Bold formatting
F_ITAL='\033[3m' # Italics
F_END='\033[0m' # Ends formatting
F_CR='\\r'

# =================================================
#   FUNCTIONS
# =================================================

# Check for aborted or failed installations
unfinished_install () {
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
    printf "%b" \\n "$ERROR" "$COLOUR_LIGHT_YELLOW" " Unfinished install found." "$COLOUR_NC" \\n\\n
    # exit 0
  fi
}

# Run command as user
run_as_user () {
  # if ! hash sudo 2>/dev/null; then
      su -c "$@" $APP_USER
  # else
      # sudo -i -u $APP_USER "$@"
  # fi
}

# WRITE STUFF HERE
# #########################################################
execute_and_log () {
  eval "$@" | tee -a $APP_LOG
}

# WRITE STUFF HERE
# #########################################################
get_timezone () {
  local curlResult=$(curl 'https://ipapi.co/timezone' 2>&1;printf \\n$?)
  local curlExitCode="${curlResult##*$'\n'}"
  # Check if we can get a timezone from ipapi.co
  if [[ "$curlExitCode" -eq 0 ]]; then
    # if we can, assign it to a variable
    ENV_TIMEZONE=$(echo "$curlResult" | awk 'NR==4{print $0}')
    return 0
  else
    # otherwise, get it locally.
    case $ENV_DISTRO in
      'fedora' )
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

# WRITE STUFF HERE
# #########################################################
database_secure () {
  # -q, --quiet     Quiet (no output)
  if ! [[ "$@" =~ "-q" ||  "$@" =~ "--quiet" ]]; then printf "  $BUSY Securing database... "; fi
  # Set the root mysql password and,
  mysqladmin -u root password "$ENV_PASSWORD" > /dev/null 2>&1
  # secure the database. Based on the actions performed by the mysql_secure_installation command.
  mysql -u root -p"$ENV_PASSWORD" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')" > /dev/null 2>&1
  mysql -u root -p"$ENV_PASSWORD" -e "DELETE FROM mysql.user WHERE User=''" > /dev/null 2>&1
  mysql -u root -p"$ENV_PASSWORD" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'" > /dev/null 2>&1
  mysql -u root -p"$ENV_PASSWORD" -e "FLUSH PRIVILEGES" > /dev/null 2>&1
  if ! [[ "$@" =~ "-q" || "$@" =~ "--quiet" ]]; then printf "done.\\n"; fi
}

# WRITE STUFF HERE
# #########################################################
database_prepare () {
  local APP_DBNAME=${APP_USER}
  printf "  $BUSY Creating database for $APP_NAME... "
  # Create databases, users and grant privileges
  mysql -u root -p"$ENV_PASSWORD" -e "CREATE USER '$APP_USER'@localhost IDENTIFIED BY '$ENV_PASSWORD'" > /dev/null 2>&1
  mysql -u root -p"$ENV_PASSWORD" -e "CREATE DATABASE $APP_DBNAME character set utf8 collate utf8_bin" > /dev/null 2>&1
  mysql -u root -p"$ENV_PASSWORD" -e "GRANT ALL PRIVILEGES ON $APP_DBNAME.* TO $APP_USER@localhost" > /dev/null 2>&1
  printf "done.\\n"
}

# WRITE STUFF HERE
# #########################################################
set_selinux () {
  if [[ "$ENV_DISTRO" == "fedora" ]]; then
    printf " $INFO SELinux\\n"
    if [[ $(awk -F = -e '/^SELINUX=/ {print $2}' /etc/selinux/config) == "enforcing" ]]; then
      printf "  $TICK SELinux is enabled, disabling... "
      setenforce 0
      sed -E -c -i 's/(^SELINUX*=)(.*)/\1disabled/' /etc/selinux/config
      printf "done.\\n\\n"
    else
      printf "  $TICK SELinux already disabled.\\n\\n"
    fi
  fi
}

# WRITE STUFF HERE
# #########################################################
start_services () {
  # -r, --restart    Restarts services
  # 
  if [[ "$ENV_DISTRO" == "fedora" ||  "$ENV_DISTRO" == "ubuntu" ]]; then
  #   for service in $APP_SERVICES; do
  #     if ! [[ "$@" == "-r" || "$@" == "--restart" ]]; then printf "  $TICK Enabling $service..."; else printf "  $TICK Reloading $service..."; fi
  #     # enable them one by one.
  #     if ! [[ "$@" == "-r" || "$@" == "--restart" ]]; then
  #       systemctl enable --now $service > /dev/null 2>&1
  #     else
  #       systemctl restart $service > /dev/null 2>&1
  #     fi
  #       if [[ $? -eq 0 ]]; then
  #         echo -e " done."
  #       else
  #         echo -e "$COLOUR_LIGHT_RED failed.$COLOUR_NC"
  #       fi
  #   done
  # else
  #   echo - " $ERROR Cannot start or stop services on this OS."



    while [[ "$#" -gt 0 ]]; do
      case $1 in
        --enable )
          local param="enable"
          ;;
        --restart )
          local param="restart"
          ;;
        * )
          local services+=($1)
          ;;
      esac
      shift
    done

    case $param in
      enable )
        for service in "${services[@]}"; do
          printf "  $TICK Enabling $service..."
          systemctl enable $service > /dev/null 2>&1
          systemctl start $service > /dev/null 2>&1
          if [[ $? -eq 0 ]]; then
            echo -e " done."
          else
            echo -e "$COLOUR_LIGHT_RED failed.$COLOUR_NC"
          fi
        done
        ;;
      restart )
        for service in "${services[@]}"; do
          printf "  $TICK Reloading $service..."
          systemctl restart $service > /dev/null 2>&1
          if [[ $? -eq 0 ]]; then
            echo -e " done."
          else
            echo -e "$COLOUR_LIGHT_RED failed.$COLOUR_NC"
          fi
        done
        ;;
    esac
  fi


}

# WRITE STUFF HERE
# #########################################################
firewall_config () {
  case $ENV_DISTRO in
    'fedora')
      printf "  $TICK Adding firewall rules... "
      # Add firewall rules to open the necessary ports.
      firewall-cmd --permanent --add-service=http --add-service=https > /dev/null 2>&1
      firewall-cmd --permanent --add-port=10050-10051/tcp > /dev/null 2>&1
      systemctl restart firewalld
      printf "done.\\n"
      ;;
    'ubuntu')
      printf "  $TICK Adding firewall rules... "
      # Add firewall rules to open the necessary ports.
      ufw allow 80/tcp > /dev/null 2>&1
      ufw allow 443/tcp > /dev/null 2>&1
      ufw allow 10050/tcp > /dev/null 2>&1
      ufw allow 10051/tcp > /dev/null 2>&1
      printf "done.\\n"
      ;;
  esac
}

# VARIABLES
# Get some important information
get_org_var () {
  read -e -p "What is your domain name: " ORG_DOMAIN
  read -e -p "What's the email address of the administrator: " ORG_ADMIN_EMAIL

  printf "\\nPlease check that all the information below is correct:\\n"
  printf " $CHECK Domain name: $COLOUR_LIGHT_GREEN$ORG_DOMAIN$COLOUR_NC\\n"
  printf " $CHECK Administrator email: $COLOUR_LIGHT_GREEN$ORG_ADMIN_EMAIL$COLOUR_NC\\n"
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

# DEPENDENCIES
install_deps () {

  # Dependencies differ between distributions, define them here.
  local packages_fedora='fping git httpd libssh2 mariadb mariadb-devel mariadb-server net-snmp-libs OpenIPMI-libs php php-bcmath php-cli php-common php-embedded php-fpm php-gd php-json php-ldap php-mbstring php-mcrypt php-mysqlnd php-pdo php-simplexml php-xml php-zip unixODBC unzip'
  local packages_ubuntu_18='apache2 apache2-bin apache2-data apache2-utils fonts-dejavu fonts-dejavu-extra fping libapache2-mod-php7.4 libapr1 libaprutil1 libaprutil1-dbd-sqlite3 libaprutil1-ldap libgd3 libltdl7 libmysqlclient20 libodbc1 libopenipmi0 libsnmp-base libsnmp30 libssh-4 mariadb-client mariadb-server mariadb-common php7.4 php7.4-bcmath php7.4-cli php7.4-common php7.4-curl php7.4-gd php7.4-json php7.4-ldap php7.4-mbstring php7.4-mysql php7.4-opcache php7.4-readline php7.4-xml php7.4-zip snmpd ssl-cert'
  local packages_ubuntu_20='apache2 apache2-bin apache2-data apache2-utils fonts-dejavu fonts-dejavu-extra fping libapache2-mod-php libapr1 libaprutil1 libaprutil1-dbd-sqlite3 libaprutil1-ldap libgd3 libltdl7 libmysqlclient21 libodbc1 libopenipmi0 libsnmp-base libsnmp35 libssh-4 mariadb-client mariadb-server php php-bcmath php-cli php-common php-curl php-gd php-json php-ldap php-mbstring php-mysql php-opcache php-readline php-xml snmpd ssl-cert'

  # Fedora Install
  if [[ "$ENV_DISTRO" == "fedora" ]]; then
    # List of packages
    local packages=${packages_fedora}
    # TODO: Build a info system. See Ubuntu section.
    # local info=$(yes n | dnf install $packages 2>&1 | grep "Total download size" | sed "s/Total download size: \(.*\)/\1/")
    # printf " $INFO Dependencies download size: $info\\n"


    # Loop through the list above and install each package
    for p in $packages; do
      printf "  $BUSY Installing $COLOUR_LIGHT_GREEN$p$COLOUR_NC... "
      # Check if the package isn't already installed.
      if dnf list installed "$p" > /dev/null 2>&1; then
        printf "already installed.\\n"
      else
        # If not, run the dnf install command in a subshell and save the results to a variable,
        local execute=$(dnf install -y $p 2>&1)
        # then check the output for information. 
        if [[ $execute =~ "no match for argument" ]]; then
          # Package not available
          printf "can't find "$COLOUR_LIGHT_RED$p$COLOUR_NC".\\n"
        elif [[ $execute =~ "complete" ]]; then
          # Installed!
          printf "done.\\n"
        # Any errors will go here.
        else
          printf " $ERROR Yikes, something broke. Better investigate.\\n$COLOUR_LIGHT_YELLOW$execute$COLOUR_NC\\n\\n"
        fi
      fi
    done
  
  # Ubuntu Install
  elif [[ "$ENV_DISTRO" == "ubuntu" ]]; then
    # We have to check our OS version, packages are different and some needs extra repositories.
    if [[ "$ENV_DISTRO_VERSION_ID" == "20.04" ]]; then
      local packages=${packages_ubuntu_20}
    elif [[ "$ENV_DISTRO_VERSION_ID" == "18.04" ]]; then
      local packages=${packages_ubuntu_18}
      # Add PHP7.4 repository
      apt -y install software-properties-common  > /dev/null 2>&1
      add-apt-repository -y ppa:ondrej/php  > /dev/null 2>&1
    else
      # TODO: Print a error message here to tell the user we only support Ubuntu 18.04 and 20.04
      printf ""
      exit 1
    fi

    local download_size=$(yes n | apt install $packages 2>&1 | grep "Need to get" | sed "s/Need to get \(.*\) of archives./\1/")

      if [[ -z $download_size ]]; then
        # TODO: There may be a flaw in the logic of only checking the download size. What if there's nothing to download, but something to update.
        printf " $TICK All dependencies installed.\\n"
      else
        printf " $INFO Dependencies download size: $download_size\\n"
        # Loop through the list above and install each package
        
        for p in $packages; do
          printf "  $BUSY Installing $COLOUR_LIGHT_GREEN$p$COLOUR_NC... "
          # Run the command in a subshell and save the results to a variable,
          if dpkg -s "$p" > /dev/null 2>&1; then
            printf "already installed.\\n"
          else
            local execute=$(apt install -y $p 2>&1)
            # then check the output for information. 
              # Package not available
            if [[ $execute =~ "unable to locate package" ]]; then
              printf "can't find "$COLOUR_LIGHT_RED$p$COLOUR_NC".\\n"
              # Installed!
            elif [[ $execute =~ "newly installed" ]]; then
              printf "done.\\n"
            # Any errors will go here.
            else
              printf " $ERROR Yikes, something broke. Better investigate.\\n$COLOUR_LIGHT_YELLOW$execute$COLOUR_NC\\n\\n"
            fi
          fi
        done
      fi
  
  # If there the distribution does not match any of the above, apologise and exit.
  else
    printf " $ERROR Sorry, can't install on this distribution. [$COLOUR_LIGHT_GREEN$NAME $VERSION$COLOUR_NC]. Exiting...\\n"
    exit 1
  fi

}

# Recipe for installing Zabbix
install_zabbix () {
  

  # REMOVE FOR main()
  # if [[ "$ENV_DISTRO" == "fedora" || "$ENV_DISTRO" == "ubuntu" ]]; then

    # Give some space
    printf \\n
    # let the user know we're ready
    printf " $INFO Ready to install Zabbix on $ENV_DISTRO_NAME $ENV_DISTRO_VERSION_FULL\\n\\n"
    
    # Get timezone data.
      # REMOVE FOR main()
      # get_timezone
      
    # Temporary location to save install files
      local APP_TMP_DIR="/tmp/$APPNAME/zabbix"
      local APP_USER="zabbix"
      local APP_NAME="Zabbix"
      if [[ "$ENV_DISTRO" == "fedora" ]]; then
        local APP_SERVICES="zabbix-server zabbix-agent"
        local HTTPD_SERVICE="httpd"
      elif [[ "$ENV_DISTRO" == "ubuntu" ]]; then
        local APP_SERVICES="zabbix-server zabbix-agent"
        local HTTPD_SERVICE="apache2"
      fi

    # Disable SELinux in Fedora
      # REMOVE FOR main()
      # set_selinux

    # Install packages
      # printf "  $INFO Checking dependencies...\\n"
      # REMOVE FOR main()
      # install_deps
    

    # Download and install Zabbix
      printf "  $INFO Downloading and installing Zabbix...\\n"
      # for Fedora
      # TODO: Add comments here.
        if [[ "$ENV_DISTRO" == "fedora" ]]; then
          printf "   $BUSY Downloading... "
          wget -q -nc -P $APP_TMP_DIR https://repo.zabbix.com/zabbix/5.2/rhel/8/x86_64/zabbix-agent-5.2.6-1.el8.x86_64.rpm https://repo.zabbix.com/zabbix/5.2/rhel/8/x86_64/zabbix-apache-conf-5.2.6-1.el8.noarch.rpm https://repo.zabbix.com/zabbix/5.2/rhel/8/x86_64/zabbix-server-mysql-5.2.6-1.el8.x86_64.rpm https://repo.zabbix.com/zabbix/5.2/rhel/8/x86_64/zabbix-web-mysql-5.2.6-1.el8.noarch.rpm https://repo.zabbix.com/zabbix/5.2/rhel/8/x86_64/zabbix-web-deps-5.2.6-1.el8.noarch.rpm https://repo.zabbix.com/zabbix/5.2/rhel/8/x86_64/zabbix-web-5.2.6-1.el8.noarch.rpm
          printf "done\\n"
          printf "   $BUSY Installing...\\n"
          rpm -import https://repo.zabbix.com/RPM-GPG-KEY-ZABBIX-A14FE591
          rpm -ivh $APP_TMP_DIR"/zabbix-*" > /dev/stdout
        fi
      # for Ubuntu
      # TODO: Add comments to this section.
        if [[ "$ENV_DISTRO" == "ubuntu" ]]; then
          # Get the deb package from the Zabbix repo
          local url='https://repo.zabbix.com/zabbix/5.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.2-1+ubuntu'$ENV_DISTRO_VERSION_ID'_all.deb'
          # TODO: Expand this error handling across the script.
          # TODO: Add comments to this section.
          printf "   $BUSY Downloading... "
          local wgetResult=$(wget -v -nc -P $APP_TMP_DIR $url 2>&1; echo $?)
          local wgetExitCode="${wgetResult##*$'\n'}"
            if [[ $wgetExitCode != 0 ]]; then
              printf "   $ERROR [$wgetExitCode] Error occurred, couldn't download Zabbix at:\\n  -> $url\\n"
              exit 1
            fi
          printf "done.\\n"

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
          # Set timezone information in /etc/zabbix/apache.conf file.
          printf "   $INFO Setting installation timezone to: $COLOUR_LIGHT_PURPLE$ENV_TIMEZONE$COLOUR_NC\\n"
          sed -E -i 's/(^.*)(# php_value date.timezone).*/\1php_value date.timezone '$(echo $ENV_TIMEZONE | sed 's/\//\\\//g')'/' /etc/zabbix/apache.conf
        fi

    # Give some space
    printf \\n

    # Prepare SQL database
      # Secure the database,
      printf "  $INFO Preparing database...\\n"
        # REMOVE FOR main()
        # database_secure # TODO: !! Run this only once. 
        # create users and grant privileges etc.
        # REMOVE FOR main()
        database_prepare
        printf "   $TICK$F_BOLD Database password [keep it in a safe place]$F_END: $COLOUR_LIGHT_PURPLE$ENV_PASSWORD$COLOUR_NC\\n"
      printf "   $TICK Done preparing database.\\n"

    # Give some space
    printf \\n


    
    # Configuring 
      printf "  $INFO Configuring ... \\n"
      # Add the database password to zabbix_server.conf file with some regex magic
        printf "   $BUSY Checking conf file... "
        sed -E -i 's/(^# DBPassword*=)/DBPassword='$ENV_PASSWORD'/' /etc/zabbix/zabbix_server.conf
        printf "done.\\n"

      # Load Zabbix schema from file
        printf "   $BUSY Loading Zabbix DB schema (this might take a while)... "
        # Check if the schema file exists,
        if [[ -f /usr/share/doc/zabbix-server-mysql/create.sql.gz ]]; then
          # and pipe the contents to mysql.
          zcat /usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql -u zabbix -D zabbix -p"$ENV_PASSWORD" > /dev/null 2>&1
          printf "done.\\n"
        else
          printf "already loaded.\\n"
        fi
      printf "   $TICK Configuration complete.\\n"


    # Give some space
    printf \\n

    # Reload all services.
      # printf " Initialising...\\n"
      # # REMOVE FOR main()
      # start_services --restart $APP_SERVICES
      # printf "done, thank you.\\n\\n"

    # Enable and start services
      printf "  $INFO Starting services...\\n"
      # REMOVE FOR main()
      start_services --restart $HTTPD_SERVICE
      start_services --enable $APP_SERVICES
      printf " done, thank you.\\n\\n"
      # REMOVE FOR main()
      # firewall_config

    # Give some space
    # printf \\n

    # Clean up
      rm -R $APP_TMP_DIR
  # REMOVE FOR main()
  # else
    # REMOVE FOR main()
    # printf "Nothing to do\\n"
  # REMOVE FOR main()
  # fi

}

# Snipe-IT recipe
install_snipeit () {
  
  # REMOVE FOR main() SNIPEIT
  # if [[ "$ENV_DISTRO" == "fedora" || "$ENV_DISTRO" == "ubuntu" ]]; then
    
    # Give some space
    printf \\n
    
    # let the user know we're ready
    printf " $INFO Ready to install Snipe-IT on $ENV_DISTRO_NAME $ENV_DISTRO_VERSION_FULL\\n\\n"
    
    create_vhost () {
      {
        # echo "<VirtualHost *:80>"
        # echo ""
        echo "  Alias /$URL_SLUG \"$APP_INSTALL_DIR/public\""
        echo ""
        echo "  <Directory $APP_INSTALL_DIR/public>"
        echo "      Allow From All"
        echo "      AllowOverride All"
        echo "      Require all granted"
        echo "      Options -Indexes"
        echo "  </Directory>"
        echo ""
        echo "  DocumentRoot $APP_INSTALL_DIR/public"
        # echo "  ServerName $(hostname --fqdn)"
        # echo ""
        # echo "</VirtualHost>"
      } > $APACHE_CONF_LOCATION/$APP_USER.conf
    }

    create_htaccess () {
      {
        echo '<IfModule mod_rewrite.c>'
        echo '    <IfModule mod_negotiation.c>'
        echo '        Options -MultiViews'
        echo '    </IfModule>'
        echo ''
        echo '    RewriteEngine On'
        echo "    RewriteBase /$URL_SLUG"
        echo ''
        echo '    # Uncomment these two lines to force SSL redirect in Apache'
        echo '    # RewriteCond %{HTTPS} off'
        echo '    # RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]'
        echo ''
        echo '    # Redirect Trailing Slashes If Not A Folder...'
        echo '    RewriteCond %{REQUEST_FILENAME} !-d'
        echo '    RewriteCond %{REQUEST_URI} (.+)/$'
        echo '    RewriteRule ^ %1 [L,R=301]'
        echo ''
        echo '    # Handle Front Controller...'
        echo '    RewriteCond %{REQUEST_FILENAME} !-d'
        echo '    RewriteCond %{REQUEST_FILENAME} !-f'
        echo '    RewriteRule ^ index.php [L]'
        echo ''
        echo '    # Handle Authorization Header'
        echo '    RewriteCond %{HTTP:Authorization} .'
        echo '    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]'
        # echo ''
        # echo '    # Security Headers'
        # echo '    # Header set Strict-Transport-Security "max-age=2592000" env=HTTPS'
        # echo '    # Header set X-XSS-Protection "1; mode=block"'
        # echo '    # Header set X-Content-Type-Options nosniff'
        # echo '    # Header set X-Permitted-Cross-Domain-Policies "master-only"'
        echo ''
        echo '</IfModule>'
      } > $APP_INSTALL_DIR/public/.htaccess
      # TODO: !! probably change file ownership here
    }

    # Start installing
    # if [[ "$ENV_DISTRO" == 'fedora' ]]; then

      # Disable SELinux in Fedora
      # REMOVE FOR main() SNIPEIT
      # set_selinux

      # Get timezone data.
      # REMOVE FOR main() SNIPEIT
      # get_timezone

      # Variables for installation
      local APP_TMP_DIR="/tmp/$APPNAME/snipe-it"
      local APP_INSTALL_DIR="/opt/snipe-it"
      local APP_USER="snipeit"
      local APP_NAME="Snipe-IT"
      local URL_SLUG="snipe-it"

      if [[ "$ENV_DISTRO" == "fedora" ]]; then
        local APP_SERVICES="httpd"
        local APACHE_USER="apache"
        local APACHE_CONF_LOCATION="/etc/httpd/conf.d"

      elif [[ "$ENV_DISTRO" == "ubuntu" ]]; then
        local APP_SERVICES="apache2"
        local APACHE_USER="www-data"
        local APACHE_CONF_LOCATION="/etc/apache2/sites-available"

      fi

      # ----  
      # Install packages
      # printf " $INFO Checking dependencies...\\n"
      # REMOVE FOR main() SNIPEIT
      # install_deps

      # Give some space
      printf \\n
      
      # Enable and start services
      # printf " $INFO Starting services...\\n"
      # REMOVE FOR main() SNIPEIT
      # start_services --enable $APP_SERVICES
      # REMOVE FOR main() SNIPEIT
      # firewall_config

      # Give some space
      # printf \\n

      printf " $INFO Preparing database...\\n"
      # REMOVE FOR main() SNIPEIT
      # database_secure
      # REMOVE FOR main() SNIPEIT
      database_prepare
      printf "  $TICK Done preparing database.\\n"

      # Give some space
      printf \\n

      # Configuring 
        printf " $INFO Getting things ready for installation... \\n"
          # add user
          case $ENV_DISTRO in
            'fedora' )
              adduser --home-dir $APP_INSTALL_DIR $APP_USER > /dev/null 2>&1
              ;;
            'ubuntu' )
              adduser --quiet --gecos \"\" --home $APP_INSTALL_DIR --disabled-password $APP_USER > /dev/null 2>&1
              ;;
          esac
          # set directory permissions
          chmod 755 $APP_INSTALL_DIR
          # set user password
          yes $ENV_PASSWORD | passwd $APP_USER > /dev/null 2>&1
          # set user group
          usermod -aG $APACHE_USER $APP_USER
        printf "  $TICK Done.\\n"
      
      # Give some space
      printf \\n

      # Download and install Snipe-IT
      printf " $INFO Downloading and installing Snipe-IT...\\n"
        
        printf "  $BUSY Downloading Snipe-IT... "
          # git clone
          git clone https://github.com/snipe/snipe-it $APP_TMP_DIR > /dev/null 2>&1
        printf "done.\\n"

        printf "  $BUSY Moving files... "
          # move files
          # Set shell option 'dotglod' to enable moving hidden (dot files) files.
          shopt -s dotglob
          mv $APP_TMP_DIR/* $APP_INSTALL_DIR 
          shopt -u dotglob
          rm $APP_INSTALL_DIR/{install,snipeit}.sh
          # change ownership
          chown -R $APP_USER:$APACHE_USER $APP_INSTALL_DIR
        printf "done.\\n"

      printf " $TICK Done downloading and installing.\\n"

      # Give some space
      printf \\n
      
      printf " $INFO Configuring ... \\n"
        
        printf "  $BUSY Configuring .env file... "
          # cp .env.example .env
          run_as_user "cd ~/; cp .env.example .env"
          # set config file options
          sed -E -i "s/(^APP_TIMEZONE=)(.*)/\1'"$(echo $ENV_TIMEZONE | sed 's/\//\\\//g')"'/" $APP_INSTALL_DIR/.env
          sed -E -i "s/(^DB_DATABASE=)(.*)/\1$APP_USER/" $APP_INSTALL_DIR/.env
          sed -E -i "s/(^DB_USERNAME=)(.*)/\1$APP_USER/" $APP_INSTALL_DIR/.env
          sed -E -i "s/(^DB_PASSWORD=)(.*)/\1$ENV_PASSWORD/" $APP_INSTALL_DIR/.env
        printf "done.\\n"

        printf "  $BUSY Running PHP Composer (this will take a while, grab a coffee while you wait)... "
          # get php composer
          run_as_user "cd ~/; curl -sS https://getcomposer.org/installer | php > /dev/null 2>&1"
          # run php composer
          run_as_user "cd ~/; php composer.phar install --no-dev --prefer-source > /dev/null 2>&1"

        printf "done.\\n"

        printf "  $BUSY Populating database... "
          # generate APP_KEY
          run_as_user "cd ~/; yes y | php artisan key:generate > /dev/null 2>&1"
          # migrate
          run_as_user "cd ~/; yes y | php artisan migrate > /dev/null 2>&1"

        printf "done.\\n"

        printf "  $BUSY Setting permissions... "
          # change ownership
          chmod -R 755 $APP_INSTALL_DIR/storage
          chmod -R 755 $APP_INSTALL_DIR/public/uploads
          chown -R $APACHE_USER $APP_INSTALL_DIR/{storage,vendor,public}
        printf "done.\\n"

        printf "  $BUSY Creating Apache VirtualHost... "
          # create apache.conf file
          create_vhost
          if [[ "$ENV_DISTRO" == "ubuntu" ]]; then
            a2ensite $APP_USER.conf > /dev/null 2>&1
            a2enmod rewrite > /dev/null 2>&1
          fi
        printf "done.\\n"

        printf "  $BUSY Creating .htaccess file... "
          # edit .htaccess
          create_htaccess
        printf "done.\\n"

      printf " $TICK Done configuring.\\n"

      # Give some space
      printf \\n

      printf " $BUSY Cleaning up... "
        # Clean up
        rm -R $APP_TMP_DIR
      printf "done.\\n"

      # Give some space
      printf \\n
      
      # ----
      # main () stop here
      printf " Initialising... \\n"
      # REMOVE FOR main() SNIPEIT
      start_services --restart $APP_SERVICES
      printf " done, thank you.\\n\\n"

      # Give some space
      printf \\n

    return 0
    # TODO: Print -- can only install on Fedora or Ubuntu.
  # REMOVE FOR main() SNIPEIT
  # fi

}


main () {
  
  if [[ "$ENV_DISTRO" == "fedora" || "$ENV_DISTRO" == "ubuntu" ]]; then
    
    # - SHOW LOGO
        show_ascii_logo
        printf "$INFO Ready to install from 'main()' on $ENV_DISTRO_NAME $ENV_DISTRO_VERSION_FULL\\n\\n"
    # - GET TIMEZONE
        get_timezone
    # - SELINUX
        set_selinux
    # - INSTALL DEPS
        install_deps
    # - START SERVICES FOR FEDORA
        if [[ "$ENV_DISTRO" == "fedora" ]]; then start_services --enable httpd php-fpm mariadb; fi
    # - FIREWALL RULES
        firewall_config
    # - SECURE DATABASE
        database_secure
    # - PREPARE DATABASE
        # database_prepare
    # - INSTALL SOFTWARE (from recipes/functions)
        # install_zabbix
        install_snipeit
    # - RESTART SERVICES
        # start_services --restart
    # - CONFIGURATIONS

    return 0
  fi

}

# RUN STUFF
main

# show_ascii_logo
# install_zabbix 
# install_snipeit
