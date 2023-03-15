local Select = {}

local operators = {
    ["IN"] = "__in",
    ["LIKE"] = "__like",
    ["OR"] = "__or",
    ["AND"] = "__and",
}

function Select:new(parent)
    local instance = setmetatable({}, { __index = Select })
    instance.parent = parent
    instance.rules = {
        select = {},
        where = {},
        limit = nil,
        offset = nil,
        join = {}
    }
    return instance
end

function Select:__build_select__()
    local function merge_tables(t1, t2)
        for _, v in ipairs(t2) do
            table.insert(t1, v)
        end
        return t1
    end

    local columns = self.parent.columns
    if next(self.rules.join) then
        for _, join in pairs(self.rules.join) do
            columns = merge_tables(columns, join.table.columns)
        end
    end

    local custom_select = {}
    if next(self.rules.select) ~= nil then
        for _, name in pairs(self.rules.select) do
            custom_select[name] = true
        end
    end

    local select = ""
    local counter = 0
    local function concat(name)
        if counter > 0 then
            name = ", " .. name
        end
        select = select .. name
        counter = counter + 1
    end
    for _, value in pairs(columns) do
        if next(custom_select) ~= nil then
            if next(self.rules.join) then
                if custom_select[value.converted_name_full] then
                    concat(value.select)
                end
            else
                if custom_select[value.name] then
                    concat(value.select)
                end
            end
        else
            concat(value.select)
        end
    end
    return select
end

function Select:__build_join__()
    local query = ""
    for _, join in pairs(self.rules.join) do
        local foreign_key = self.parent:get_foreign_key(join.table.name)
        query = query .. " " .. join.type .. " JOIN "
        query = query .. "`" .. join.table.name .. "` ON "
        query = query .. "`" .. join.table.name .. "`.`" .. join.table.primary_column[1].name .. "` = "
        query = query .. "`" .. self.parent.name .. "`.`" .. foreign_key.name .. "`"
    end
    return query
end

function Select:__build_where__()
    local function ends_with(string, value)
        return string.sub(string, - #value) == value
    end

    local function cut_ending(string, value)
        return string.sub(string, 1, - #value - 1)
    end

    local function parse_rules(rules, seperator, group)
        local columns = {}
        if next(self.rules.join) then
            for _, value in pairs(self.parent.columns) do
                columns[value.converted_name_full] = value
            end
            for _, join in pairs(self.rules.join) do
                for _, value in pairs(join.table.columns) do
                    columns[value.converted_name_full] = value
                end
            end
        else
            for _, value in pairs(self.parent.columns) do
                columns[value.name] = value
            end
        end
        local counter = 0
        local where = ""
        for key, value in pairs(rules) do
            local colvalue = ""
            if type(value) == "table" and ends_with(key, operators["OR"]) then
                colvalue = parse_rules(value, "OR", true)
            elseif type(value) == "table" and ends_with(key, operators["AND"]) then
                colvalue = parse_rules(value, "AND", true)
            elseif type(value) == "table" and ends_with(key, operators["IN"]) then
                local column = columns[cut_ending(key, operators["IN"])]
                assert(column ~= nil, string.format("Invalid column name %s in select", cut_ending(key, operators["IN"])))
                local converted_values = {}
                for _, _value in pairs(value) do
                    table.insert(converted_values, column.type.to_sql(_value))
                end
                colvalue = column.converted_name_full .. " IN (" .. table.concat(converted_values, ", ") .. ")"
            elseif ends_with(key, operators["LIKE"]) then
                local column = columns[cut_ending(key, operators["LIKE"])]
                assert(column ~= nil,
                    string.format("Invalid column name %s in select", cut_ending(key, operators["LIKE"])))
                colvalue = column.converted_name_full .. " LIKE " .. column.type.to_sql(value)
            else
                local column = columns[key]
                assert(column ~= nil, string.format("Invalid column name %s in select", key))
                colvalue = column.converted_name_full .. " = " .. column.type.to_sql(value)
            end

            if counter ~= 0 then
                colvalue = " " .. seperator .. " " .. colvalue
            end

            where = where .. colvalue
            counter = counter + 1
        end
        if group == true then
            return "(" .. where .. ")"
        end
        return where
    end

    return " WHERE " .. parse_rules(self.rules.where, "AND")
end

function Select:__query__()
    local select = self:__build_select__()

    local query = "SELECT " .. select .. " FROM `" .. self.parent.name .. "`"

    if next(self.rules.join) then
        query = query .. self:__build_join__()
    end

    if next(self.rules.where) then
        query = query .. self:__build_where__()
    end

    if self.rules.limit then
        query = query .. " LIMIT " .. tostring(self.rules.limit)
        if self.rules.offset then
            query = query .. " OFFSET " .. tostring(self.rules.offset)
        end
    end

    return self.parent:rows(query)
end

function Select:count()
    local query = "SELECT count(" ..
        self.parent.primary_column[1].converted_name_full .. ") FROM `" .. self.parent.name .. "`"

    if next(self.rules.join) then
        query = query .. self:__build_join__()
    end

    if next(self.rules.where) then
        query = query .. self:__build_where__()
    end

    if self.rules.limit then
        query = query .. " LIMIT " .. tostring(self.rules.limit)
        if self.rules.offset then
            query = query .. " OFFSET " .. tostring(self.rules.offset)
        end
    end

    local cursor = self.parent:execute(query)
    local fetch = cursor:fetch({})
    if not fetch or next(fetch) == nil then
        return 0
    end
    return fetch[1]
end

function Select:select(args)
    assert(type(args) == "table", "Invalid select should be a table")
    self.rules.select = args
    return self
end

function Select:where(args)
    assert(type(args) == "table", "Invalid where should be a table")
    self.rules.where = args
    return self
end

function Select:limit(count)
    assert(type(count) == "number", "Invalid limit should be a number")
    if count == 0 then
        self.rules.limit = nil
        return self
    end
    self.rules.limit = count
    return self
end

function Select:offset(count)
    assert(type(count) == "number", "Invalid offset should be a number")
    if count == 0 then
        self.rules.offset = nil
        return self
    end
    self.rules.offset = count
    return self
end

function Select:left_join(value)
    assert(type(table) == "table", "Invalid left join should be a table")
    table.insert(self.rules.join, {
        type = "LEFT",
        table = value
    })
    return self
end

function Select:inner_join(value)
    assert(type(value) == "table", "Invalid inner join should be a table")
    table.insert(self.rules.join, {
        type = "INNER",
        table = value
    })
    return self
end

function Select:find()
    return self:__query__()
end

function Select:find_one()
    self.rules.limit = 1
    return self:__query__()[1]
end

setmetatable(Select, { __call = Select.new })
return Select
