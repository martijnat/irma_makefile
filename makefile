BASEDIR="/opt/irma"
DOWNLOADDIR="/opt/irma_git"
IP := $(shell hostname -i | tr ' ' '\n' | tail -n 2 | head -n 1 | tr -d '\n')
TERMINAL="xfce4-terminal"
ROOT_TERMINAL="xterm"

# Run as a non-root user from a fresh install of Debian 9 (stable)

all: clean build run


# Installs all software needed but not present on a fresh install of debian
libs-debian:
	sudo apt-get update
	sudo apt-get upgrade
	sudo apt-get install -y gradle openjdk-8-jre openjdk-8-jdk curl
	curl -sL https://deb.nodesource.com/setup_8.x | sudo bash -
	sudo apt-get install nodejs
	sudo npm install -g grunt-cli
	sudo npm install -g bower
	sudo npm install -g compass
	sudo npm install -g qrcode-terminal request jsonwebtoken fs
	npm install qrcode-terminal request jsonwebtoken fs

libs-arch:
	sudo pacman -Syu
	sudo npm install -g grunt-cli
	sudo npm install -g bower
	sudo npm install -g compass
	sudo npm install -g qrcode-terminal request jsonwebtoken fs
	npm install qrcode-terminal request jsonwebtoken fs

clean:
	sudo rm -fr ${BASEDIR} || true
	sudo cp -r ${DOWNLOADDIR}/ ${BASEDIR}/
	sudo chmod 777 -R ${BASEDIR}

build: network irma_api_server irma_js irma_glue

network:
	sudo ${ROOT_TERMINAL} -e "ufw disable; create_ap wlp3s0 enp2s0 tmpwifi tmptmptmp; ufw enable" &

git_repositories:
	echo test
	sudo rm -fr ${DOWNLOADDIR} || true
	sudo mkdir ${DOWNLOADDIR}
	sudo chmod 777 -R ${DOWNLOADDIR}
	cd ${DOWNLOADDIR} && git clone 'https://github.com/credentials/irma_api_server'
	cd ${DOWNLOADDIR}"/irma_api_server" && git submodule update --init
	cd ${DOWNLOADDIR}"/irma_api_server/src/main/resources/" && git clone -b combined 'https://github.com/credentials/irma_configuration'
	cd ${DOWNLOADDIR} && git clone 'https://github.com/credentials/irma_js'
	cd ${DOWNLOADDIR} && git clone 'https://github.com/credentials/irma_web_service'

irma_api_server:
	cp ${DOWNLOADDIR}"/irma_api_server/src/main/resources/config.sample-demo.json" ${BASEDIR}"/irma_api_server/src/main/resources/config.json"
	bash ${BASEDIR}"/irma_api_server/utils/keygen.sh" ${BASEDIR}"/irma_api_server/src/main/resources/sk" ${BASEDIR}"/irma_api_server/src/main/resources/pk"
	cd ${BASEDIR}"/irma_api_server" && gradle buildProduct
	cd ${BASEDIR}"/irma_api_server" && npm install qrcode-terminal request jsonwebtoken fs

irma_js:
	sed -i "s,<IRMA_WEB_SERVER>,http://${IP}:8081/irma_api_server/server/,g" ${BASEDIR}/irma_js/examples/*
	sed -i "s,<IRMA_API_SERVER>,http://${IP}:8081/irma_api_server/api/v2/,g" ${BASEDIR}/irma_js/examples/*
	rm -fr ${BASEDIR}/irma_js/build || true
	cd ${BASEDIR}"/irma_js" && npm install
	cd ${BASEDIR}"/irma_js" && bower install
	cd ${BASEDIR}"/irma_js" && grunt build

irma_glue:
	cp issue.js              ${BASEDIR}/irma_api_server/utils/
	cp verify.js             ${BASEDIR}/irma_api_server/utils/
	cp issue.sh              ${BASEDIR}/irma_api_server/utils/
	cp verify.sh             ${BASEDIR}/irma_api_server/utils/
	cp connect_smartwatch.sh ${BASEDIR}/irma_api_server/utils/

run:
	cd ${BASEDIR}"/irma_js" && ${TERMINAL} -e 'grunt --server_url="http://${IP}:8081/irma_api_server/"' &
	cd ${BASEDIR}/irma_api_server/build/output/irma_api_server/  && ${TERMINAL} -e './run.sh' &
	sleep 10		#wait for server to be up
	cp -r ${BASEDIR}/irma_js/build/bower_components ${BASEDIR}/irma_api_server/build/output/irma_api_server/webapps-exploded/irma_api_server/webapp/
	cp -r ${BASEDIR}/irma_js/build/client ${BASEDIR}/irma_api_server/build/output/irma_api_server/webapps-exploded/irma_api_server/webapp/
	cp -r ${BASEDIR}/irma_js/build/examples ${BASEDIR}/irma_api_server/build/output/irma_api_server/webapps-exploded/irma_api_server/webapp/
	cp -r ${BASEDIR}/irma_js/build/server ${BASEDIR}/irma_api_server/build/output/irma_api_server/webapps-exploded/irma_api_server/webapp/
	cd ${BASEDIR}"/irma_web_service/WebContent" && cp -r * ${BASEDIR}/irma_api_server/build/output/irma_api_server/webapps-exploded/irma_api_server/webapp/
