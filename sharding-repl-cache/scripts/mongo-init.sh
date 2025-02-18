#!/bin/bash

#Делаем инициализацию сервера конфигурации

docker exec -it configSrv mongosh --port 27017 --quiet <<EOF
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

#Инициируем 1-ю шарду и 3 реплики к ней

docker exec -it shard1 mongosh --port 27018 --quiet <<EOF
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

#Инициируем 2-ю шарду и 3 реплики к ней

docker exec -it shard2 mongosh --port 27019 --quiet <<EOF
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

#Конфигурируем роутер

docker exec -it mongos_router mongosh --port 27020 --quiet <<EOF
sh.addShard( "shard1/shard1:27018");
sh.addShard( "shard2/shard2:27019");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
use somedb
EOF

#Заполняем mongodb данными

docker exec -it mongos_router mongosh --port 27020 --quiet <<EOF
use somedb;
for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i});
EOF
