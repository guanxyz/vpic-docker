from ubuntu:16.04

RUN apt-get update

RUN apt-get -y install \
  vim\
  autoconf\
  cmake\
  gcc\
  git\
  gfortran\
  g++\
  libtool\
  libva-dev\
  mpich\
  openssh-server\
  pkg-config\
  python\
  python-dev\
  python-pip\
  xutils-dev\
  wget

# needed by mesa
RUN pip install mako

# build mesa
WORKDIR /usr/local
# this link will expire as mesa gets older and then become stable in an old release
# download, unpack, and remove tar file...keeps image smaller and reduces number of layers
RUN wget https://mesa.freedesktop.org/archive/11.2.1/mesa-11.2.1.tar.gz && tar xvzf mesa-11.2.1.tar.gz && rm mesa-11.2.1.tar.gz

WORKDIR /usr/local/mesa-11.2.1

RUN autoreconf -fi
RUN ./configure \
    --enable-osmesa\
    --disable-glx \
    --disable-driglx-direct\ 
    --disable-dri\ 
    --disable-egl \
    --with-gallium-drivers=swrast 
#    --enable-gallium-osmesa \
#    --enable-gallium-llvm=yes \
#    --with-llvm-shared-libs \

RUN make; make install

#RUN ln -s /usr/local/mesa-11.2.1/lib/gallium/libOSMesa.so /usr/local/lib

# build glu
ENV C_INCLUDE_PATH '/usr/local/mesa-11.2.9/include'
ENV CPLUS_INCLUDE_PATH '/usr/local/mesa-11.2.9/include'
WORKDIR /usr/local
RUN git clone http://anongit.freedesktop.org/git/mesa/glu.git

WORKDIR /usr/local/glu
RUN ./autogen.sh --enable-osmesa
RUN ./configure --enable-osmesa
RUN make
RUN make install


# checkout paraview
WORKDIR /usr/local

RUN git clone https://gitlab.kitware.com/paraview/paraview.git
WORKDIR /usr/local/paraview

RUN git checkout v5.0.1

RUN git submodule init
RUN git submodule update

RUN mkdir /usr/local/paraview.bin

# build paraview
WORKDIR /usr/local/paraview.bin
RUN cmake \
  -DBUILD_TESTING=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DPARAVIEW_ENABLE_CATALYST=ON  \
  -DPARAVIEW_ENABLE_PYTHON=ON \
  -DPARAVIEW_BUILD_QT_GUI=OFF \
  -DVTK_USE_X=OFF \
  -DOPENGL_INCLUDE_DIR=/usr/local/mesa-11.2.1/include \
  -DOPENGL_gl_LIBRARY=/usr/local/mesa-11.2.1/lib/libOSMesa.so \
  -DVTK_OPENGL_HAS_OSMESA=ON \
  -DOSMESA_INCLUDE_DIR=/usr/local/mesa-11.2.1/include \
  -DOSMESA_LIBRARY=/usr/local/mesa-11.2.1/lib/libOSMesa.so \
  -DPARAVIEW_USE_MPI=ON \
  /usr/local/paraview
 
RUN make -j16
RUN make -j16 install

# follow instructions in https://github.com/docker/docker/issues/5663
RUN sed -ri 's/^session\s+required\s+pam_loginuid.so$/session optional pam_loginuid.so/' /etc/pam.d/sshd

# create a vpic user
RUN groupadd -r vpic && useradd -r -m -g vpic vpic

# setup ssh keys and config
COPY id_rsa /home/vpic/.ssh/
COPY id_rsa.pub /home/vpic/.ssh/
COPY config /home/vpic/.ssh/
RUN chown -R vpic:vpic /home/vpic/.ssh; chmod 0700 /home/vpic/.ssh; chmod 0600 /home/vpic/.ssh/*
RUN sed -i 's/Port 22/Port 9222/' /etc/ssh/sshd_config

# add no password login
RUN cat /home/vpic/.ssh/id_rsa.pub >> /home/vpic/.ssh/authorized_keys

RUN chown -R vpic:vpic /home/vpic


# get more recent cmake as required for vpic
RUN mkdir /usr/local/cmake-3
WORKDIR /usr/local/cmake-3
RUN wget  https://cmake.org/files/v3.5/cmake-3.5.2-Linux-x86_64.tar.gz
RUN tar -xzf cmake-3.5.2-Linux-x86_64.tar.gz
ENV PATH /usr/local/cmake-3/cmake-3.5.2-Linux-x86_64/bin:$PATH


USER vpic
WORKDIR /home/vpic

#RUN git clone --recursive https://github.com/losalamos/vpic.git
RUN git clone https://github.com/demarle/vpic.git
WORKDIR /home/vpic/vpic
RUN git checkout -b dockerify origin/dockerify
RUN git submodule init
RUN git submodule update

# RBTODO move this to runvpic.sh
#RUN mkdir /home/vpic/vpic.bin
#WORKDIR /home/vpic/vpic.bin
#RUN cmake \
#  -DUSE_CATALYST=ON \
#  -DCMAKE_BUILD_TYPE=Release \
#  /home/vpic/vpic
#RUN make -j16

# add the launcher scripts for the docker file
ADD launch.sh /home/vpic
ADD launch_sshd.sh /home/vpic
ADD runvpic.sh /home/vpic
ADD machinefile /home/vpic

WORKDIR /home/vpic

USER root
