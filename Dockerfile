
# Docker demo image, as used on try.jupyter.org and tmpnb.org

FROM jupyter/datascience-notebook:cf6258237ff9

MAINTAINER Byung Chun Kim <wizardbc@gmail.com>

USER root

RUN sed -i 's%archive.ubuntu.com%ftp.daumkakao.com%' /etc/apt/sources.list

# If git:// blocked by firewall, use https://
#RUN git config --global url."https://".insteadOf git://
#USER $NB_USER
#RUN git config --global url."https://".insteadOf git://

# IRuby
# From odk211/iruby-notebook
USER root

# install iruby https://github.com/SciRuby/iruby
RUN apt-get update -qq && \
    apt-get install -y \
    libtool libffi-dev make automake \
    libssl-dev libreadline-dev zlib1g-dev \
    git libzmq-dev autoconf pkg-config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/zeromq/czmq --depth 1 && \
    cd czmq && \
    ./autogen.sh && ./configure && make && make install && \
    cd .. && \
    rm -rf ./czmq

# install ruby-build, ruby
RUN git clone https://github.com/rbenv/ruby-build.git --depth 1 && \
    cd ruby-build && \
    ./install.sh && \
    cd .. && \
    rm -rf ./ruby-build

ENV RUBY_VERSION=2.4.1 \
    RUBY_DIR=/opt/ruby

ENV PATH=$RUBY_DIR/bin:$PATH

RUN mkdir -p $RUBY_DIR && \
    chown $NB_USER $RUBY_DIR

USER $NB_USER

RUN ruby-build $RUBY_VERSION $RUBY_DIR

RUN gem install bundler cztop iruby pry pry-doc awesome_print gnuplot rubyvis nyaplot --no-document && \
    iruby register --force

# brendan-rius/jupyter-c-kernel
RUN mkdir -p /home/$NB_USER/.local/
WORKDIR /home/$NB_USER/.local/
RUN git clone https://github.com/brendan-rius/jupyter-c-kernel.git && \
    mv jupyter-c-kernel/ jupyter_c_kernel/ && \
    pip install --no-cache-dir -e jupyter_c_kernel/ && \
    cd jupyter_c_kernel && install_c_kernel --user
WORKDIR /home/$NB_USER/

# Tensorflow
RUN conda install --quiet --yes -c conda-forge tensorflow
RUN conda install --quiet --yes -c conda-forge jupyter_contrib_nbextensions

# Octave Kernel
# From arnau/docker-octave-notebook
USER root
RUN apt-get update -qq && \
    apt-get install -y octave liboctave-dev && \
    apt-get autoclean && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER $NB_USER

#jupyter nbextension enable --py --sys-prefix widgetsnbextension
RUN pip install octave_kernel && \
    python -m octave_kernel.install && \
    conda install -y ipywidgets


### Install Sage

USER root
ENV SAGE_VER 8.0
ENV SAGE_BIN_FILE sage-$SAGE_VER-Ubuntu_16.04-x86_64.tar.bz2
ENV SAGE_ROOT /opt/sage/$SAGE_VER
RUN mkdir -p $SAGE_ROOT && chown $NB_USER:users $SAGE_ROOT
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends bsdtar && \
    apt-get autoclean && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER $NB_USER
WORKDIR $SAGE_ROOT
RUN wget -nv https://mirrors.tuna.tsinghua.edu.cn/sagemath/linux/64bit/$SAGE_BIN_FILE && \
    bsdtar -xjf $SAGE_BIN_FILE --strip-components=1 && \
    rm $SAGE_BIN_FILE

USER root
RUN ln -sf $SAGE_ROOT/sage /usr/bin/sage && \
    ln -sf $SAGE_ROOT/sage /usr/bin/sagemath

ADD ./add_sage/post.py $SAGE_ROOT/post.py
RUN sudo -H -u $NB_USER sage post.py && \
    rm post.py
WORKDIR /usr/local/share/jupyter/kernels/
RUN ln -s  $SAGE_ROOT/local/share/jupyter/kernels/sagemath/ ./

USER $NB_USER
WORKDIR /home/$NB_USER/work/
RUN ln -s $SAGE_ROOT/local/share/jsmol /opt/conda/lib/python3.6/site-packages/notebook/static/
ADD ./add_sage/backend_ipython.py $SAGE_ROOT/local/lib/python2.7/site-packages/sage/repl/rich_output/backend_ipython.py
