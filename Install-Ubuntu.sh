#!/bin/bash
#
# Parsing options for the installation
# --vscode
# --intellij
# --scala
# --nodejs
# --dotnetcore 2.1|none
# --java default|openjdk|oraclejdk|none
# 
# ---
# Note: for quality checks, this is using super-linter from GitHub
#       details can be found at https://github.com/github/super-linter
#       you can run it locally using your own docker environment
#       docker run -e RUN_LOCAL=true -e VALIDATE_ALL_CODEBASE=false -eVALIDATE_BASH=true -v /pathtoyourcoderoot/devmachinesetup/:/tmp/lint github/super-linter
# ---
#

show_help()  {
    echo "Automatically install stuff on a typical Linux Developer Machine (Ubuntu-based)!"
    echo "Usage: Install-Ubuntu.sh --enduser --baseline --python --sysstat --sshsrv --docker --clis --ruby --golang --scala --nodejs --java default|openjdk|oraclejdk|none --dotnetcore 2|3|none --dotnetmono --vscode --moreDevTools --intellij --prompt"
}

instEnduser=0
instBase=0
instPrompt=0
instPython=0
instSysstat=0
instSshServer=0
instDockerEngine=0
instCLIs=0
instNodeJs=0
instDotNetCore="none"
instDotNetMono=0
instJava="none"
instScala=0
instRuby=0
instGoLang=0
instVsCode=0
instIntelliJ=0
instMoreDevTools=0

while :; do
    case $1 in
        -h|--help)
            show_help
            exit
            ;;
        --enduser)
            instEnduser=1
            ;;
        --baseline)
            instBase=1
            ;;
        --prompt)
            instPrompt=1
            instGoLang=1
            ;;
        --sshsrv)
            instSshServer=1
            ;;
        --sysstat)
            instSysstat=1
            ;;
        --docker)
            instDockerEngine=1
            ;;
        --clis)
            instCLIs=1
            instPython=1    # Many CLIs require python
            ;;
        --vscode)
            instVsCode=1
            ;;
        --moreDevTools)
            instMoreDevTools=1
            ;;
        --intellij)
            instIntelliJ=1
            ;;
        --python)
            instPython=1
            ;;
	    --golang)
            instGoLang=1
	        ;;
	    --ruby)
            instRuby=1
	        ;;
        --nodejs)
            instNodeJs=1
            ;;
        --scala)
            instScala=1
            ;;
        --java)
            if [ "$2" ]; then
                instJava=$2
                shift
            else
                instJava="default"
            fi
            ;;
        --dotnetcore)
            if [ "$2" ]; then
                instDotNetCore=$2
                shift
            else
                instDotNetCore=3
            fi
            ;;
        --dotnetmono)
            instDotNetMono=1
            ;;
        -?*)
            echo "WARN: ignoring unknown option $1" >&2
            ;;
        *)
            break
    esac

    shift
done


#
# Check Ubuntu Version
#
ver=$(lsb_release -r | cut -f 2)
if [ "$ver" != "16.04" ] && [ "$ver" != "18.04" ] && [ "$ver" != "20.04" ]; then 
    echo "Only Ubuntu 16.04, 18.04 and 20.04 have been tested!"
    exit 
fi


#
# General packages commonly used on my Linux Dev Machines
#
if [ $instBase == 1 ]; then

    sudo apt update
    sudo apt -y upgrade 

    # Known bug in Ubuntu 16.04 with missing package for GTK 
    sudo apt install -y gtk2-engines-pixbuf

    sudo apt install -y tmux
    sudo apt install -y debconf-utils
    sudo apt install -y net-tools
    sudo apt install -y dos2unix
    sudo apt install -y unzip
    sudo apt install -y curl

    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys D6BC243565B2087BC3F897C9277A7293F59E4889
    if [ "$ver" == "16.04" ]; then
        echo "deb http://miktex.org/download/ubuntu xenial universe" | sudo tee /etc/apt/sources.list.d/miktex.list
    elif [ "$ver" == "18.04" ]; then
        echo "deb http://miktex.org/download/ubuntu bionic universe" | sudo tee /etc/apt/sources.list.d/miktex.list
    elif [ "$ver" == "20.04" ]; then
	echo "deb [arch=amd64] http://miktex.org/download/ubuntu focal universe" | sudo tee /etc/apt/sources.list.d/miktex.list
    fi 
    sudo apt update
    sudo apt install -y miktex

    sudo apt install -y ffmpeg
    sudo apt install -y mencoder
    sudo apt install -y libpng-dev

    # Git including enabling large-file-store scenarios (git-lfs)
    sudo apt install -y git
    sudo apt install -y git-lfs
    
    sudo apt install -y jq
    sudo apt install -y zlib1g-dev
    sudo apt install -y libxml2
    sudo apt install -y build-essential

    # Install 'homebrew' on Ubuntu per https://brew.sh/
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    #test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv)
    # shellcheck disable=SC2046
    test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
    #test -r ~/.bash_profile && echo eval" ($(brew --prefix)/bin/brew shellenv)" >> ~/.bash_profile
    # shellcheck disable=SC2046
    echo "eval $($(brew --prefix)/bin/brew shellenv)" >> ~/.profile

    brew update

fi


#
# Installing end user tools for a desktop environment
#
if [ $instEnduser == 1 ]; then
    
    sudo snap install --edge 1password
    sudo snap install spotify
    
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo dpkg -i google-chrome-stable_current_amd64.deb
    
    sudo snap install telegram-desktop
    sudo snap install whatsapp-for-linux  
    sudo snap install skype
    
    sudo snap install --classic slack
    
    curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EB3E94ADBE1229CF
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/ms-teams stable main" | sudo tee /etc/apt/sources.list.d/teams.list
    sudo apt update
    sudo apt install -y teams

    sudo snap install unofficial-webapp-office
    
    sudo apt install -y calibre   
    
    sudo snap install remmina
    
    sudo sudo apt install -y mate-system-monitor
    
    sudo ufw enable
    sudo systemctl enable ufw
    sudo ufw default deny incoming
    
    sudo apt install -y p7zip-full
    
fi


#
# Installing Python
#
if [ $instPython == 1 ]; then
    sudo apt install -y python3
    sudo apt install -y python3-pip  
    sudo rm /usr/bin/python
    sudo ln /usr/bin/python3 /usr/bin/python
    sudo -H python -m pip install --upgrade pip

    sudo -H pip3 install numpy
    sudo -H pip3 install pytest
    sudo -H pip3 install mock
    sudo -H pip3 install Pillow
    sudo -H pip3 install GhostScript
    sudo -H pip3 install matplotlib
    sudo -H pip3 install autopep8
fi


#
# Installing Ruby on Rails
#
if [ $instRuby == 1 ]; then
    # Ruby and Jekyll for GitHub Pages

    sudo apt install -y ruby-full

    # shellcheck disable=SC1090
    {
        echo "# Install Ruby Gems to ~/gems"
        echo "export GEM_HOME=\"$HOME/gems\"" 
        echo "export PATH=\"\$HOME/gems/bin:\$PATH\""
    } >> ~/.bashrc

    # shellcheck disable=SC1090
    source ~/.bashrc

    sudo gem install jekyll bundler
fi


#
# Installing Go Language
#
if [ $instGoLang == 1 ]; then
    sudo apt install -y golang-go
fi


#
# Install packages needed on a full server, only
#
if [ $instSshServer == 1 ]; then
    sudo apt install -y openssh-server
fi


#
# Install and configure sysstat tools (iostat, top etc.)
#
if [ $instSysstat == 1 ]; then
    sudo apt-get install -y sysstat
    awk '{gsub("ENABLED=\"false\"", "ENABLED=\"true\"")}1' /etc/default/sysstat | sudo tee /etc/default/sysstat
    # Update /etc/cron.d/sysstat for more frequent intervals
    # Change "5-55/10 * * * * root command -v debina-sa1 > /dev/null && debian-sa1 1 1"
    # To     "*/2 * * * * root command -v debian-sa1 > /dev/null && debian-sa1 1 1"
fi


#
# Install docker engine
#
if [ $instDockerEngine == 1 ]; then

   sudo apt -y install \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg-agent \
        software-properties-common

   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
   
   sudo apt-key fingerprint 0EBFCD88
   
   sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
   
   sudo apt update
   sudo apt install -y docker-ce containerd.io	# Not installing docker-ce-cli because of using dvm for that
   
   # groupadd was not needed after the installation
   #sudo groupadd docker
   sudo usermod -aG docker "$USER"

fi


#
# Installing Java with package manager
#
case $instJava in
    openjdk)
        sudo apt-get install -y openjdk-8-jdk
        # Set JAVA_HOME as an environment variable for the entire system
        echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/" | sudo tee /etc/profile.d/set_java_home.sh
        sudo chmod +x /etc/profile.d/set_java_home.sh
        # Bug in OpenJDK 9 with missing directory for security classes
        # https://github.com/docker-library/openjdk/issues/101
        sudo ln -s "$JAVA_HOME/lib" "$JAVA_HOME/conf"
        sudo apt install -y maven
        ;;

    oraclejdk)
        sudo add-apt-repository ppa:webupd8team/java
        sudo apt update
        echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
        echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
        sudo apt install -y oracle-java8-installer
        sudo apt install -y maven
        ;;

    default)
        sudo apt-get install -y default-jdk
        sudo apt install -y maven
        ;;
esac


#
# Installing Scala SBT with package manager
#
if [ $instScala == 1 ]; then
    echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823
    sudo apt update
    sudo apt install -y sbt
fi


#
# NodeJS Installation with NVM
#
if [ $instNodeJs == 1 ]; then
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1090
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"	# Loading NVM into the current session
    # shellcheck disable=SC1090
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # Loading nvm bash_completion

    # shellcheck disable=SC1090
    source ~/.profile

    nvm install --lts	# Install the latest LTS build of Node
    npm install -g moment
    npm install -g bower        # Consider replacing with WebPack, Yarn or Parcel 
    npm install -g gulp
    npm install -g autorest@3.0.6187
    npm install -g swagger-tools@0.10.4
    
    # This particular version 3.0.6187 of autorest depends on libssl1.0, hence on Ubuntu 20.04 need to install this version of the library, as well
    if [ "$ver" == "20.04" ]; then
    	wget -O libssl1.0.0_1.0.1t-1+deb8u12_amd64.deb http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u12_amd64.deb
        wget -O multiarch-support_2.19-18+deb8u10_amd64.deb http://ftp.de.debian.org/debian/pool/main/g/glibc/multiarch-support_2.19-18+deb8u10_amd64.deb

        sudo dpkg -i multiarch-support_2.19-18+deb8u10_amd64.deb
        sudo dpkg -i libssl1.0.0_1.0.1t-1+deb8u12_amd64.deb
    fi
fi


#
# Installing .Net core runtimes
#
if [ "$instDotNetCore" != "none" ]; then   
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg

    if [ "$ver" == "16.04" ]; then        
        wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb
    elif [ "$ver" == "18.04" ]; then
        wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
    elif [ "$ver" == "20.04" ]; then
        wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
    fi
    sudo dpkg -i packages-microsoft-prod.deb
    
    # Needed on Ubuntu 18.04 in WSL
    if [ "$ver" == "18.04" ]; then
        sudo add-apt-repository "deb http://security.ubuntu.com/ubuntu xenial-security main"
        sudo apt update 
        sudo apt install -y libicu55
    fi

    sudo add-apt-repository universe
    sudo apt update
    sudo apt install -y apt-transport-https
    sudo apt update
fi 

case $instDotNetCore in
    2)
        sudo apt install -y dotnet-sdk-2.2
        sudo apt install -y powershell
        ;;

    3)
        sudo apt install -y dotnet-sdk-3.1
        sudo apt install -y powershell
        # Alternatively
        #dotnet tool install -g powershell
        #echo "export PATH=\"\$HOME/.dotnet/tools:\$PATH\"" >> ~/.profile
        # shellcheck disable=SC1090
        source ~/.profile
        ;;

    none)
        ;;
esac


#
# Installing Mono for .NET
#
if [ $instDotNetMono == 1 ]; then
    sudo apt install gnupg ca-certificates
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
    echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
    
    sudo apt update
    sudo apt install -y mono-devel
fi


#
# Installing various CLIs
#
if [ $instCLIs == 1 ]; then

    # All goes into CLIs if not installed via package
    mkdir ~/clis
    existsclis=$(grep "$HOME/clis" ~/.profile)
    if [ "$existsclis" == "" ]; then
        # shellcheck disable=SC1090
        echo "export PATH=\"\$HOME/clis:\$PATH\"" >> ~/.profile
        # shellcheck disable=SC1090
        source ~/.profile
    fi

    # Install Azure CLI and plug-ins
    # Workaround needed on WSL / Ubuntu 18.04 LTS for some reason:
    sudo rm -rf /usr/lib/python3/dist-packages/PyYAML-*
    # After Workaround, can install azure CLI without issues
    sudo -H pip3 install azure-cli
    dos2unix az-cli.extensions
    while read -r azext; do 
        az extension add --name "$azext"
    done < az-cli.extensions

    # Install other cloud provider CLIs
    sudo -H pip3 install awscli

    # Install Docker CLI
    #curl -L "https://download.docker.com/linux/static/stable/x86_64/docker-18.06.1-ce.tgz" | tar -xz
    #mv ./docker/* ~/clis
    #rm ./docker -R
    curl -sL https://howtowhale.github.io/dvm/downloads/latest/install.sh | sh
    # shellcheck disable=SC1090
    echo "source ~/.dvm/dvm.sh" >> ~/.bashrc
    # shellcheck disable=SC1090
    source ~/.dvm/dvm.sh
    dvm install 17.12.1-ce
    dvm install 18.09.6

    # Latest kubectl
    kubeversion=$(curl -s "https://storage.googleapis.com/kubernetes-release/release/stable.txt")
    wget -O ~/clis/kubectl "https://storage.googleapis.com/kubernetes-release/release/$kubeversion/bin/linux/amd64/kubectl"
    chmod +x ~/clis/kubectl
    
    # Krew extension manager
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz"
    tar zxvf krew.tar.gz
    mv krew* ~/clis
    KREW=~/clis/krew-"$(uname | tr '[:upper:]' '[:lower:]')_$(uname -m | sed -e 's/x86_64/amd64/' -e 's/arm.*$/arm/')"
    "$KREW" install krew
    cp "$KREW" ./krew
    echo "export PATH=\"${KREW_ROOT:-$HOME/.krew}/bin:$PATH\"" >> ~/.profile
    # shellcheck disable=SC1090
    source ~/.profile
    # Install the plug-ins
    krew install krew
    krew install exec-as
    

    # Helm CLI
    # curl -L "https://storage.googleapis.com/kubernetes-helm/helm-v2.11.0-linux-amd64.tar.gz" | tar -zx
    # mv ./linux-amd64/* ~/clis
    # rm ./linux-amd64 -R
    curl -L https://git.io/get_helm.sh | bash

    # Cloud Foundry CLI
    curl -L "https://packages.cloudfoundry.org/stable?release=linux64-binary&source=github" | tar -zx
    mv cf ~/clis

    # OpenShift CLI
    curl -L "https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz" | tar -zx
    mv ./openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit/* ~/clis 
    
    # Remove Temporary files
    rm ./LICENSE
    rm ./NOTICE
    rm ./openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit -r

    # armclient GO-version for Linux
    curl -sL https://github.com/yangl900/armclient-go/releases/download/v0.2.3/armclient-go_linux_64-bit.tar.gz | tar xz
    mv armclient ~/clis
    rm ./LICENSE

fi


#
# Installing IntelliJ IDEA Communtiy from un-supported package source
# https://launchpad.net/~mmk2410/+archive/ubuntu/intellij-idea
#
if [ $instIntelliJ == 1 ]; then
    sudo snap install intellij-idea-community --classic --edge
fi


#
# Installing Visual Studio Code and most used extensions
#
if [ $instVsCode == 1 ]; then
    sudo snap install --classic code 
    #sudo snap install --classic code-insiders

    # Start installing all extensions
    dos2unix vscode.extensions
    while read -r vscodeext; do 
        code --install-extension "$vscodeext"
    done < vscode.extensions
fi


#
# Installing cloud tools such as Azure Data Studio etc.
#
if [ $instMoreDevTools == 1 ]; then

   # Azure Data Studio
   wget -O azuredatastudio-linux.deb https://go.microsoft.com/fwlink/?linkid=2138508
   sudo dpkg -i ./azuredatastudio-linux.deb
   
   # Azure Storage Explorer
   sudo snap install storage-explorer
   sudo snap connect storage-explorer:password-manager-service :password-manager-service
   
   # Postman
   sudo snap install postman
   
   # MQTT Explorer
   sudo snap install mqtt-explorer
   
   # Arduino IDE
   sudo snap install arduino
   sudo usermod -a -G dialout "$USER"
   
   # Redis Desktop Manager
   sudo snap install redis-desktop-manager
   
   # Installing the Cascadia code font
   sudo apt install -y unzip
   wget -O "cascadiacodepl.zip" "https://github.com/microsoft/cascadia-code/releases/download/v2005.15/CascadiaCode_2005.15.zip"
   unzip "cascadiacodepl.zip" -d "./cascadiacodepl"
   sudo mkdir "/usr/local/share/fonts/cascadiacodepl"
   sudo cp ./cascadiacodepl/ttf/*.ttf /usr/local/share/fonts/cascadiacodepl/

fi


#
# Installing components for a pretty prompt
# I know this is not the most beautiful way, but this is sparetime and hence I had to rush
#
if [ $instPrompt == 1 ]; then

    go get -u github.com/justjanne/powerline-go

    goPathExists=$(grep GOPATH ~/.bashrc)
    if [ ! "$goPathExists" ]; then
        # shellcheck disable=SC1090
        {
            echo ""
            echo "GOPATH=$HOME/go"
        } >> ~/.bashrc
    fi

    # shellcheck disable=SC1090
    promptIsThere=$(grep "#mszcool_prompt" ~/.bashrc)
    if [ ! "$promptIsThere" ]; then
        # shellcheck disable=SC1090
        {
            printf "\n"
            printf "#mszcool_prompt_start\n"
            printf "function _update_ps1() {\n"
            printf "  PS1=\"\$(\$GOPATH/bin/powerline-go -error \$?)\\\n\\\$ \"\n"
            printf "}\n"
            printf "if [ \"\$TERM\" != \"linux\" ] && [ -f \"\$GOPATH/bin/powerline-go\" ]; then\n"
            printf "    PROMPT_COMMAND=\"_update_ps1; \$PROMPT_COMMAND\"\n"
            printf "fi\n"
            printf "#mszcool_prompt\n"
        } >> ~/.bashrc
    fi

    # shellcheck disable=SC1090
    source ~/.profile
    # shellcheck disable=SC1090
    source ~/.bashrc

fi
