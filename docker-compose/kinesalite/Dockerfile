FROM node:latest

RUN npm install kinesalite --global
RUN npm install leveldown
EXPOSE 4567
ENTRYPOINT ["/usr/local/bin/kinesalite"]
