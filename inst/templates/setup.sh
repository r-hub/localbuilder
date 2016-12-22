
# Setup library -----------------------------------------------------------

mkdir -p ~/R
echo "source ~/.bashrc" >> ~/.bash_profile
echo "export PATH=$(ls -d /opt/R-*)/bin:\$PATH" >> ~/.bashrc
echo "export R_LIBS=~/R" >> ~/.bashrc
if [[ -z "$RBINARY" ]]; then
    echo "export RBINARY=R" >> ~/.bashrc
fi
. ~/.bashrc

# Set up repos: CRAN, BioC, local -----------------------------------------

## It seems that BiocInstaller removes custom repos, so we add our local
## repo at the end. We add it as the first repo, so that it will be used
## by default.

echo "options(repos = c(CRAN = '{{{ cran-repo }}}'))" >> ~/.Rprofile
$RBINARY -e "source('https://bioconductor.org/biocLite.R')"
echo "options(repos = BiocInstaller::biocinstallRepos())" >> ~/.Rprofile
echo "unloadNamespace('BiocInstaller')" >> ~/.Rprofile
echo "options(repos = c(LOCAL = '{{{ local-repo }}}', getOption('repos')))" \
     >> ~/.Rprofile

# Install sysreqs and remotes, if requested -------------------------------

if [[ "{{{ sysreqs }}}" == "TRUE" ]]; then
    $RBINARY -e "source('https://install-github.me/r-hub/sysreqs')"
fi

if [[ "{{{ remotes }}}" == "TRUE" ]]; then
    $RBINARY -e "source('https://install-github.me/r-pkgs/remotes')"
fi
