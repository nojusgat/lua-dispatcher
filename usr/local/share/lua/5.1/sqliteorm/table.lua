local Query = require "sqliteorm.query"
local Select = require "sqliteorm.select"
local Column = require "sqliteorm.column"

local function table_contains_key(table, key, element)
    for _, value in pairs(table) do
        if value[key] == element then
            return true
        end
    end
    return false
end

local Table = {}

function Table:new(parent, args)
    local instance = setmetatable({}, { __index = Table, __call = Table.insert })
    assert(args.name ~= nil and args.name ~= "", "Invalid table name")
    instance.parent = parent
    instance.name = args.name
    instance.converted_name = nil
    instance.foreign_keys = {}
    instance.columns = instance:convert_column_object(args.columns)
    instance.primary_column = instance:validate_columns()

    instance:add_table_to_columns()

    if args.drop_existing == true then
        assert(instance.parent:execute(string.format("DROP TABLE IF EXISTS `%s`", instance.name)))
    end

    -- Table creation
    assert(instance.parent:execute(
        string.format(
            "CREATE TABLE IF NOT EXISTS `%s` (\n\t%s%s\n)",
            instance.name,
            instance:columns_to_query(),
            instance:foreign_keys_to_query()
        )
    ))

    return instance
end

function Table:escape(string)
    return self.parent:escape(string)
end

function Table:execute(query)
    return self.parent:execute(query)
end

function Table:rows(query)
    local data = {}
    local _cursor = self:execute(query)

    if _cursor then
        local row = _cursor:fetch({}, "a")

        while row do
            local row_data = {}
            local row_table_data = {}
            for key, value in pairs(row) do
                local tbl_name = string.match(key, "([^.]*)")
                if tbl_name == self.converted_name then
                    local column = self:get_column_converted(key)
                    row_data[column.name] = column.type.from_sql(value)
                else
                    for _, col in pairs(self.foreign_keys) do
                        if col.foreign_key.table.name == tbl_name then
                            if not row_table_data[tbl_name] then
                                row_table_data[tbl_name] = {
                                    table = col.foreign_key.table,
                                    columns = {}
                                }
                            end
                            local column = col.foreign_key.table:get_column_converted(key)
                            row_table_data[tbl_name]["columns"][column.name] = column.type.from_sql(value)
                            break
                        end
                    end
                end
            end
            for key, value in pairs(row_table_data) do
                row_data[key] = Query(value["table"], value["columns"], true)
            end
            local object = Query(self, row_data, true)
            table.insert(data, object)
            row = _cursor:fetch({}, "a")
        end

        _cursor:close()
    end
    return data
end

function Table:last_id()
    return self.parent:last_id()
end

function Table:convert_column_object(columns)
    assert(columns ~= nil and type(columns) == "table", "Invalid columns")
    assert(next(columns) ~= nil, "Undefined columns")

    local data = {}
    for _, value in ipairs(columns) do
        local col = Column(value)
        if value.foreign_key ~= nil and type(value.foreign_key) == "table" then
            table.insert(self.foreign_keys, col)
        end
        table.insert(data, col)
    end
    return data
end

function Table:validate_columns()
    assert(next(self.columns) ~= nil, "Undefined columns")
    local primary = 0
    local primary_column = nil
    for _, value in pairs(self.columns) do
        if value.primary_key then
            primary = primary + 1
            primary_column = value
        end
    end
    assert(primary == 1, "There should be exactly one primary column")
    return primary_column
end

function Table:get_column(name)
    for _, value in pairs(self.columns) do
        if value.name == name then
            return value
        end
    end
    error(string.format("Column '%s' in table '%s' not found", name, self.name))
end

function Table:get_foreign_key(table)
    for _, value in pairs(self.foreign_keys) do
        if value.foreign_key.table.name == table then
            return value
        end
    end
    error(string.format("Foreign key on table '%s' in table '%s' not found", table, self.name))
end

function Table:get_column_converted(name)
    for _, value in pairs(self.columns) do
        if value.converted_name_full == name then
            return value
        end
    end
    error(string.format("Column '%s' in table '%s' not found", name, self.name))
end

function Table:add_table_to_columns()
    local converted_table_name = string.gsub(self.name, "%s+", "_")
    self.converted_name = converted_table_name

    for _, value in pairs(self.columns) do
        local converted_column_name = string.gsub(value.name, "%s+", "_")
        value.table = self
        value.converted_name = converted_column_name
        value.converted_name_full = self.converted_name .. "." .. converted_column_name
        value.select = string.format("`%s`.`%s` AS `%s`", self.name, value.name, value.converted_name_full)
    end
end

function Table:columns_to_query()
    local converted = {}
    for _, value in pairs(self.columns) do
        table.insert(converted, value:to_query())
    end
    return table.concat(converted, ",\n\t")
end

function Table:foreign_keys_to_query()
    local converted = {}
    for _, value in pairs(self.foreign_keys) do
        assert(value.foreign_key.table, "Invalid foreign key should have a table")
        assert(type(value.foreign_key.table) == "table", "Invalid foreign key should have a table")

        local column = value.foreign_key.table.primary_column.name
        if value.foreign_key.column ~= nil then
            column = value.foreign_key.column
            value.foreign_key.table:get_column(column)
        end

        local query = string.format("FOREIGN KEY (`%s`)", value.name)
        query = query .. "\n\t" .. string.format("REFERENCES `%s` (`%s`)", value.foreign_key.table.name, column)
        if value.foreign_key.update and type(value.foreign_key.update) == "string" then
            query = query .. "\n\t\t" .. "ON UPDATE " .. string.upper(value.foreign_key.update)
        end
        if value.foreign_key.delete and type(value.foreign_key.delete) == "string" then
            query = query .. "\n\t\t" .. "ON DELETE " .. string.upper(value.foreign_key.delete)
        end
        table.insert(converted, query)
    end
    if #converted > 0 then
        return ",\n\t" .. table.concat(converted, ", ")
    end
    return ""
end

function Table:insert(data)
    assert(type(data) == "table", "Invalid insert data")
    for key in pairs(data) do
        assert(
            table_contains_key(self.columns, "name", key) == true,
            string.format("Insert failed. Column '%s' not found in table '%s'", key, self.name)
        )
    end

    return Query(self, data)
end

function Table:get()
    assert(self.parent ~= nil, "Could not use get")
    return Select(self)
end

setmetatable(Table, { __call = Table.new })

return Table
