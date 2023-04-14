package generator

import (
	"embed"
	"io/ioutil"
	"path/filepath"

	"github.com/zeromicro/go-zero/tools/goctl/util/pathx"
)

//go:embed proto/*
var protoDir embed.FS

// ProtoTmpl returns a sample of a proto file
func ProtoCommonTmpl(out string) error {

	// read file in protoDir and save to out
	protoFiles, err := protoDir.ReadDir(".")
	dirStack := []string{"."}

	if err == nil {
		for len(protoFiles) > 0 {
			obj := protoFiles[0]
			protoFiles = protoFiles[1:]
			dir := dirStack[0]
			dirStack = dirStack[1:]
			if obj.IsDir() {
				files, _ := protoDir.ReadDir(filepath.Join(dir, obj.Name()))
				for _, f := range files {
					dirStack = append(dirStack, filepath.Join(dir, obj.Name()))
					protoFiles = append(protoFiles, f)
				}
				continue
			} else {
				f, err := protoDir.Open(filepath.Join(dir, obj.Name()))
				if err == nil {
					output, err := ioutil.ReadAll(f)
					if err == nil {
						p := filepath.Join(out, dir, obj.Name())
						d := filepath.Dir(p)
						err := pathx.MkdirIfNotExist(d)
						if err != nil {
							continue
						}
						ioutil.WriteFile(p, output, 0o666)
					}
				}
			}
		}
	}
	return err
}
