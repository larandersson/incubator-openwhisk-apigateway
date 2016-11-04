DOCKER_TAG ?= snapshot-`date +'%Y%m%d-%H%M'`
DOCKER_REGISTRY ?= ''

docker:
	docker build -t apicgw/apigateway .

.PHONY: docker-ssh
docker-ssh:
	docker run -ti --entrypoint='bash' apicgw/apigateway:latest

.PHONY: test-build
test-build:
	cd api-gateway-config/tests; ./install-deps.sh

.PHONY: test-run
test-run:
	cd api-gateway-config/tests; ./run-tests.sh

.PHONY: docker-run
docker-run:
	docker run --rm --name="apigateway" -p 80:80 -p 5000:5000 apicgw/apigateway:latest ${DOCKER_ARGS}

.PHONY: docker-run-mgmt
docker-run-mgmt:
	docker run --rm --name="apigateway" -p 80:80 -p 8080:8080 -p 9000:9000 \
		-e REDIS_HOST=${REDIS_HOST} -e REDIS_PORT=${REDIS_PORT} -e REDIS_PASS=${REDIS_PASS} \
		apicgw/apigateway:latest

.PHONY: docker-debug
docker-debug:
	#Volumes directories must be under your Users directory
	mkdir -p ${HOME}/tmp/apiplatform/apigateway
	rm -rf ${HOME}/tmp/apiplatform/apigateway/api-gateway-config
	cp -r `pwd`/api-gateway-config ${HOME}/tmp/apiplatform/apigateway/
	docker run --name="apigateway" \
			-p 80:80 -p 5000:5000 \
			-e "LOG_LEVEL=info" -e "DEBUG=true" \
			-v ${HOME}/tmp/apiplatform/apigateway/api-gateway-config/:/etc/api-gateway \
			apicgw/apigateway:latest ${DOCKER_ARGS}

.PHONY: docker-reload
docker-reload:
	cp -r `pwd`/api-gateway-config ${HOME}/tmp/apiplatform/apigateway/
	docker exec apigateway api-gateway -t -p /usr/local/api-gateway/ -c /etc/api-gateway/api-gateway.conf
	docker exec apigateway api-gateway -s reload

.PHONY: docker-attach
docker-attach:
	docker exec -i -t apigateway bash

.PHONY: docker-stop
docker-stop:
	docker stop apigateway
	docker rm apigateway

.PHONY: docker-push
docker-push:
	docker tag -f apicgw/apigateway $(DOCKER_REGISTRY)/apicgw/apigateway:$(DOCKER_TAG)
	docker push $(DOCKER_REGISTRY)/apicgw/apigateway:$(DOCKER_TAG)

