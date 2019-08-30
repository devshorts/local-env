#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.


# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/usr/local/opt/go/libexec/bin

# Customize to your needs...
for config_file ($HOME/.yadr/zsh/*.zsh) source $config_file
 
export PATH=/usr/local/bin:$PATH
. /Users/akropp/.rbenvrc
. ~/.bash_profile

source sc-aliases
export SC_AWS_ROLE_NAME='engineers'

. $HOME/src/EnvZ/bootstrap

export PKG_CONFIG_PATH=/Users/akropp/src/external/seabolt/build/dist/share/pkgconfig
export DYLD_LIBRARY_PATH=/Users/akropp/src/external/seabolt/build/dist/lib
export LD_LIBRARY_PATH=/Users/akropp/src/external/seabolt/build/dist/lib64
export C_INCLUDE_PATH=/Users/akropp/src/external/seabolt/build/dist/include

source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh