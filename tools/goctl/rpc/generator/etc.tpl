Name: {{.serviceName}}.rpc
ListenOn: 0.0.0.0:8080
Etcd:
  Hosts:
  - 127.0.0.1:2379
  Key: {{.serviceName}}.rpc
# Etcd:
#   Hosts:
#   - 127.0.0.1:2379
#   Key: manager.rpc
DB:
  Datesource: root:password@tcp(127.0.0.1:3306)/cc?charset=utf8mb4&parseTime=true&loc=Asia%2FShanghai
CacheRedis:
  - Host: 127.0.0.1:6379
    Pass: password
    Type: node