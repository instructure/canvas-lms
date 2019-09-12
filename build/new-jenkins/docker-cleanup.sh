# sometimes things don't cleanup so run this a few times
docker-compose stop && docker-compose down --volumes --remove-orphans --rmi all
docker-compose stop && docker-compose down --volumes --remove-orphans --rmi all
docker-compose stop && docker-compose down --volumes --remove-orphans --rmi all

echo "running docker images"
docker ps -a
echo "images locally"
docker images
echo "volumes left over"
docker volume ls
