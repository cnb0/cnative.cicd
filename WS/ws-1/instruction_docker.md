## Backend = Node.js

Pull image

```
$docker image pull node:14.5.0-stretch
```

Create Dockerfile

```
FROM node:14.5.0-stretch
WORKDIR /app
COPY . .
RUN npm install
EXPOSE 4000
CMD [ "npm", "start" ]
```

Build imaage from Dockerfile

```
$docker image build -t myapp:1.0.0 .
```

Create container from image

```
$docker container run --name backend -p 4000:4000 myapp:1.0.0
```

Open url=`http://loccalhost:4000`

## Database = MongoDB

Pull image

```
$docker image pull mongo:4.2.8
```

Create container

```
$docker network create demo-network

$docker container run -d --name mongo \
    --network demo-network \
    -e MONGO_INITDB_ROOT_USERNAME=mongoadmin \
    -e MONGO_INITDB_ROOT_PASSWORD=secret \
    -e MONGO_INITDB_DATABASE=mydb \
    mongo:4.2.8
```

Delete and Create container from Backend image

```
// Delete container
$docker container stop backend
$docker container rm backend

// Create new container
$docker container run --name backend -p 4000:4000 \
   --network demo-network \
   myapp:1.0.0
```

## Working with docker-compose

Create file `docker-compose.yml`

```
version: "3.8"
services:
  backend:
    image: myapp:1.0.0
    ports:
      - 4000:4000

  mongo:
    image: mongo:4.2.8

```

Start with docker-compose

```
$docker-compose up -d
$docker-compose ps
$docker-compose logs --follow
```

Delette all

```
$docker-compose down
```
