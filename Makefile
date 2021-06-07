MODULES  ?= $(shell ls services)
TOKEN 				?= $(shell curl -s -X POST "http://localhost:10080/rbac/users/login" -H "accept: */*" -H "Content-Type: application/json" -d "{\"email\":\"test@test.com\",\"password\":\"asdfasdf\"}" | jq -r '.token')
USERNAME 			?= $(shell whoami)
MODULES 			?= $(shell ls services)
PURPLE          	:= $(shell tput setaf 129)
GRAY            	:= $(shell tput setaf 245)
GREEN           	:= $(shell tput setaf 34)
BLUE            	:= $(shell tput setaf 25)
YELLOW          	:= $(shell tput setaf 3)
WHITE           	:= $(shell tput setaf 7)
RESET           	:= $(shell tput sgr0)
BASE_PATH			= $(shell pwd)
COMPOSE_IGNORE_ORPHANS=True

# mlfabric frankfurk es box
ELASTICSEARCH_LOGGER_HOST	?= http://22.11.166.157:9200
ELASTICSEARCH_CACHE_HOST	?= http://internal-mlfabric-camv2-prod-eu-1-es-325321758.eu-central-1.elb.amazonaws.com:9200

# mlfabric frankfurt
KUBE_BASE_URI		?= 881029454603.dkr.ecr.eu-central-1.amazonaws.com

LOG_LEVEL ?= DEBUG
export

.PHONY: help h conda/install
.DEFAULT_GOAL := help


login:
	curl -X POST "https://api.streaming-platform.com/rbac/users/login" -H  "accept: */*" -H  "Content-Type: application/json" -d "{\"email\":\"test@test.com\",\"password\":\"Agby5kma0130\"}" | jq -r .token | pbcopy

#
# This will expand to multiple targets (being that of each directory in services/) and
# execute them in parallel based on $NPROCS.
#
## Get deployment status of all services.
k8/deployment/status:

	@for F in $(MODULES_TO_COMPOSE); do echo "$(PURPLE)Getting deployment status for $$F$(RESET)"; kubectl get deployment -lapp=$$F; echo; done

k8/deployment/install: guard-MODULE

	@$(MAKE) -C services/$$MODULE install

k8/deployment/install/all:

#	@for F in $(MODULES_TO_COMPOSE); do $(MAKE) -C services/$$F install; done
	for F in $(MODULES_TO_COMPOSE); do \
		make -C services/$$F install & \
	done; \
	wait

k8/deployment/delete: guard-MODULE

	@$(MAKE) -C services/$$MODULE delete

k8/deployment/delete/all:

#	@for F in $(MODULES_TO_COMPOSE); do echo "$(GREEN)Deleting deployment for $$F$(RESET)"; $(MAKE) -C services/$$F delete &; wait; done
	for F in $(MODULES_TO_COMPOSE); do \
		make -C services/$$F delete & \
	done; \
	wait

k8/deployment/scale/all: guard-REPLICAS

	@for F in $(MODULES_TO_COMPOSE); do echo "$(GREEN)Scaling deployment $$F to $$REPLICAS replicas..$(RESET)"; kubectl scale --replicas $$REPLICAS deployment $$F; done

k8/images/build: guard-MODULE

	@$(MAKE) -C services/$$MODULE build

k8/images/build/all:

	@for F in $(MODULES_TO_COMPOSE); do $(MAKE) -C services/$$F build; done

k8/images/push: guard-MODULE

	@$$(aws ecr get-login --no-include-email)

	@$(MAKE) -C services/$$MODULE push

k8/images/push/all:

	@$$(aws ecr get-login --no-include-email)

	@for F in $(MODULES_TO_COMPOSE); do $(MAKE) -C services/$$F push; done

aws/ecr/create-repos:

	@for F in $(MODULES_TO_COMPOSE); do aws ecr create-repository --repository-name=camv2/$$F; done

aws/ecr/put-lifecycle-policies:

	@for F in $(MODULES_TO_COMPOSE); do aws ecr put-lifecycle-policy --repository-name=camv2/$$F --lifecycle-policy-text "file://infra/aws-ecr-lifecycle-policy.json"; done

header:

	@echo "${PURPLE}"
	@cat docs/banner-maaml.txt
	@echo "${RESET}${GRAY}"
	@cat docs/banner-camv2.txt
	@echo "${RESET}"

help:: header

#		@docker run --rm -v $(PWD)/docs:/sandbox -w /sandbox -it rawkode/mdv:latest quickstart.md

		@echo Tools:
		@echo
		@awk '/^[a-zA-Z\/\-\_0-9]+:/ { \
				helpMessage = match(lastLine, /^## (.*)/); \
				if (helpMessage) { \
						helpCommand = substr($$1, 0, index($$1, ":")-1); \
						helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
						printf "  ${GREEN}%-31s${RESET} ${GRAY}%s${RESET}\n", helpCommand, helpMessage; \
				} \
		} \
		{ lastLine = $$0 }' $(MAKEFILE_LIST)
		@echo
		@echo Specific Targets:
		@echo
		@awk '/^[a-zA-Z\/\-\_0-9]+:/ { \
				helpMessage = match(lastLine, /^### (.*)/); \
				if (helpMessage) { \
						helpCommand = substr($$1, 0, index($$1, ":")-1); \
						helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
						printf "  ${GREEN}%-30s${RESET} ${GRAY}%s${RESET}\n", helpCommand, helpMessage; \
				} \
		} \
		{ lastLine = $$0 }' $(MAKEFILE_LIST)
		@echo
		@echo "  $(PURPLE)Create a new conda environment for the monorepo with $(GRAY)make conda/setup$(RESET)"
		@[ -f $$PWD/.conda ] || echo "  $(PURPLE)Activate conda with: $(GRAY)source $$PWD/.conda/bin/activate$(RESET)" || true;
		@echo

guard-%:
		@ if [ "${${*}}" = "" ]; then \
				echo "$(YELLOW)Environment variable $* not set (make $*=.. target or export $*=..$(RESET)"; \
				exit 1; \
		fi

## Output service information.
info: header

	@$(eval IP=$(shell curl -s http://api.ipify.org))

	@echo
	@echo "My Public IP: $(PURPLE)$$IP$(RESET)"
	@echo
	@echo "$(PURPLE)Web URLs$(RESET):"
	@echo
	@printf "  + $(YELLOW)%-30s$(RESET): $(BLUE)%-20s$(RESET)" "Search UI" http://$$IP:$(shell docker inspect $(USERNAME)-maa-ml-camv2-api-search-entrypoint | jq -r '.[0].NetworkSettings.Ports."80/tcp"[0].HostPort')/swagger
	@echo
	@printf "  + $(YELLOW)%-30s$(RESET): $(BLUE)%-20s$(RESET)" "Translation UI" http://$$IP:$(shell docker inspect $(USERNAME)-maa-ml-camv2-api-translation | jq -r '.[0].NetworkSettings.Ports."80/tcp"[0].HostPort')/swagger
	@echo
	@printf "  + $(YELLOW)%-30s$(RESET): $(BLUE)%-20s$(RESET)" "Chronograf (metrics) UI" http://$$IP:$(shell docker inspect $(USERNAME)-camv2-infra-chronograf | jq -r '.[0].NetworkSettings.Ports."8888/tcp"[0].HostPort')
	@echo
	@printf "  + $(YELLOW)%-30s$(RESET): $(BLUE)%-20s$(RESET)" "Kibana UI" http://$$IP:$(shell docker inspect $(USERNAME)-camv2-infra-kibana | jq -r '.[0].NetworkSettings.Ports."5601/tcp"[0].HostPort')
	@echo
	@printf "  + $(YELLOW)%-30s$(RESET): $(BLUE)%-20s$(RESET)" "RabbitMQ UI" http://$$IP:$(shell docker inspect $(USERNAME)-camv2-infra-rabbitmq | jq -r '.[0].NetworkSettings.Ports."15672/tcp"[0].HostPort')
	@echo
	@echo
	@echo "$(PURPLE)Infrastructure Service Ports$(RESET):"
	@echo
	@printf "  + $(YELLOW)%-30s$(RESET): ${GREEN}%s${RESET}\n" "Chronograf (metrics) Port (UI)" $(shell docker inspect $(USERNAME)-camv2-infra-chronograf | jq -r '.[0].NetworkSettings.Ports."8888/tcp"[0].HostPort')
	@printf "  + $(YELLOW)%-30s$(RESET): ${GREEN}%s${RESET}\n" "Elasticsearch Port (API)" $(shell docker inspect $(USERNAME)-camv2-infra-elasticsearch | jq -r '.[0].NetworkSettings.Ports."9200/tcp"[0].HostPort')
	@printf "  + $(YELLOW)%-30s$(RESET): ${GREEN}%s${RESET}\n" "InfluxDB (metrics) Port (API)" $(shell docker inspect $(USERNAME)-camv2-infra-influxdb | jq -r '.[0].NetworkSettings.Ports."8086/tcp"[0].HostPort')
	@printf "  + $(YELLOW)%-30s$(RESET): ${GREEN}%s${RESET}\n" "Kibana Port (WEB UI)" $(shell docker inspect $(USERNAME)-camv2-infra-kibana | jq -r '.[0].NetworkSettings.Ports."5601/tcp"[0].HostPort')
	@printf "  + $(YELLOW)%-30s$(RESET): ${GREEN}%s${RESET} ${GRAY}mysql -h127.0.0.1 -P$(shell docker inspect $(USERNAME)-camv2-infra-mysql | jq -r '.[0].NetworkSettings.Ports."3306/tcp"[0].HostPort') -uroot -pmysql camv2${RESET}\n" "MySQL Port" $(shell docker inspect $(USERNAME)-camv2-infra-mysql | jq -r '.[0].NetworkSettings.Ports."3306/tcp"[0].HostPort')
	@printf "  + $(YELLOW)%-30s$(RESET): ${GREEN}%s${RESET}\n" "RabbitMQ Port (AMQP)" $(shell docker inspect $(USERNAME)-camv2-infra-rabbitmq | jq -r '.[0].NetworkSettings.Ports."5672/tcp"[0].HostPort')
	@printf "  + $(YELLOW)%-30s$(RESET): ${GREEN}%s${RESET}\n" "RabbitMQ Port (WEB UI)" $(shell docker inspect $(USERNAME)-camv2-infra-rabbitmq | jq -r '.[0].NetworkSettings.Ports."15672/tcp"[0].HostPort')
	@echo

## Grab a shell in a running docker container matching the pattern.
exec/%:

	@echo
	@echo "$(PURPLE)Grabbing shell in $(GREEN)$(shell docker ps | egrep "$$USERNAME.*?${*}" | awk -F ' ' '{print $$1}' | head -n 1)$(RESET) ${*} .. enjoy!$(RESET)"
	@echo
	@echo " + Hostname: $(YELLOW) $(shell docker exec -it $(shell docker ps | egrep "$$USERNAME.*?${*}" | awk -F ' ' '{print $$1}' | head -n 1) hostname)$(RESET)"
	@echo
	@docker exec -it $(shell docker ps | egrep "$$USERNAME.*?${*}" | awk -F ' ' '{print $$1}' | head -n 1) sh

## Resets (and deletes all volumes, containers, networks)
reset:

	$(MAKE) stack/infra/delete || true
	$(MAKE) stack/modules/delete
	$(MAKE) stack/network/delete

	@for F in $(MODULES); do docker rm -f $$F; done

	$(MAKE) status

## Displays the current docker container statuses.
status:

	@echo "########################################################################################################################"
	@echo "$(BLUE)CURRENT CONTAINER STATUS:$(RESET)"
	@echo "----$(PURPLE)"
	@docker ps -a --format '{{.Names}};{{.Status}};{{.Ports}}' | grep "mc" | column -s";" -t
	@echo "$(RESET)----"
	@echo "$(GREEN)$(shell docker ps -a | grep mc | wc -l) TOTAL $(RESET)/$(YELLOW)$(shell docker ps -a | grep mc | grep Up | wc -l) UP$(RESET)"
	@echo "########################################################################################################################"

### View the compiled docker-compose.yaml files for all modules.
config/composes/view:

	@for F in $(MODULES_TO_COMPOSE); do echo "------------------------------------------------"; echo "$$F:"; echo; MODULE=services/$$F MODULE_NAME=$$USERNAME-$$F envsubst < services/$$F/docker-compose.yaml; echo "------------------------------------------------"; done

### Create a new branch across all modules (make git/branch BRANCH=awesome-branch).
git/branch/new: guard-BRANCH

	@git checkout -b $$BRANCH
	@for F in $(MODULES); do echo "$(GREEN)Creating new branch in $(RESET)$(PURPLE)$$F$(RESET) on branch $(GREEN)$(BRANCH)$(RESET)"; cd $(PWD)/services/$$F && git checkout -b $(BRANCH) && git pull && git branch --set-upstream-to=origin/$(BRANCH) $(BRANCH) && git status; echo; done

### Generates CHANGELOG.md for all modules.
git/changelog/generate:

#	@echo "$(GREEN)Creating/updating $(GRAY)CHANGELOG.md$(RESET) in $(RESET)$(PURPLE)monorepo$(RESET)" && conventional-changelog -i CHANGELOG.md -s
#	@for F in $(MODULES); do echo "$(GREEN)Creating/updating $(GRAY)CHANGELOG.md$(RESET) in $(RESET)$(PURPLE)$$F$(RESET)" && cd $(PWD)/services/$$F && conventional-changelog -i CHANGELOG.md -s; done

### Checkout an EXISTING branch (make git/branch/checkout BRANCH=master).
git/branch/checkout: guard-BRANCH

	@echo "Checking out $(PURPLE)$$BRANCH$(RESET) in $(PURPLE)monorepo$(RESET).."
	@git checkout $(BRANCH)
	@git pull origin $(BRANCH)
	@for F in $(MODULES); do echo "$(PURPLE)Checking out $(PURPLE)$$BRANCH$(RESET) in $(GREEN)$$F$(RESET) .." && cd $(PWD)/services/$$F && git fetch && git checkout $$BRANCH && git status; done || true
	@$(MAKE) git/pull

### Commit and push all changes for module (make git/commit-and-push MODULE=some-module-name MESSAGE="my changes").
git/commit-and-push: guard-MODULE guard-BRANCH guard-MESSAGE

	@echo "$(GREEN)Committing $$MODULE ..$(RESET)" && cd $(PWD)/services/$$MODULE && git add . && git commit -am '$(MESSAGE)' && git push origin $(BRANCH); done || true
	@git commit -am '$(MESSAGE)' || true
	@git push || true

### Commit and push all changes for all submodules (make git/commit-and-push/all MESSAGE="my changes").
git/commit-and-push/all: guard-BRANCH

	@for F in $(MODULES); do echo "$(GREEN)Committing $$F ..$(RESET)" && cd $(PWD)/services/$$F && git add . && git commit -am '$(MESSAGE)' && git push origin $(BRANCH); done || true
	@git commit -am '$(MESSAGE)' || true
	@git push origin $(BRANCH) || true

### Bump version with an empty commit and push all changes for all submodules (make git/bump-and-push/all BRANCH=some-module-name).
git/bump-and-push/all: guard-BRANCH guard-MESSAGE

	@for F in $(MODULES); do echo "$(GREEN)Committing $$F ..$(RESET)" && cd $(PWD)/services/$$F && git add . || true; git commit -am'$(MESSAGE)' && git push origin $(BRANCH); done || true
	@git add . || true
	@git commit -am '$(MESSAGE)' || true
	@git push origin $(BRANCH) || true


### Bump to new version and push empty commit for module (make git/bump-and-push MODULE=some-module-name).
git/bump-and-push: guard-MODULE guard-BRANCH

	@echo "$(GREEN)Committing $$MODULE ..$(RESET)" && cd $(PWD)/services/$$MODULE && git commit --allow-empty -m 'bump version' && git push origin $(BRANCH);
	@git commit -am 'bump version' || true
	@git push || true

### Merge an EXISTING branch (make git/branch/merge BRANCH=master).
git/branch/merge: guard-BRANCH

	@echo "Merging $(PURPLE)$$BRANCH$(RESET) in $(PURPLE)monorepo$(RESET).."
	@git merge $(BRANCH)
	@for F in $(MODULES); do echo "$(PURPLE)Merging $(PURPLE)$$BRANCH$(RESET) in $(GREEN)$$F$(RESET) .." && cd $(PWD)/services/$$F && git merge $$BRANCH && git status; done || true

git/pull: guard-BRANCH

	@git submodule update --init
	@for F in $(MODULES); do echo "$(GREEN)Pullling in changes for $(RESET)$(PURPLE)$$F$(RESET) on branch $(GREEN)$(BRANCH)$(RESET)"; cd $(PWD)/services/$$F && git checkout $(BRANCH) && git pull origin $(BRANCH) && git status; echo; done

git/push:

	@for F in $(MODULES); do cd $(PWD)/services/$$F && git push origin HEAD:master; done
	@git push

### Performs a git reset --hard HEAD on all modules (beware).
git/reset:

	@echo "$(GREEN)Are you SURE you want to continue? [Y,n]$(RESET):"
	@read CONTINUE; [[ "$$CONTINUE" == "Y" ]] && for F in $(MODULES); do echo "$(GREEN)Resetting changes for $(RESET)$(PURPLE)$$F$(RESET)"; cd $(PWD)/services/$$F && git reset --hard HEAD; echo; done || exit 0

### Get the current status of all modules (make git/branch/show).
git/status:

	@for F in $(MODULES); do echo ---; echo; echo "$(GREEN)Checking status in $$F ..$(RESET)" && cd $(PWD)/services/$$F && git status; echo; echo "$(PURPLE)Pull request status:$(RESET)"; echo; done || true

### Update (pull) all modules from git. (make git/update BRANCH=somename)
git/update: guard-BRANCH

	@echo "$(GREEN)Pullling in changes for $(RESET)$(PURPLE)monorepo (itself)$(RESET)"; echo
	@git pull origin $(BRANCH)
	@git submodule update --init --recursive
	@git submodule foreach git checkout $(BRANCH)
	@git submodule foreach git pull origin $(BRANCH)
	@echo

### View link to see all pull requests for all modules.
github/pullrequests/link:

	@echo "$(PURPLE)View pull requests for all modules:$(RESET) $(GRAY)https://github.com/pulls?q=repo:moodysanalytics/maa-ml-camv2-monorepo+repo:moodysanalytics/$(subst $(eval) ,+repo:moodysanalytics/,$(MODULES))$(RESET)"

### View status of pull requests for all modules.
github/pullrequests/status:

	@echo "$(PURPLE)View pull requests for all modules:$(RESET) $(GRAY)$(RESET)"
	@for F in $(MODULES_TO_COMPOSE); do echo; echo "$(PURPLE)Checking for pull requests in $(GREEN)$$F$(RESET):"; echo "$(YELLOW)"; hub pr show; echo "$(RESET)"; done;

### Start infrastructure containers.
stack/infra/up: stack/network/create

	@echo "$(PURPLE)***************************************************************************************"
	@echo "***"
	@echo "*** STARTING ALL INFRASTRUCTURE SERVICES!"
	@echo "***"
	@echo "***************************************************************************************$(RESET)"

	@echo "+ Pre-Starting MySQL.."
	@envsubst < docker-compose.yaml | docker-compose -f - up -d mc-mysql
	@until docker exec mc-mysql mysql -u mysql -pmysql -e exit > /dev/null 2>&1; do echo "..waiting for MySQL.."; sleep 1; done

	docker-compose up -d
	cd infra/haproxy; docker-compose up -d --build

	@$(MAKE) status

### Stop all infra containers.
stack/infra/down:

	envsubst < docker-compose.yaml | docker-compose -f - down

### Delete all infra containers.
stack/infra/delete:

	@envsubst < docker-compose.yaml | docker-compose -f - down -v

### Restart infrastructure containers (rabbitmq, elasticsearch, etc..)
stack/infra/restart: stack/infra/down stack/infra/up

	@echo; echo "$(GREEN)Restarting infrastructure services..(RESET)"; echo;

### List container names.
stack/containers/list:

	@docker ps |grep camv2|awk -F ' ' '{print$11}'

### Run init.sh (if it exists) in a module directory.
stack/module/download: guard-MODULE

	@test -s services/$$MODULE/init.sh && echo "Running init.sh for $$MODULE" && cd services/$$MODULE && sh init.sh || true

### Rebuild and start a SINGLE service module.
stack/module/rebuild: guard-MODULE

	@echo; echo "$(GREEN)Rebuilding $$MODULE$(RESET)"; echo; cd services/$$MODULE; docker-compose up -d --build
	@$(MAKE) stack/module/down
	@$(MAKE) stack/module/up

### Stop a SINGLE service module.
stack/module/down: guard-MODULE

	@echo; echo "$(GREEN)Stopping $$MODULE$(RESET)"; echo; cd services/$$MODULE; docker-compose up -d

### Start a SINGLE service module.
stack/module/up: guard-MODULE

	@echo; echo "$(GREEN)Starting $$MODULE$(RESET)"; echo; cd services/$$MODULE; docker-compose up -d
	@$(MAKE) status

### Rebuild (with no-cache opt) and start a SINGLE service module.
stack/module/rebuild/nocache: guard-MODULE

	@echo; echo "$(GREEN)Rebuilding (no-cache) $$MODULE$(RESET)"; echo; make stack/module/download; MODULE_NAME=$$USERNAME-$$MODULE envsubst < services/$$MODULE/docker-compose.yaml | docker-compose -f - build --no-cache
	@$(MAKE) stack/module/down
	@$(MAKE) stack/module/up

### Copies env.orig to .env for all modules.
stack/modules/cpenv:

	@@for F in $(MODULES); do echo "$(GREEN)Copying env.orig to .env for $$F$(RESET)"; cd $(PWD)/services/$$F && cp env.orig .env; done

### Stop all service modules (does not include infra containers).
stack/modules/down:
	@for F in $(MODULES_TO_COMPOSE); do echo; echo "$(GREEN)Stopping$(RESET) Module: $(PURPLE)$$F$(RESET)"; echo; MODULE=services/$$F MODULE_NAME=$$USERNAME-$$F envsubst < services/$$F/docker-compose.yaml | docker-compose -f - down; done

### Delete all service module containers + volumes (does not include infra containers).
stack/modules/delete:

	@for F in $(MODULES_TO_COMPOSE); do echo; echo "$(GREEN)Deleting$(RESET) Module $(PURPLE)$$F$(RESET)"; echo; MODULE=services/$$F MODULE_NAME=$$USERNAME-$$F envsubst < services/$$F/docker-compose.yaml | docker-compose -f - rm -v; done

### Start all service modules (does not include infra containers).
stack/modules/up:

	@for F in $(MODULES_TO_COMPOSE); do echo; echo "$(GREEN)Starting$(RESET) $(PURPLE)$$F$(RESET)"; echo; MODULE=services/$$F MODULE_NAME=$$USERNAME-$$F envsubst < services/$$F/docker-compose.yaml | docker-compose -f - up -d; done

	@$(MAKE) status/self


### Rebuild (serially) and start all service modules.
stack/modules/rebuild/serial:

	@echo "$(GREEN)Checking for init.sh to call before building in each module...$(RESET)"
	@for F in $(MODULES_TO_COMPOSE); do echo; echo "$(PURPLE)Rebuilding $$F$(RESET)"; echo; make stack/module/download MODULE=$$F; MODULE=services/$$F MODULE_NAME=$$USERNAME-$$F envsubst < services/$$F/docker-compose.yaml | docker-compose -f - build; done
	@$(MAKE) stack/modules/restart

### Rebuild (with no-cache opt) and start all service modules.
stack/modules/rebuild/nocache:

	@echo "$(GREEN)Checking for init.sh to call before building in each module...$(RESET)"
	@for F in $(MODULES_TO_COMPOSE); do echo; echo "$(PURPLE)Rebuilding $$F$(RESET)"; echo; make stack/module/download MODULE=$$F; MODULE=services/$$F MODULE_NAME=$$USERNAME-$$F envsubst < services/$$F/docker-compose.yaml | docker-compose -f - build --no-cache; done
	@$(MAKE) stack/modules/restart

### Restart (not rebuild) all servivce modules.
stack/modules/restart: stack/modules/down stack/modules/up

### Create the docker network.
stack/network/create:

	@docker network inspect sp > /dev/null || docker network create --ipam-driver default --subnet=66.0.0.0/16 --attachable sp

### Delete the docker network.
stack/network/delete:

	@docker network inspect sp > /dev/null || docker network delete sp

### Re-create teh docker network.
stack/network/recreate:

	@echo "Re-creating docker network.."

	#
	# Test if network exists, if so delete it.
	#
	@docker network inspect sp && docker network rm sp || true

	#
	# Create the network
	#
	@docker network create --ipam-driver default --subnet=16.0.0.0/16 --attachable sp

templates:
	echo $(MODULES)
	@for MODULE in $(MODULES); do echo $$MODULE;cp -R infra/github-actions-module/workflows/build-and-deploy.yml services/$$MODULE/.github/workflows; done
