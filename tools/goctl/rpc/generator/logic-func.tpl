{{if .hasComment}}{{.comment}}{{end}}
func (l *{{.logicName}}) {{.method}} ({{if .hasReq}}in {{.request}}{{if .stream}},stream {{.streamBody}}{{end}}{{else}}stream {{.streamBody}}{{end}}) ({{if .hasReply}}{{.response}},{{end}} error) {
	// todo: check your logic here and delete this line

	{{if eq .operate "create"}}
	err := in.Validate()
	if err != nil {
		return nil, err
	}

	if in.Data.Id == "" {
		in.Data.Id = xid.New().String()
	}

	obj := model.{{.entityName}}{}
	if err = copier.Copy(&obj, in.Data); err == nil {
		_, err = l.svcCtx.{{.entityName}}Model.Insert(l.ctx, &obj)
	}
	if err != nil {
		return nil, err
	}
	return in.Data, nil
	{{else if eq .operate "Update"}}
	err := in.Validate()
	if err != nil {
		return nil, err
	}

	obj, err := l.svcCtx.{{.entityName}}Model.FindOne(l.ctx, in.Data.Id)
	if err != nil {
		return nil, err
	}
	// update fields by in field_mask
	mask, _ := fieldmask_utils.MaskFromProtoFieldMask(in.UpdateMask, generator.CamelCase)
	err = fieldmask_utils.StructToStruct(mask, in.Data, obj)
	if err != nil {
		return nil, err
	}

	err = l.svcCtx.{{.entityName}}Model.Update(l.ctx, obj)
	if err != nil {
		return nil, err
	}

	return &{{.responseType}}{}, nil
	{{else if eq .operate "Delete" }}
	err := in.Validate()
	if err != nil {
		return nil, err
	}

	err = l.svcCtx.{{.entityName}}Model.Delete(l.ctx, in.Id)
	if err != nil {
		return nil, err
	}

	return &{{.responseType}}{}, nil
	{{else if eq .operate "Get" }}
	err := in.Validate()
	if err != nil {
		return nil, err
	}

	obj, err := l.svcCtx.{{.entityName}}Model.FindOne(l.ctx, in.Id)
	if err != nil {
		return nil, err
	}
	res := &{{.responseType}}{}
	err = copier.Copy(res, obj)
	if err != nil {
		return nil, err
	}
	return res, nil
	{{else if eq .operate "List" }}
	err := in.Validate()
	if err != nil {
		return nil, err
	}

	q := queryinfo.QueryInfo{}

	copier.Copy(&q, in)

	filter, sorting, limit, offset := queryinfo.PageInfoToExpModeOffset(q)

	var count int64
	if in.Total {
		count, err = l.svcCtx.{{.entityName}}Model.FindCount(l.ctx, filter)
		if err != nil && err != model.ErrNotFound {
			return nil, err
		}
	}

	objs, err := l.svcCtx.{{.entityName}}Model.FindAll(l.ctx, filter, sorting, limit, offset)
	if err != nil && err != model.ErrNotFound {
		return nil, err
	}
	res := []*{{.packageName}}.{{.entityName}}{}
	for _, obj := range objs {
		o := {{.packageName}}.{{.entityName}}{}
		err = copier.Copy(&o, obj)
		if err != nil {
			return nil, err
		}
		res = append(res, &o)
	}

	return &{{.responseType}}{
		Data:      res,
		TotalSize: count,
	}, nil
	{{end}}

	return {{if .hasReply}}&{{.responseType}}{},{{end}} nil
}
