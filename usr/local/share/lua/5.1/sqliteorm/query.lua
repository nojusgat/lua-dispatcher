local Query = {}

function Query:new(parent, args, created)
    local instance = {}
    instance.__parent__ = parent
    instance.__data__ = args
    instance.__dataRemove__ = {}
    instance.__insert__ = Query.__insert__
    instance.__update__ = Query.__update__
    instance.__created__ = created or false
    instance.save = Query.save
    instance.delete = Query.delete
    setmetatable(instance, { __index = Query.index, __newindex = Query.newIndex })
    return instance
end

function Query:__insert__()
    assert(type(self.__data__) == "table", "Invalid query data")
    assert(next(self.__data__) ~= nil, "Query data not found")
    local query = "INSERT INTO `" .. self.__parent__.name .. "` ("
    local values = ""

    local counter = 0
    for key, value in pairs(self.__data__) do
        local column = self.__parent__:get_column(key)
        assert(column.type.validator(value), string.format("Insert: Column %s in table %s failed type validation", column.name, self.__parent__.name))

        local colname = "`" .. column.name .. "`"
        local colvalue = column.type.to_sql(value)
        if counter ~= 0 then
            colname = ", " .. colname
            colvalue = ", " .. colvalue
        end

        values = values .. colvalue
        query = query .. colname
        counter = counter + 1
    end

    query = query .. ") VALUES (" .. values .. ")"
    assert(self.__parent__:execute(query))

    if self.__parent__.primary_column.auto_increment then
        self.__data__[self.__parent__.primary_column.name] = assert(self.__parent__:last_id())
    end
    self.__created__ = true
end

function Query:__update__()
    assert(type(self.__data__) == "table", "Invalid query data")
    assert(next(self.__data__) ~= nil, "Query data not found")
    assert(self.__data__[self.__parent__.primary_column.name] ~= nil, "No primary key, cannot update row")
    local query = "UPDATE `" .. self.__parent__.name .. "` SET "

    local counter = 0
    local function generate_query(key, value)
        local column = self.__parent__:get_column(key)
        assert(column.type.validator(value), string.format("Update: Column %s in table %s failed type validation", column.name, self.__parent__.name))

        local colvalue = "`" .. column.name .. "` = "
        colvalue = colvalue .. column.type.to_sql(value)
        if counter ~= 0 then
            colvalue = ", " .. colvalue
        end

        query = query .. colvalue
        counter = counter + 1
    end

    for key, value in pairs(self.__data__) do
        if key ~= self.__parent__.primary_column.name then
            generate_query(key, value)
        end
    end
    for _, value in pairs(self.__dataRemove__) do
        generate_query(value, nil)
    end
    self.__dataRemove__ = {}
    if counter < 1 then
        return
    end

    query = query .. " WHERE `" .. self.__parent__.primary_column.name .. "` = "
    query = query .. self.__parent__.primary_column.type.to_sql(self.__data__[self.__parent__.primary_column.name])

    assert(self.__parent__:execute(query))
end

function Query:delete()
    assert(type(self.__data__) == "table", "Invalid query data")
    assert(next(self.__data__) ~= nil, "Query data not found")
    assert(self.__data__[self.__parent__.primary_column.name] ~= nil, "No primary key, cannot delete row")

    local query = "DELETE FROM `" .. self.__parent__.name .. "` "
    query = query .. "WHERE `" .. self.__parent__.primary_column.name .. "` = "
    query = query .. "'" .. tostring(self.__data__[self.__parent__.primary_column.name]) .. "'"

    assert(self.__parent__:execute(query))
end

function Query:save()
    if self.__created__ then
        self:__update__()
    else
        self:__insert__()
    end
end

function Query:index(key)
    return self.__data__[key]
end

function Query:newIndex(key, value)
    if value == nil then
        table.insert(self.__dataRemove__, key)
    end
    self.__data__[key] = value
end

setmetatable(Query, { __call = Query.new })

return Query
