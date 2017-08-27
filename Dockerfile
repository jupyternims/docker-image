
# Docker demo image, as used on try.jupyter.org and tmpnb.org

FROM jupyter/datascience-notebook:c8797824e8c0

MAINTAINER Byung Chun Kim <wizardbc@gmail.com>

USER root

#RUN sed -i 's%archive.ubuntu.com%ftp.daumkakao.com%' /etc/apt/sources.list

RUN apt-get update \
 && apt-get -y dist-upgrade --no-install-recommends \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# git:// blocked by firewall, use https://
USER $NB_USER
RUN git config --global url."https://".insteadOf git://

# From jupyter/docker-demo-images
# Install system libraries first as root
USER root

# The Glorious Glasgow Haskell Compiler
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository -y ppa:hvr/ghc && \
    sed -i s/jessie/trusty/g /etc/apt/sources.list.d/hvr-ghc-jessie.list && \
    apt-get update && \
    apt-get install -y cabal-install-1.22 ghc-7.8.4 happy-1.19.4 alex-3.1.3 && \
    apt-get clean

# IHaskell dependencies
RUN apt-get install -y --no-install-recommends zlib1g-dev libzmq3-dev libtinfo-dev libcairo2-dev libpango1.0-dev && apt-get clean

# Ruby dependencies
RUN apt-get install -y --no-install-recommends ruby ruby-dev libtool autoconf automake gnuplot-nox libsqlite3-dev libatlas-base-dev libgsl0-dev libmagick++-dev imagemagick && \
    ln -s /usr/bin/libtoolize /usr/bin/libtool && \
    apt-get clean
# We need to pin activemodel to 4.2 while we have ruby < 2.2
RUN gem update --system --no-document && \
    gem install --no-document 'activemodel:~> 4.2' sciruby-full

# Now switch to $NB_USER for all conda and other package manager installs
USER $NB_USER

ENV PATH /home/$NB_USER/.cabal/bin:/opt/cabal/1.22/bin:/opt/ghc/7.8.4/bin:/opt/happy/1.19.4/bin:/opt/alex/3.1.3/bin:$PATH

# IRuby
RUN iruby register

# IHaskell + IHaskell-Widgets + Dependencies for examples
RUN cabal update && \
    CURL_CA_BUNDLE='/etc/ssl/certs/ca-certificates.crt' curl 'https://www.stackage.org/lts-2.22/cabal.config?global=true' >> ~/.cabal/config && \
    cabal install cpphs && \
    cabal install gtk2hs-buildtools && \
    cabal install ihaskell-0.8.4.0 --reorder-goals && \
    cabal install \
        # ihaskell-widgets-0.2.3.1 \ temporarily disabled because installation fails
        HTTP Chart Chart-cairo && \
    ihaskell install && \
    rm -fr $(echo ~/.cabal/bin/* | grep -iv ihaskell) ~/.cabal/packages ~/.cabal/share/doc ~/.cabal/setup-exe-cache ~/.cabal/logs

# Extra Kernels
# Tensorflow
RUN conda install --quiet --yes -c conda-forge tensorflow
RUN conda install --quiet --yes -c conda-forge jupyter_contrib_nbextensions
# C
RUN pip install --user --no-cache-dir jupyter-c-kernel && \
    ~/.local/bin/install_c_kernel --user
RUN wget -O - https://raw.githubusercontent.com/brendan-rius/jupyter-c-kernel/master/install.sh | sh
# Octave Kernel
# From arnau/docker-octave-notebook
USER root
RUN apt-get update \
 && apt-get install -y octave liboctave-dev \
 && apt-get autoclean \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER $NB_USER

#jupyter nbextension enable --py --sys-prefix widgetsnbextension
RUN pip install octave_kernel \
 && python -m octave_kernel.install \
 && conda install -y ipywidgets


### Install Sage

USER root
ENV SAGE_VER 8.0
ENV SAGE_BIN_FILE sage-$SAGE_VER-Ubuntu_16.04-x86_64.tar.bz2
ENV SAGE_ROOT /opt/sage/$SAGE_VER
RUN mkdir -p $SAGE_ROOT && chown $NB_USER:users $SAGE_ROOT
RUN apt-get update \
 && apt-get install -y --no-install-recommends bsdtar \
 && apt-get autoclean \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER $NB_USER
WORKDIR $SAGE_ROOT
RUN wget -nv http://mirrors.mit.edu/sage/linux/64bit/$SAGE_BIN_FILE
RUN bsdtar -xjf $SAGE_BIN_FILE --strip-components=1
RUN rm $SAGE_BIN_FILE

USER root
RUN ln -sf $SAGE_ROOT/sage /usr/bin/sage &&\
    ln -sf $SAGE_ROOT/sage /usr/bin/sagemath

ADD ./add_sage/post.py $SAGE_ROOT/post.py
RUN sudo -H -u $NB_USER sage post.py && \
    rm post.py
WORKDIR /usr/local/share/jupyter/kernels/
RUN ln -s  $SAGE_ROOT/local/share/jupyter/kernels/sagemath/ ./

USER $NB_USER
WORKDIR /home/$NB_USER/work
RUN ln -s $SAGE_ROOT/local/share/jsmol /opt/conda/lib/python3.6/site-packages/notebook/static/
ADD ./add_sage/backend_ipython.py $SAGE_ROOT/local/lib/python2.7/site-packages/sage/repl/rich_output/backend_ipython.py

# JupyterLab
RUN conda remove --quiet --yes --force 'jupyterlab'
RUN conda install --quiet --yes -c conda-forge jupyterlab && conda clean -tipsy

# Append tmpnb specific options to the base config
COPY resources/jupyter_notebook_config.partial.py /tmp/
RUN cat /tmp/jupyter_notebook_config.partial.py >> /home/$NB_USER/.jupyter/jupyter_notebook_config.py && \
    rm /tmp/jupyter_notebook_config.partial.py
