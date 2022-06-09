#!/bin/bash
module --force purge

module load Stages/2022
#module load Intel/2021.4.0 ParaStationMPI/5.5.0-1
module load GCC/11.2.0
module load ParaStationMPI/5.5.0-1
module load HDF5/1.12.1
module load Doxygen

set -e
# Deployment directory
project=$1
DEPLOYMENT_HOME=/p/project/$project/opt/

script_path=`readlink -f $0`
CONFIG_HOME=`dirname $script_path`
echo "CONFIG_HOME=$CONFIG_HOME"

# Clone spack repository and setup environment
cd $DEPLOYMENT_HOME
# [[ -d spack ]] || git clone https://github.com/BlueBrain/spack.git -b jusuf_deployment_2022
[[ -d spack ]] || git clone https://github.com/spack/spack

# Setup environment
export SPACK_ROOT=`pwd`/spack
export PATH=$SPACK_ROOT/bin:$PATH
source $SPACK_ROOT/share/spack/setup-env.sh

# Copy configurations
mkdir -p $SPACK_ROOT/etc/spack/defaults/linux/
cp $CONFIG_HOME/*.yaml $SPACK_ROOT/etc/spack/defaults/linux/

# Directory for deployment
export SPACK_INSTALL_PREFIX=$DEPLOYMENT_HOME
module list

spack mirror list

# Python 3 packages
module load Python/3.9.6
module load SciPy-Stack/2021b
module list
export LC_ALL=en_US.utf8
export LANG=en_US.utf8
export LC_CTYPE=en_US.UTF-8

PYTHON_VERSION='^python@3.9.6'
nest_deps="$PYTHON_VERSION"
neuron_deps="$PYTHON_VERSION"

# SPECS
# spack spec -Il nest %gcc $nest_deps
spack spec -Il neuron %gcc $neuron_deps

# INSTALLS
# echo "NEST INSTALL"
# spack install --keep-stage --dirty -v nest %gcc $nest_deps

echo "NEURON INSTALL"
spack install --keep-stage --dirty -v neuron %gcc $neuron_deps

spack module tcl refresh --delete-tree --latest -y
cd $DEPLOYMENT_HOME/spack/modules/tcl/linux-centos7-zen2
find py* -type f -print0|xargs -0 sed -i '/PYTHONPATH.*\/neuron-/d'
