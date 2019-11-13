#!/bin/bash

# sometimes things don't cleanup so run this a few times
docker-compose stop && docker-compose down --volumes --remove-orphans --rmi all
docker-compose stop && docker-compose down --volumes --remove-orphans --rmi all
docker-compose stop && docker-compose down --volumes --remove-orphans --rmi all

# remove all containers
docker rm --force --volumes $(docker ps --all --quiet)

# delete all containers
docker rmi -f $(docker images --all --quiet)

echo "running docker images"
docker ps -a
echo "images locally"
docker images -a
echo "volumes left over"
docker volume ls
