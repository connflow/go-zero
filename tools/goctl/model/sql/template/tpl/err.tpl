package {{.pkg}}

import (
	"github.com/doug-martin/goqu/v9"
	_ "github.com/doug-martin/goqu/v9/dialect/mysql"
	"github.com/zeromicro/go-zero/core/stores/sqlx"
)

var ErrNotFound = sqlx.ErrNotFound
var dialect = goqu.Dialect("mysql")
