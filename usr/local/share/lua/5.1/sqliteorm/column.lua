local Column = {}

function Column:new(args)
    local instance = setmetatable({}, { __index = Column })
    instance.name = instance:validate_name(args.name)
    instance.type = instance:validate_type(args.type)
    instance.primary_key = instance:validate_primary_key(args.primary_key)
    instance.auto_increment = instance:validate_auto_increment(args.auto_increment)
    instance.nullable = instance:validate_nullable(args.nullable)
    instance.default = instance:validate_default(args.default)
    instance.unique = instance:validate_unique(args.unique)
    instance.length = tonumber(args.length) or nil
    instance.foreign_key = args.foreign_key

    -- Data will be added in table
    instance.table = nil
    instance.converted_name = nil
    instance.converted_name_full = nil
    instance.select = nil
    return instance
end

function Column:types()
    local types = {
        ["string"] = {
            internal = "string",
            external = "TEXT",
            validator = function(value)
                if self.nullable == true and value == nil then
                    return true
                end
                if self.nullable == false and value == nil then
                    return false
                end
                if not tostring(value) then
                    return false
                end
                if self.length ~= nil and #tostring(value) > self.length then
                    return false
                end
                return true
            end,
            to_sql = function(value)
                if value == nil then
                    return "NULL"
                end
                value = tostring(value)
                return "'" .. self.table:escape(value) .. "'"
            end,
            from_sql = function(value)
                return tostring(value)
            end
        },
        ["number"] = {
            internal = "number",
            external = "INTEGER",
            validator = function(value)
                if self.nullable == true and value == nil then
                    return true
                end
                if self.nullable == false and value == nil then
                    return false
                end
                if not tonumber(value) then
                    return false
                end
                return true
            end,
            to_sql = function(value)
                if value == nil then
                    return "NULL"
                end
                return tostring(value)
            end,
            from_sql = function(value)
                return tonumber(value)
            end
        },
        ["boolean"] = {
            internal = "boolean",
            external = "INTEGER",
            validator = function(value)
                if self.nullable == true and value == nil then
                    return true
                end
                if self.nullable == false and value == nil then
                    return false
                end
                if type(value) == "string" and (value == "true" or value == "false") then
                    return true
                end
                return type(value) == "boolean"
            end,
            to_sql = function(value)
                if value == "true" or value == true then
                    return "1"
                end
                return "0"
            end,
            from_sql = function(value)
                if tonumber(value) == 1 then
                    return true
                end
                return false
            end
        }
    }
    return types
end

function Column:validate_name(value)
    assert(type(value) == "string", "Column name must be string")
    return value
end

function Column:validate_type(value)
    assert(self:types()[value], "Invalid data type")
    return self:types()[value]
end

function Column:validate_primary_key(value)
    if value == nil then return false end
    assert(type(value) == "boolean", "Primary key should be true or false")
    return value
end

function Column:validate_auto_increment(value)
    if value == nil then return false end
    assert(type(value) == "boolean", "Auto increment should be true or false")
    assert(self.type.internal == "number", "Auto increment can only be used with numbers")
    return value
end

function Column:validate_nullable(value)
    if value == nil then return true end
    assert(type(value) == "boolean", "Nullable should be true or false")
    return value
end

function Column:validate_default(value)
    if value == nil then return nil end
    assert(self.type.validator(value) == true, "Default value must be the same type")
    return self.type.to_sql(value)
end

function Column:validate_unique(value)
    if value == nil then return false end
    assert(type(value) == "boolean", "Unique should be true or false")
    return value
end

function Column:to_query()
    return string.format(
        "`%s` %s%s%s%s%s",
        self.name,
        self.type.external,
        (self.primary_key and #self.table.primary_column == 1) and " PRIMARY KEY" or "",
        self.auto_increment and " AUTOINCREMENT" or "",
        self.default ~= nil and " DEFAULT " .. self.default or "",
        self.nullable and "" or " NOT NULL",
        self.unique and " UNIQUE" or ""
    )
end

setmetatable(Column, { __call = Column.new })

return Column
