.PHONY: all release

TAG?=c64b1e33ae52
REPO:=jupyternims/docker-image

all: release

refresh:
	-docker pull $(REPO):latest

build:
	sed -i '/^FROM/c\FROM jupyter\/datascience-notebook:$(TAG)' Dockerfile
	docker build --force-rm -t $(REPO):latest .

dev: build
	docker run --rm -it -p 8888:8888 jupyternims/docker-image:latest

tag:
	docker tag $(REPO):latest $(REPO):$(TAG)

push: tag
	docker push $(REPO):latest
	docker push $(REPO):$(TAG)

release: refresh build push
