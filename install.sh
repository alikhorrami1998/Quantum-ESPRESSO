#!/bin/bash
set -e

# ---------------- Variables ----------------
SCALAPACK_PREFIX="/usr/local/scalapack"
QE_VERSION="7.4.1"
QE_DIR="q-e"
QE_TAR_URL="https://www.quantum-espresso.org/download/software/qe-${QE_VERSION}-ReleasePack.tar.gz"
INSTALL_PREFIX="/usr/local/quantum_espresso"
BUILD_DIR="build"

# ---------------- Dependencies ----------------
echo "Installing prerequisites..."
sudo apt update
sudo apt install -y \
  build-essential \
  gfortran \
  cmake \
  git \
  wget \
  libopenmpi-dev \
  openmpi-bin \
  libblas-dev \
  liblapack-dev \
  libfftw3-dev \
  libhdf5-openmpi-dev \
  libxc-dev \
  pkg-config

# ---------------- SCALAPACK from GitHub ----------------
echo "Cloning SCALAPACK from GitHub..."
cd /tmp
git clone https://github.com/Reference-ScaLAPACK/scalapack.git
cd scalapack
mkdir build && cd build

BLAS_LIB=$(ldconfig -p | grep libblas.so | head -n1 | awk '{print $4}')
LAPACK_LIB=$(ldconfig -p | grep liblapack.so | head -n1 | awk '{print $4}')

cmake .. \
  -DCMAKE_INSTALL_PREFIX="${SCALAPACK_PREFIX}" \
  -DBLAS_LIBRARIES="${BLAS_LIB}" \
  -DLAPACK_LIBRARIES="${LAPACK_LIB}" \
  -DMPI_C_COMPILER=mpicc \
  -DMPI_Fortran_COMPILER=mpifort

make -j$(nproc)
sudo make install

# ---------------- Quantum ESPRESSO ----------------
echo "Downloading and building Quantum ESPRESSO ${QE_VERSION}..."
cd ~
wget -c "${QE_TAR_URL}"
tar -xzf "qe-${QE_VERSION}-ReleasePack.tar.gz"
mv qe-${QE_VERSION} "${QE_DIR}"
cd "${QE_DIR}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

cmake .. \
  -DQE_ENABLE_MPI=ON \
  -DQE_ENABLE_HDF5=ON \
  -DQE_ENABLE_SCALAPACK=ON \
  -DQE_ENABLE_LIBXC=ON \
  -DQE_ENABLE_TEST=ON \
  -DQE_FFTW_VENDOR=FFTW3 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
  -DSCALAPACK_DIR="${SCALAPACK_PREFIX}/lib"

make -j$(nproc)
sudo make install

# ---------------- Environment ----------------
echo "Updating environment..."
echo "export PATH=\$PATH:${INSTALL_PREFIX}/bin" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${INSTALL_PREFIX}/lib:${SCALAPACK_PREFIX}/lib" >> ~/.bashrc
source ~/.bashrc

echo "✅ Quantum ESPRESSO ${QE_VERSION} installed successfully!"
