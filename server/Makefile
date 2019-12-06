build:
	docker build . -t dreg.fxpal.net/rhelp

publish:
	docker push dreg.fxpal.net/rhelp

start:
	docker pull dreg.fxpal.net/rhelp
	docker run --rm -it -d -p 5443:5443 --name rhelp dreg.fxpal.net/rhelp

stop:
	docker rm -f rhelp