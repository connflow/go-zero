package generator

import (
	_ "embed"
	"path/filepath"
	"strings"

	"github.com/gobuffalo/flect"
	"github.com/zeromicro/go-zero/tools/goctl/util"
	"github.com/zeromicro/go-zero/tools/goctl/util/pathx"
	"github.com/zeromicro/go-zero/tools/goctl/util/stringx"
)

//go:embed rpc.tpl
var rpcTemplateText string

// ProtoTmpl returns a sample of a proto file
func ProtoTmpl(out string) error {
	protoFilename := filepath.Base(out)
	serviceName := stringx.From(strings.TrimSuffix(protoFilename, filepath.Ext(protoFilename)))
	text, err := pathx.LoadTemplate(category, rpcTemplateFile, rpcTemplateText)
	if err != nil {
		return err
	}

	dir := filepath.Dir(out)
	err = pathx.MkdirIfNotExist(dir)
	if err != nil {
		return err
	}

	entity := flect.Singularize(flect.Capitalize(flect.Camelize(serviceName.Title())))
	entities := flect.Pluralize(entity)

	err = util.With("t").Parse(text).SaveTo(map[string]string{
		"package":     serviceName.Untitle(),
		"serviceName": serviceName.Title(),
		"entity":      entity,
		"entities":    entities,
	}, out, false)
	return err
}
