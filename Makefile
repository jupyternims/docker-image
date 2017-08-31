.PHONY: all release

TAG?=cf6258237ff9
REPO:=jupyternims/docker-image

all: release

refresh:
	-docker pull $(REPO):latest

build:
	sed -i '/^FROM/c\FROM jupyter\/datascience-notebook:$(TAG)' Dockerfile
	docker build --force-rm -t $(REPO):latest .

tag:
	docker tag $(REPO):latest $(REPO):$(TAG)

push:
	docker push $(REPO):latest
	docker push $(REPO):$(TAG)

release: refresh build tag push
