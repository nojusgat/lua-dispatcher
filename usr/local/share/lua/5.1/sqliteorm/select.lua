local Select = {}

function Select:new(parent)
    local instance = setmetatable({}, { __index = Select })
    instance.parent = parent
    instance.rules = {
        where = {},
        limit = nil,
        offset = nil,
        join = {
            type = nil,
            table = nil
        }
    }
    return instance
end

function Select:__query__()
    local select = ""
    local counter = 0
    local function concat_select_fields(columns)
        for _, value in pairs(columns) do
            local _select = value.select
            if counter > 0 then
                _select = ", " .. _select
            end
            select = select .. _select
            counter = counter + 1
        end
    end
    concat_select_fields(self.parent.columns)
    if self.rules.join.table ~= nil then
        concat_select_fields(self.rules.join.table.columns)
    end

    local query = "SELECT " .. select .. " FROM `" .. self.parent.name .. "`"

    if self.rules.join.type ~= nil then
        local foreign_key = self.parent:get_foreign_key(self.rules.join.table.name)
        query = query .. " " .. self.rules.join.type .. " JOIN `" .. self.rules.join.table.name .. "` ON "
        query = query ..
            "`" .. self.rules.join.table.name .. "`.`" .. self.rules.join.table.primary_column.name .. "` = "
        query = query .. "`" .. self.parent.name .. "`.`" .. foreign_key.name .. "`"
    end

    if next(self.rules.where) then
        query = query .. " WHERE "
        counter = 0
        for key, value in pairs(self.rules.where) do
            local column = self.parent:get_column(key)
            local colvalue = column.converted_name_full .. " = '" .. tostring(value) .. "'"
            if counter ~= 0 then
                colvalue = " AND " .. colvalue
            end

            query = query .. colvalue
            counter = counter + 1
        end
    end

    if self.rules.limit then
        query = query .. " LIMIT " .. tostring(self.rules.limit)
        if self.rules.offset then
            query = query .. " OFFSET " .. tostring(self.rules.offset)
        end
    end

    return self.parent:rows(query)
end

function Select:where(args)
    assert(type(args) == "table", "Invalid where should be a table")
    self.rules.where = args
    return self
end

function Select:limit(count)
    assert(type(count) == "number", "Invalid limit should be a number")
    self.rules.limit = count
    return self
end

function Select:offset(count)
    assert(type(count) == "number", "Invalid offset should be a number")
    self.rules.offset = count
    return self
end

function Select:left_join(table)
    assert(type(table) == "table", "Invalid left join should be a table")
    self.rules.join.type = "LEFT"
    self.rules.join.table = table
    return self
end

function Select:inner_join(table)
    assert(type(table) == "table", "Invalid inner join should be a table")
    self.rules.join.type = "INNER"
    self.rules.join.table = table
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
