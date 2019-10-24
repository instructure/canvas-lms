# sometimes things don't cleanup so run this a few times
docker-compose stop && docker-compose down --volumes --remove-orphans --rmi all
docker-compose stop && docker-compose down --volumes --remove-orphans --rmi all
docker-compose stop && docker-compose down --volumes --remove-orphans --rmi all
# remove any dangling containers
docker rmi -f $(docker images -f "dangling=true" -q)
# find any leftover containers containing canvas-lms and remove
docker images | grep "canvas-lms" | awk '{print $1 ":" $2}' | xargs docker rmi -f

echo "running docker images"
docker ps -a
echo "images locally"
docker images -a
echo "volumes left over"
docker volume ls
