local Column = {}

function Column:new(args)
    local instance = setmetatable({}, { __index = Column })
    instance.name = instance:validate_name(args.name)
    instance.type = instance:validate_type(args.type)
    instance.primary_key = instance:validate_primary_key(args.primary_key)
    instance.auto_increment = instance:validate_auto_increment(args.auto_increment)
    instance.length = tonumber(args.length) or nil
    instance.foreign_key = args.foreign_key

    if args.nullable ~= nil then
        instance.nullable = args.nullable
    else
        instance.nullable = true
    end

    -- Data will be added in table
    instance.table = nil
    instance.converted_name = nil
    instance.converted_name_full = nil
    instance.select = nil
    return instance
end

function Column:types()
    local this = self
    local types = {
        ["string"] = {
            internal = "string",
            external = "TEXT",
            validator = function (value)
                if self.nullable == true and value == nil then
                    return true
                end
                if self.nullable == false and value == nil then
                    return false
                end
                if type(value) ~= "string" then
                    return false
                end
                if this.length ~= nil and #value > this.length then
                    return false
                end
                return true
            end,
            to_sql = function (value)
                if value == nil then
                    return "NULL"
                end
                return "'" .. value .. "'"
            end,
            from_sql = function (value)
                return tostring(value)
            end
        },
        ["number"] = {
            internal = "number",
            external = "INTEGER",
            validator = function (value)
                if self.nullable == true and value == nil then
                    return true
                end
                if self.nullable == false and value == nil then
                    return false
                end
                return type(value) == "number"
            end,
            to_sql = function (value)
                if value == nil then
                    return "NULL"
                end
                return tostring(value)
            end,
            from_sql = function (value)
                return tonumber(value)
            end
        },
        ["boolean"] = {
            internal = "boolean",
            external = "INTEGER",
            validator = function (value)
                if self.nullable == true and value == nil then
                    return true
                end
                if self.nullable == false and value == nil then
                    return false
                end
                return type(value) == "boolean"
            end,
            to_sql = function (value)
                if value == true then
                    return "1"
                end
                return "0"
            end,
            from_sql = function (value)
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

function Column:to_query()
    return string.format(
        "`%s` %s%s%s%s",
        self.name,
        self.type.external,
        self.primary_key and " PRIMARY KEY" or "",
        self.auto_increment and " AUTOINCREMENT" or "",
        self.nullable and "" or " NOT NULL"
    )
end

setmetatable(Column, { __call = Column.new })

return Column