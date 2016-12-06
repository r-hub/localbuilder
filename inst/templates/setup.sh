
# Setup library -----------------------------------------------------------

mkdir -p ~/R
echo "source ~/.bashrc" >> ~/.bash_profile
echo "export PATH=$(ls -d /opt/R-*)/bin:\$PATH" >> ~/.bashrc
echo "export R_LIBS=~/R" >> ~/.bashrc
if [[ -z "$RBINARY" ]]; then
    echo "export RBINARY=R" >> ~/.bashrc
fi
. ~/.bashrc

# Set up CRAN repo --------------------------------------------------------

echo "options(repos = c(CRAN = '{{{ cran-repo }}}'))" >> ~/.Rprofile
$RBINARY -e "source('https://bioconductor.org/biocLite.R')"
echo "options(repos = BiocInstaller::biocinstallRepos())" >> ~/.Rprofile
echo "unloadNamespace('BiocInstaller')" >> ~/.Rprofile
