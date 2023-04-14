package {{.pkg}}
{{if .withCache}}
import (
	"context"

	"github.com/doug-martin/goqu/v9"
	"github.com/zeromicro/go-zero/core/stores/cache"
	"github.com/zeromicro/go-zero/core/stores/sqlx"
)
{{else}}

import "github.com/zeromicro/go-zero/core/stores/sqlx"
{{end}}
var _ {{.upperStartCamelObject}}Model = (*custom{{.upperStartCamelObject}}Model)(nil)

type (
	// {{.upperStartCamelObject}}Model is an interface to be customized, add more methods here,
	// and implement the added methods in custom{{.upperStartCamelObject}}Model.
	{{.upperStartCamelObject}}Model interface {
		{{.lowerStartCamelObject}}Model
		FindOneByQuery(ctx context.Context, filter queryinfo.Expression) (*{{.upperStartCamelObject}}, error)
		FindCount(ctx context.Context, filter queryinfo.Expression) (int64, error)
		FindAll(ctx context.Context, filter queryinfo.Expression, order []queryinfo.OrderedExpression, limit int64, offset int64) ([]*{{.upperStartCamelObject}}, error)
	}

	custom{{.upperStartCamelObject}}Model struct {
		*default{{.upperStartCamelObject}}Model
	}
)

// New{{.upperStartCamelObject}}Model returns a model for the database table.
func New{{.upperStartCamelObject}}Model(conn sqlx.SqlConn{{if .withCache}}, c cache.CacheConf{{end}}) {{.upperStartCamelObject}}Model {
	return &custom{{.upperStartCamelObject}}Model{
		default{{.upperStartCamelObject}}Model: new{{.upperStartCamelObject}}Model(conn{{if .withCache}}, c{{end}}),
	}
}

func (m *default{{.upperStartCamelObject}}Model) FindOneByQuery(ctx context.Context, filter queryinfo.Expression) (*{{.upperStartCamelObject}}, error) {
	query, _, err := dialect.From(m.tableRaw).Where(filter).ToSQL()
	if err != nil {
		return nil, err
	}

	var resp {{.upperStartCamelObject}}
	err = m.QueryRowNoCacheCtx(ctx, &resp, query)
	switch err {
	case nil:
		return &resp, nil
	default:
		return nil, err
	}

}

func (m *default{{.upperStartCamelObject}}Model) FindCount(ctx context.Context, filter queryinfo.Expression) (int64, error) {
	query, _, err := dialect.From(m.tableRaw).Select(goqu.COUNT("*")).Where(filter).ToSQL()
	if err != nil {
		return 0, err
	}

	var resp int64
	err = m.QueryRowNoCacheCtx(ctx, &resp, query)
	switch err {
	case nil:
		return resp, nil
	default:
		return 0, err
	}

}

func (m *default{{.upperStartCamelObject}}Model) FindAll(ctx context.Context, filter queryinfo.Expression, order []queryinfo.OrderedExpression, limit int64, offset int64) ([]*{{.upperStartCamelObject}}, error) {
	b := dialect.From(m.tableRaw).Where(filter).Order(order...).Limit(uint(limit))
	if offset > 0 {
		b = b.Offset(uint(offset))
	}
	query, _, err := b.Order(order...).ToSQL()
	if err != nil {
		return nil, err
	}

	var resp []*{{.upperStartCamelObject}}
	err = m.QueryRowsNoCacheCtx(ctx, &resp, query)
	switch err {
	case nil:
		return resp, nil
	default:
		return nil, err
	}
}
