# pymongo-api

## Как запустить

Запускаем сервис конфигурации, mongodb shard1, mongodb shard2, router1, router2 и приложение

```shell
docker compose up -d
```

Делаем инициализацию сервера конфигурации

```shell
docker exec -it configSrv mongosh --port 27017 --quiet <<EOF && exit
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
EOF
```

Инициируем 1-ю шарду и 3 реплики к ней

```shell
docker exec -it shard1 mongosh --port 27018 --quiet <<EOF && exit
rs.initiate(
   {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1:27018" },
        { _id : 1, host : "shard1_1:27028" },
        { _id : 2, host : "shard1_2:27038" },
        { _id : 3, host : "shard1_3:27048" }
      ]
    }
);
EOF
```

Инициируем 2-ю шарду и 3 реплики к ней

```shell
docker exec -it shard2 mongosh --port 27019 --quiet <<EOF && exit
rs.initiate(
   {
      _id : "shard2",
      members: [
        { _id : 0, host : "shard2:27019" },
        { _id : 1, host : "shard2_1:27029" },
        { _id : 2, host : "shard2_2:27039" },
        { _id : 3, host : "shard2_3:27049" }
      ]
    }
);
EOF
```

Конфигурируем роутер

```shell
docker exec -it mongos_router mongosh --port 27020 --quiet <<EOF && exit
sh.addShard( "shard1/shard1:27018");
sh.addShard( "shard2/shard2:27019");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
use somedb
EOF
```


Заполняем mongodb данными

```shell
docker exec -it mongos_router mongosh --port 27020 --quiet <<EOF && exit
use somedb;
for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i});
EOF
```

## Как проверить

### Получение количества документов на shard1
```shell
docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF && exit
use somedb
db.helloDoc.countDocuments()
EOF 
```

### Получение количества документов на shard2
```shell
docker compose exec -T shard2 mongosh --port 27019 --quiet <<EOF && exit
use somedb
db.helloDoc.countDocuments()
EOF 
```

### Получение общего количества документов на mongodb
```shell
docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF && exit
use somedb
db.helloDoc.countDocuments()
EOF 
```

### Если вы запускаете проект на локальной машине

Откройте в браузере http://localhost:8080

## Доступные эндпоинты

Список доступных эндпоинтов, swagger http://localhost:8080/docs