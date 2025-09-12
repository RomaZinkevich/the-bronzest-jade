mvn clean package &&
cd .. &&
docker-compose down &&
docker-compose build &&
docker-compose up