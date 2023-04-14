package generator

import (
	_ "embed"
	"fmt"
	"path/filepath"
	"strings"

	"github.com/gobuffalo/flect"
	"github.com/zeromicro/go-zero/core/collection"
	conf "github.com/zeromicro/go-zero/tools/goctl/config"
	"github.com/zeromicro/go-zero/tools/goctl/rpc/parser"
	"github.com/zeromicro/go-zero/tools/goctl/util"
	"github.com/zeromicro/go-zero/tools/goctl/util/format"
	"github.com/zeromicro/go-zero/tools/goctl/util/pathx"
	"github.com/zeromicro/go-zero/tools/goctl/util/stringx"
)

//go:embed logic-func.tpl
var logicFunctionTemplate string

//go:embed logic.tpl
var logicTemplate string

// GenLogic generates the logic file of the rpc service, which corresponds to the RPC definition items in proto.
func (g *Generator) GenLogic(ctx DirContext, proto parser.Proto, cfg *conf.Config,
	c *ZRpcContext) error {
	if !c.Multiple {
		return g.genLogicInCompatibility(ctx, proto, cfg)
	}

	return g.genLogicGroup(ctx, proto, cfg)
}

func (g *Generator) genLogicInCompatibility(ctx DirContext, proto parser.Proto,
	cfg *conf.Config) error {
	dir := ctx.GetLogic()
	service := proto.Service[0].Service.Name
	for _, rpc := range proto.Service[0].RPC {
		logicName := fmt.Sprintf("%sLogic", stringx.From(rpc.Name).ToCamel())
		logicFilename, err := format.FileNamingFormat(cfg.NamingFormat, rpc.Name+"_logic")
		if err != nil {
			return err
		}

		filename := filepath.Join(dir.Filename, logicFilename+".go")
		functions, err := g.genLogicFunction(service, proto.PbPackage, logicName, rpc)
		if err != nil {
			return err
		}

		imports := collection.NewSet()
		imports.AddStr(fmt.Sprintf(`"%v"`, ctx.GetSvc().Package))
		imports.AddStr(fmt.Sprintf(`"%v"`, ctx.GetPb().Package))
		text, err := pathx.LoadTemplate(category, logicTemplateFileFile, logicTemplate)
		if err != nil {
			return err
		}
		err = util.With("logic").GoFmt(true).Parse(text).SaveTo(map[string]any{
			"logicName":   fmt.Sprintf("%sLogic", stringx.From(rpc.Name).ToCamel()),
			"functions":   functions,
			"packageName": "logic",
			"imports":     strings.Join(imports.KeysStr(), pathx.NL),
		}, filename, false)
		if err != nil {
			return err
		}
	}
	return nil
}

func (g *Generator) genLogicGroup(ctx DirContext, proto parser.Proto, cfg *conf.Config) error {
	dir := ctx.GetLogic()
	for _, item := range proto.Service {
		serviceName := item.Name
		for _, rpc := range item.RPC {
			var (
				err           error
				filename      string
				logicName     string
				logicFilename string
				packageName   string
			)

			logicName = fmt.Sprintf("%sLogic", stringx.From(rpc.Name).ToCamel())
			childPkg, err := dir.GetChildPackage(serviceName)
			if err != nil {
				return err
			}

			serviceDir := filepath.Base(childPkg)
			nameJoin := fmt.Sprintf("%s_logic", serviceName)
			packageName = strings.ToLower(stringx.From(nameJoin).ToCamel())
			logicFilename, err = format.FileNamingFormat(cfg.NamingFormat, rpc.Name+"_logic")
			if err != nil {
				return err
			}

			filename = filepath.Join(dir.Filename, serviceDir, logicFilename+".go")
			functions, err := g.genLogicFunction(serviceName, proto.PbPackage, logicName, rpc)
			if err != nil {
				return err
			}

			imports := collection.NewSet()
			imports.AddStr(fmt.Sprintf(`"%v"`, ctx.GetSvc().Package))
			imports.AddStr(fmt.Sprintf(`"%v"`, ctx.GetPb().Package))
			text, err := pathx.LoadTemplate(category, logicTemplateFileFile, logicTemplate)
			if err != nil {
				return err
			}

			if err = util.With("logic").GoFmt(true).Parse(text).SaveTo(map[string]any{
				"logicName":   logicName,
				"functions":   functions,
				"packageName": packageName,
				"imports":     strings.Join(imports.KeysStr(), pathx.NL),
			}, filename, false); err != nil {
				return err
			}
		}
	}
	return nil
}

func (g *Generator) genLogicFunction(serviceName, goPackage, logicName string,
	rpc *parser.RPC) (string,
	error) {
	functions := make([]string, 0)
	text, err := pathx.LoadTemplate(category, logicFuncTemplateFileFile, logicFunctionTemplate)
	if err != nil {
		return "", err
	}

	operate := ""
	entityName := flect.Singularize(parser.CamelCase(serviceName))
	entitiesName := flect.Pluralize(parser.CamelCase(serviceName))

	if strings.HasPrefix(rpc.Name, "Create") && rpc.Name == "Create"+entityName {
		operate = "Create"
	}
	if strings.HasPrefix(rpc.Name, "List") && rpc.Name == "List"+entitiesName {
		operate = "List"
	}
	if strings.HasPrefix(rpc.Name, "Update") && rpc.Name == "Update"+entityName {
		operate = "Update"
	}
	if strings.HasPrefix(rpc.Name, "Delete") && rpc.Name == "Delete"+entityName {
		operate = "Delete"
	}
	if strings.HasPrefix(rpc.Name, "Get") && rpc.Name == "Get"+entityName {
		operate = "Get"
	}

	comment := parser.GetComment(rpc.Doc())
	streamServer := fmt.Sprintf("%s.%s_%s%s", goPackage, parser.CamelCase(serviceName),
		parser.CamelCase(rpc.Name), "Server")
	buffer, err := util.With("fun").Parse(text).Execute(map[string]any{
		"logicName":    logicName,
		"packageName":  goPackage,
		"serviceName":  serviceName,
		"entityName":   entityName,
		"entitiesName": entitiesName,
		"operate":      operate,
		"method":       parser.CamelCase(rpc.Name),
		"hasReq":       !rpc.StreamsRequest,
		"request":      fmt.Sprintf("*%s.%s", goPackage, parser.CamelCase(rpc.RequestType)),
		"hasReply":     !rpc.StreamsRequest && !rpc.StreamsReturns,
		"response":     fmt.Sprintf("*%s.%s", goPackage, parser.CamelCase(rpc.ReturnsType)),
		"responseType": fmt.Sprintf("%s.%s", goPackage, parser.CamelCase(rpc.ReturnsType)),
		"stream":       rpc.StreamsRequest || rpc.StreamsReturns,
		"streamBody":   streamServer,
		"hasComment":   len(comment) > 0,
		"comment":      comment,
	})
	if err != nil {
		return "", err
	}

	functions = append(functions, buffer.String())
	return strings.Join(functions, pathx.NL), nil
}
