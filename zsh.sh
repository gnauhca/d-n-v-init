# !/bin/sh
sudo apt-get update;apt-get install zsh -y;chsh -s /bin/zsh;apt-get install git -y;apt-get install curl;yes | sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)";apt-get install autojump -y;echo '. /usr/share/autojump/autojump.sh' >> ~/.zshrc;apt-get install rsync -y;
