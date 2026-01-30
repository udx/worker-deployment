IMAGE_NAME ?= usabilitydynamics/udx-worker-child:latest

.PHONY: build run shell

build:
	docker build -t $(IMAGE_NAME) .

run:
	docker run --rm -it $(IMAGE_NAME)

shell:
	docker run --rm -it $(IMAGE_NAME) /bin/bash
