# Docker demo image, as used on try.jupyter.org and tmpnb.org

FROM jupyter/datascience-notebook:8f56e3c47fec
#FROM jupyter/all-spark-notebook:8e15d329f1e9

MAINTAINER Byung Chun Kim <wizardbc@gmail.com>

USER root

RUN sed -i 's%archive.ubuntu.com%ftp.daumkakao.com%' /etc/apt/sources.list

RUN apt-get update \
 && apt-get -y dist-upgrade --no-install-recommends \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# git:// blocked by firewall, use https://
USER $NB_USER
RUN git config --global url."https://".insteadOf git://

# Install system libraries first as root
USER root

# !!! Haskell does not work !!!
# The Glorious Glasgow Haskell Compiler
#RUN apt-get update && \
#    apt-get install -y --no-install-recommends software-properties-common && \
#    add-apt-repository -y ppa:hvr/ghc && \
#    sed -i s/jessie/trusty/g /etc/apt/sources.list.d/hvr-ghc-jessie.list && \
#    apt-get update && \
#    apt-get install -y cabal-install-1.22 ghc-7.8.4 happy-1.19.4 alex-3.1.3 && \
#    apt-get clean

# IHaskell dependencies
RUN apt-get update
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

# !!! Haskell does not work !!!
#ENV PATH /home/$NB_USER/.cabal/bin:/opt/cabal/1.22/bin:/opt/ghc/7.8.4/bin:/opt/happy/1.19.4/bin:/opt/alex/3.1.3/bin:$PATH

# IRuby
RUN iruby register

# !!! Haskell does not work !!!
# IHaskell + IHaskell-Widgets + Dependencies for examples
#RUN cabal update && \
#    CURL_CA_BUNDLE='/etc/ssl/certs/ca-certificates.crt' curl 'https://www.stackage.org/lts-2.22/cabal.config?global=true' >> ~/.cabal/config && \
#    cabal install cpphs && \
#    cabal install gtk2hs-buildtools && \
#    cabal install ihaskell-0.8.0.0 --reorder-goals && \
#    cabal install ihaskell-widgets-0.2.2.1 HTTP Chart Chart-cairo && \
#    ihaskell install && \
#    rm -fr $(echo ~/.cabal/bin/* | grep -iv ihaskell) ~/.cabal/packages ~/.cabal/share/doc ~/.cabal/setup-exe-cache ~/.cabal/logs

# Extra Kernels
# Bash
#RUN pip install --user --no-cache-dir bash_kernel && \
#    python -m bash_kernel.install
# Tensorflow
RUN conda install --quiet --yes -c conda-forge tensorflow
#RUN conda install --quiet --yes -n python2 -c conda-forge tensorflow
RUN conda install --quiet --yes -c conda-forge jupyter_contrib_nbextensions
# C
USER root
RUN wget -O - https://raw.githubusercontent.com/brendan-rius/jupyter-c-kernel/master/install.sh | sh
# Octave Kernel
# From arnau/docker-octave-notebook

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


# !!! Haskell does not work !!!
#RUN git clone --depth 1 https://github.com/gibiansky/IHaskell.git /home/$NB_USER/work/IHaskell/ && \
#    mv /home/$NB_USER/work/IHaskell/ihaskell-display/ihaskell-widgets/Examples /home/$NB_USER/work/featured/ihaskell-widgets && \
#    rm -r /home/$NB_USER/work/IHaskell



### Install Sage

USER root
ENV SAGE_VER 8.0
ENV SAGE_BIN_FILE sage-$SAGE_VER-Debian_GNU_Linux_8-x86_64.tar.bz2
ENV SAGE_ROOT /opt/sage/$SAGE_VER
RUN mkdir -p $SAGE_ROOT && chown $NB_USER:users $SAGE_ROOT

USER $NB_USER
WORKDIR $SAGE_ROOT
RUN wget -nv https://mirrors.tuna.tsinghua.edu.cn/sagemath/linux/64bit/$SAGE_BIN_FILE && \
    tar -xjvf $SAGE_BIN_FILE --strip-components=1 && \
    rm $SAGE_BIN_FILE

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


USER root
# Clone featured notebooks before adding local content to avoid recloning
# everytime something changes locally
RUN mkdir -p /home/$NB_USER/work/communities && \
    mkdir -p /home/$NB_USER/work/featured
RUN git clone --depth 1 https://github.com/jvns/pandas-cookbook.git /home/$NB_USER/work/featured/pandas-cookbook/

# Add local content, starting with notebooks and datasets which are the largest
# so that later, smaller file changes do not cause a complete recopy during 
# build
COPY notebooks/ /home/$NB_USER/work/
COPY datasets/ /home/$NB_USER/work/datasets/

# Switch back to root for permission fixes, conversions, and trust. Make sure
# trust is done as $NB_USER so that the signing secret winds up in the $NB_USER
# profile, not root's
USER root

# Convert notebooks to the current format and trust them
RUN find /home/$NB_USER/work -name '*.ipynb' -exec jupyter nbconvert --to notebook {} --output {} \; && \
    chown -R $NB_USER:users /home/$NB_USER && \
    sudo -u $NB_USER env "PATH=$PATH" find /home/$NB_USER/work -name '*.ipynb' -exec jupyter trust {} \;


# JupyterLab
RUN conda remove --quiet --yes --force 'jupyterlab'
RUN conda install --quiet --yes -c conda-forge jupyterlab && conda clean -tipsy

# Finally, add the site specific tmpnb.org / try.jupyter.org configuration.
# These should probably be split off into a separate docker image so that others
# can reuse the very expensive build of all the above with their own site 
# customization.

# Install our custom.js
#COPY resources/custom.js /home/$NB_USER/.jupyter/custom/

# Add the templates
COPY resources/templates/ /srv/templates/
RUN chmod a+rX /srv/templates && \
    chown -R $NB_USER:users /srv/templates

# Append tmpnb specific options to the base config
COPY resources/jupyter_notebook_config.partial.py /tmp/
RUN cat /tmp/jupyter_notebook_config.partial.py >> /home/$NB_USER/.jupyter/jupyter_notebook_config.py && \
    rm /tmp/jupyter_notebook_config.partial.py

RUN cp -R /home/$NB_USER/work /srv/work
COPY docker-entrypoint.sh /srv/docker-entrypoint.sh
ENTRYPOINT ["tini", "--", "/srv/docker-entrypoint.sh"]
CMD ["start-notebook.sh"]

USER $NB_USER
