package config

import "github.com/zeromicro/go-zero/zrpc"

type Config struct {
	zrpc.RpcServerConf
	DB struct {
		Datesource string
	}
	CacheRedis cache.CacheConf
}
