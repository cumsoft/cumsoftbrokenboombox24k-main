#!/usr/bin/env bash

# Debian 12 Openbox Script
# do after fresh netinstall of Debian 12 Bullseye Stable with firmware
# run as normal user - will prompt for sudo password

# define messaging function, waits for 3 seconds before proceeding
message () {
    echo
    echo "--~== $1 ==~--"
    echo
    sleep 3
}

cd $HOME

message "Updating packages"

# backup sources.list
sudo mv /etc/apt/sources.list /etc/apt/sources.list.bak

# add contrib to sources.list
sudo cat << EOF > /etc/apt/sources.list

deb http://deb.debian.org/debian/ bookworm main non-free-firmware contrib
deb-src http://deb.debian.org/debian/ bookworm main non-free-firmware contrib

deb http://security.debian.org/debian/ bookworm-security main non-free-firmware contrib
deb-src http://security.debian.org/debian/ bookworm-security main non-free-firmware contrib

deb http://deb.debian.org/debian/ bookworm-updates main non-free-firmware contrib
deb-src http://deb.debian.org/debian/ bookworm-updates main non-free-firmware contrib
EOF

sudo apt update && sudo apt -y upgrade

# check machine architecture
PROCESSOR=$(uname -m)
case $PROCESSOR in
  x86_64|amd64)
    arch="amd64"
    cpu="x86_64";;
  i?86)
    arch="x86"
    cpu="i686";;
  aarch64)
    arch="arm64"
    cpu="aarch64";;
esac

message "This OS runs on the $arch architecture"

message "Install basic utilities"

sudo apt install -y build-essential git subversion p7zip-full unzip \
zip curl bat exa linux-headers-$arch bsdmainutils htop

message "Installing Basic Xorg environment"

sudo apt install -y xserver-xorg-core openbox fonts-noto \
desktop-base jgmenu xterm x11-xserver-utils \
lxappearance lxappearance-obconf slick-greeter

message "Graphical boot splash screen"
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/' /etc/default/grub && sudo update-grub2

message "Microsoft Fonts"
sudo apt install -y ttf-mscorefonts-installer

# home directory default folders e.g. Downloads, Documents etc.
xdg-user-dirs-update

# creating config directories in ~/.config
mkdir -p $HOME/.config/{openbox,rofi,jgmenu,tint2,helix}

message "Installing GUI software"

# file manager
sudo apt install -y thunar thunar-archive-plugin thunar-gtkhash \
thunar-font-manager thunar-volman

# wallpaper placer
sudo apt install -y feh

# archiver
sudo apt install -y engrampa

# sound volume
sudo apt install -y pavucontrol pnmixer

# internet and firewall
sudo apt install -y firefox-esr transmission-gtk ufw
sudo ufw enable

# media player
sudo apt install -y parole

# openbox utils
sudo apt install -y picom rofi tint2 xfce4-notifyd libnotify-bin \
gsimplecal light-locker ristretto lxpolkit redshift-gtk arc-theme

# office
sudo apt install -y zathura zathura-pdf-poppler zathura-djvu \
zathura-cb geany geany-plugins abiword gnumeric

# screenshots
sudo apt install -y kazam

# terminal
sudo apt install -y sakura

# logout interface
sudo apt install -y obsession

echo "Installing Pywal Themer"
message "Pywal sets terminal theme from wallpaper colours"
sudo apt -y install python3-pip python3-wheel python3-dev
sudo apt -y install python3-venv imagemagick
cd $HOME

message "Downloading Wallpapers"
mkdir -p $HOME/Pictures/wallpapers
cd $HOME/Pictures/wallpapers
wget https://raw.githubusercontent.com/jawuku/dotfiles/master/wallpapers/EznixOS/fall_lake.jpg

wget https://raw.githubusercontent.com/jawuku/dotfiles/master/wallpapers/MyDebOS/Flowery-Mountain-Side.jpg

message "Downloading Roboto Mono Nerd Font"
cd $HOME/Downloads
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/RobotoMono.zip

mkdir -p $HOME/.local/share/fonts

# extract fonts and install them
features = "MediumItalic Regular BoldItalic Light ThinItalic Medium Bold SemiBoldItalic Italic Thin SemiBold LightItalic"

for i in $features; do
    unzip -j RobotoMono.zip RobotoMonoNerdFont-$i.ttf -d $HOME/.local/share/fonts
done

fc-cache -fv

message "Openbox configuration"
cd $HOME/.config/openbox/

wget https://raw.githubusercontent.com/jawuku/dotfiles/master/.config/openbox/rc.xml
wget https://raw.githubusercontent.com/jawuku/dotfiles/master/.config/openbox/autostart

message "Rofi Program Launcher"
cd $HOME/.config/rofi

wget https://raw.githubusercontent.com/jawuku/dotfiles/master/.config/rofi/config.rasi

wget https://raw.githubusercontent.com/jawuku/dotfiles/master/.config/rofi/Adapta-Nokto.rasi

message "Tint2 panel config"
cd $HOME/.config/tint2

wget https://raw.githubusercontent.com/jawuku/dotfiles/master/.config/tint2/tint2rc

message "Build jgmenu dynamic desktop menu"
cd $HOME/.config/jgmenu

wget https://raw.githubusercontent.com/jawuku/dotfiles/master/.config/jgmenu/jgmenurc
wget https://raw.githubusercontent.com/jawuku/dotfiles/master/.config/jgmenu/append.csv
wget https://raw.githubusercontent.com/jawuku/dotfiles/master/.config/jgmenu/prepend.csv

message "Installing Icon Themes"

message "Installing Qogir Icon Theme"
cd $HOME/Downloads

git clone https://github.com/vinceliuice/Qogir-icon-theme.git

cd Qogir-icon-theme

./install.sh # installs into $HOME/.local/share/icons

message "Installing Tela Icon Theme"
cd $HOME/Downloads

git clone https://github.com/vinceliuice/Tela-icon-theme.git
cd Tela-icon-theme
./install.sh -a # option installs all colour variations

message "Installing Tela Circle Icon Theme"
cd $HOME/Downloads

git clone https://github.com/vinceliuice/Tela-circle-icon-theme.git
cd Tela-circle-icon-theme
./install.sh -a # option installs all colour variations

message "Installing Moka Icon Theme"
sudo apt -y install moka-icon-theme

message "Python Environment"
cd $HOME/Downloads

wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-${cpu}.sh"

bash Miniforge3-$(uname)-${cpu}.sh # follow interactive prompts

source $HOME/.bashrc

conda config --set auto_activate_base false

conda deactivate

conda create -n datasci python=3.11

conda activate datasci

conda install seaborn gmpy2 mpmath scipy scikit-learn pycountry \
beautifulsoup4 notebook requests ruff-lsp

conda deactivate

message "Installing Julia Language"
curl -fsSL https://install.julialang.org | sh
source $HOME/.bashrc
julia -e 'using Pkg; Pkg.add(["OhMyREPL", "Plots", "RowEchelon", "LanguageServer"])'

message "Installing Java"
sudo apt install -y openjdk-17-jdk

message "Installing Clojure"
sudo apt -y install rlwrap

cd ~/Downloads
# download official Clojure Installer
curl -L -O https://github.com/clojure/brew-install/releases/latest/download/posix-install.sh
chmod +x posix-install.sh
sudo ./posix-install.sh

# Install Leiningen
wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
sudo mv lein /usr/local/bin/
sudo chmod +x /usr/local/bin/lein
lein

# Clojure Language Server
sudo bash < <(curl -s https://raw.githubusercontent.com/clojure-lsp/clojure-lsp/master/install)

message "Installing Scala"
curl -fL https://github.com/coursier/coursier/releases/latest/download/cs-${cpu}-pc-linux.gz | gzip -d > cs && chmod +x cs && ./cs setup && ./cs install metals

source $HOME/.profile

message "Install Rust Language"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

message "Install R Language"
sudo apt install -y r-base r-base-dev r-recommended r-cran-tidyverse r-cran-irkernel

Rscript -e 'install.packages("languageserver", repos="https://cloud.r-project.org")'

cd $HOME/Downloads

message "Helix Text Editor"
sudo apt install -y snapd
sudo snap install core
sudo snap install helix --classic

message "Finished! Reboot to see your new Openbox system!"
