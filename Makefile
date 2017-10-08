.PHONY: all release

TAG?=281505737f8a
REPO:=jupyternims/docker-image

all: refresh build push

refresh:
	-docker pull $(REPO):latest

build: refresh
	sed -i '/^FROM/c\FROM jupyter\/datascience-notebook:$(TAG)' Dockerfile
	docker build --force-rm -t $(REPO):latest .

dev: build
	docker run --rm -it -p 8888:8888 jupyternims/docker-image:latest

tag: build
	docker tag $(REPO):latest $(REPO):$(TAG)

push: tag
	docker push $(REPO):latest
	docker push $(REPO):$(TAG)

git_push: push
	git add .
	git commit -m 'bump to $(TAG)'
	git push
