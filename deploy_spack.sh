#!/bin/bash
module --force purge

module load Stages/2022
module load Intel/2021.4.0 ParaStationMPI/5.5.0-1
module load HDF5/1.12.1

set -e
# Deployment directory
project=$1
DEPLOYMENT_HOME=/p/project/$project/opt/

CONFIG_HOME=`dirname $0`

# Clone spack repository and setup environment
cd $DEPLOYMENT_HOME
[[ -d spack ]] || git clone https://github.com/BlueBrain/spack.git -b jusuf_deployment_2022

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
neurodamus_deps="^coreneuron $PYTHON_VERSION"
spack spec -Il neurodamus-hippocampus+coreneuron %intel $neurodamus_deps
for nd in neurodamus-hippocampus neurodamus-neocortex neurodamus-mousify
do
   spack install --keep-stage --dirty -v $nd+coreneuron %intel $neurodamus_deps
done

spack module tcl refresh --delete-tree --latest -y
cd $DEPLOYMENT_HOME/modules/tcl/linux-centos7-zen2
find py* -type f -print0|xargs -0 sed -i '/PYTHONPATH.*\/neuron-/d'
