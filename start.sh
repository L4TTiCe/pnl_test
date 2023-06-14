sudo chown -R 1000:100 ./notebooks
sudo chown -R 1000:100 ./data

docker-compose up --build --remove-orphans --force-recreate
