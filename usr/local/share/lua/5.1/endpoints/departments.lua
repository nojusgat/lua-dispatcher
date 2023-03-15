local BaseEndpoint = require "endpoints.BaseEndpoint"
local DepartmentsEndpoint = {}
DepartmentsEndpoint.__index = DepartmentsEndpoint

setmetatable(DepartmentsEndpoint, { __index = BaseEndpoint })

function DepartmentsEndpoint:init()
    self:enable_auth("post")
end

function DepartmentsEndpoint:get()
    local where = {}

    if self.env.query.q ~= nil then
        local search = tostring(self.env.query.q)
        where["name__like"] = "%" .. search .. "%"
    end

    local total_count = self.model["Departments"]
        :get()
        :where(where)
        :count()

    local limit, page, total_pages = self:pagination(total_count)

    local offset = (page - 1) * limit
    local results = self.model["Departments"]
        :get()
        :where(where)
        :limit(limit)
        :offset(offset)
        :find()

    local formated_results = {}
    for _, value in pairs(results) do
        table.insert(formated_results, value:to_table())
    end

    self.send({ results = formated_results, page = page, total_pages = total_pages, total_results = #results })
end

function DepartmentsEndpoint:post()
    self:permission("edit_structure")

    local data = self.body()

    if not data then
        return self.send({ error = "Data required" }, 400)
    end

    local status, results = pcall(function()
        local department = self.model["Departments"](data)
        department:save()
        return department
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send({ result = results:to_table() }, 201)
end

return DepartmentsEndpoint
