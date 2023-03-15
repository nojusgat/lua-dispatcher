local Query = {}

function Query:new(parent, args, created)
    local instance = {}
    instance.__parent__ = parent
    instance.__data__ = args
    instance.__dataUpdate__ = {}
    instance.__dataRemove__ = {}
    instance.__insert__ = Query.__insert__
    instance.__update__ = Query.__update__
    instance.__created__ = created or false
    instance.save = Query.save
    instance.delete = Query.delete
    instance.to_table = Query.to_table
    setmetatable(instance, { __index = Query.index, __newindex = Query.newIndex })
    return instance
end

function Query:__insert__()
    assert(type(self.__data__) == "table", "Invalid insert data")
    assert(next(self.__data__) ~= nil or next(self.__dataUpdate__) ~= nil, "Nothing to insert")
    local query = "INSERT INTO `" .. self.__parent__.name .. "` ("
    local values = ""

    for key, value in pairs(self.__dataUpdate__) do
        self.__data__[key] = value
    end
    for _, value in pairs(self.__dataRemove__) do
        self.__data__[value] = nil
    end
    self.__dataRemove__ = {}

    local counter = 0
    for key, value in pairs(self.__data__) do
        local column = self.__parent__:get_column(key)
        assert(column.type.validator(value),
            string.format("Column %s in table %s invalid type should be %s", column.name, self.__parent__.name,
                column.type.external))

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

    for _, primary_column in pairs(self.__parent__.primary_column) do
        if primary_column.auto_increment then
            self.__data__[primary_column.name] = assert(self.__parent__:last_id())
        end
    end
    self.__created__ = true
end

function Query:__update__()
    assert(type(self.__dataUpdate__) == "table", "Invalid update data")
    assert(next(self.__dataUpdate__) ~= nil or next(self.__dataRemove__) ~= nil, "Nothing to update")
    local query = "UPDATE `" .. self.__parent__.name .. "` SET "

    local counter = 0
    local function generate_query(key, value)
        local column = self.__parent__:get_column(key)
        assert(column.type.validator(value),
            string.format("Column %s in table %s invalid type should be %s", column.name, self.__parent__.name,
                column.type.external))

        local colvalue = "`" .. column.name .. "` = "
        colvalue = colvalue .. column.type.to_sql(value)
        if counter ~= 0 then
            colvalue = ", " .. colvalue
        end

        query = query .. colvalue
        counter = counter + 1
    end

    for key, value in pairs(self.__dataUpdate__) do
        if self.__data__[key] ~= value then
            generate_query(key, value)
        end
    end
    for _, value in pairs(self.__dataRemove__) do
        generate_query(value, nil)
    end
    assert(counter >= 1, "Nothing to update")

    query = query .. " WHERE "
    counter = 0
    for _, primary_column in pairs(self.__parent__.primary_column) do
        assert(self.__data__[primary_column.name] ~= nil,
            string.format("Unable to update, table %s has no primary key", self.__parent__.name))
        local where = "`" ..
            primary_column.name .. "` = " .. primary_column.type.to_sql(self.__data__[primary_column.name])
        if counter > 0 then
            where = " AND " .. where
        end
        counter = counter + 1
        query = query .. where
    end

    assert(self.__parent__:execute(query))
    for key, value in pairs(self.__dataUpdate__) do
        self.__data__[key] = value
    end
    for _, value in pairs(self.__dataRemove__) do
        self.__data__[value] = nil
    end
    self.__dataRemove__ = {}
end

function Query:delete()
    assert(type(self.__data__) == "table", "Invalid query data")
    assert(next(self.__data__) ~= nil, "Unable to delete, query has no data")

    local query = "DELETE FROM `" .. self.__parent__.name .. "` WHERE "
    local counter = 0
    for _, primary_column in pairs(self.__parent__.primary_column) do
        assert(self.__data__[primary_column.name] ~= nil,
            string.format("Unable to delete, table %s has no primary key", self.__parent__.name))
        local where = "`" ..
            primary_column.name .. "` = " .. primary_column.type.to_sql(self.__data__[primary_column.name])
        if counter > 0 then
            where = " AND " .. where
        end
        counter = counter + 1
        query = query .. where
    end

    assert(self.__parent__:execute(query))
    self.__data__ = {}
end

function Query:to_table(exluded)
    if not exluded then exluded = {} end
    local exlude_table = {}
    for _, value in pairs(exluded) do
        exlude_table[value] = true
    end
    local function helper(data)
        local converted = {}
        if next(data) ~= nil then
            for key, value in pairs(data) do
                if not exlude_table[key] then
                    if type(value) == "table" then
                        converted[key] = helper(value.__data__)
                    else
                        converted[key] = value
                    end
                end
            end
        end
        return converted
    end
    return helper(self.__data__)
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
    self.__dataUpdate__[key] = value
end

setmetatable(Query, { __call = Query.new })

return Query
