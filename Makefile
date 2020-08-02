include Makefile.config

.PHONY: dev build compress deploy clean

all: build

dev:
	yarn dev

build:
	yarn build

compress:
	find public -type f \( -name '*.html' -o -name '*.js' -o -name '*.css' -o -name '*.xml' -o -name '*.svg' -o -name '*.json' \) -exec gzip -v -k -f --best {} \;

deploy: build
	sed -i.bu 's|base href="/"|base href="https://$(SERVER)/timer/"|' public/index.html
	find public -type f \( -name '*.html' -o -name '*.js' -o -name '*.css' -o -name '*.xml' -o -name '*.svg' -o -name '*.json' \) -exec gzip -v -k -f --best {} \;
	rsync -avz --delete-after public/ root@$(SERVER):$(DEPLOY_TARGET)
	mv public/index.html.bu public/index.html

clean:
	rm -f **/*.gz
	rm -rf public/build