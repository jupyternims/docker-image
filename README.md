# Docker image for [jupyter.nims.re.kr](https://jupyter.nims.re.kr).

This image is a modification of [jupyter/docker-demo-images](https://github.com/jupyter/docker-demo-images) and based on [jupyter/docker-stacks](https://github.com/jupyter/docker-stacks)'s `datascience-notebook`.

This project is supported by [NIMS](https://www.nims.re.kr).

## What it Gives You

* Everything in [Data Science Notebook](https://github.com/jupyter/docker-stacks/tree/master/datascience-notebook)
* IRuby (from [odk211/iruby-notebook](https://hub.docker.com/r/odk211/iruby-notebook/))
* Tensorflow (without GPU support)
* Octave kernel
* [SageMath](http://www.sagemath.org)
* JupyterLab

**Python 2.x was removed** from all [jupyter/docker-stacks](https://github.com/jupyter/docker-stacks) images on August 10th, 2017.

## Basic Use

The following command starts a container with the Notebook server listening for HTTP connections on port 8888 with a randomly generated authentication token configured.

```
docker run -it --rm -p 8888:8888 jupyternims/docker-image
```

Take note of the authentication token included in the notebook startup log messages. Include it in the URL you visit to access the Notebook server or enter it in the Notebook login form.

You can find more options at [Data Science Notebook](https://github.com/jupyter/docker-stacks/tree/master/datascience-notebook).

# [jupyter.nims.re.kr](https://jupyter.nims.re.kr)

[jupyter.nims.re.kr](https://jupyter.nims.re.kr) is hosted by [NIMS](https://www.nims.re.kr).

## Start and Stop

If you start your server, you will get a container with jupyter notebook.

If you stop your server, your container will be destroyed and all data outside of `~/work` folder will be lost.

So, if something is wrong, just stop and restart your notebook server in `Control Panel`.

## Notice of Shutdown

[jupyter.nims.re.kr](https://jupyter.nims.re.kr) will reboot regularly once a week (1:00am to 4:00am on Monday) for package management.

At this point, all user calculations are stopped and all environments are initialized.

In particular, the data of users outside the `~/work` folder will be lost.
