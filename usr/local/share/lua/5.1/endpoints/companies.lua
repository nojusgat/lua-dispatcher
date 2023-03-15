local BaseEndpoint = require "endpoints.BaseEndpoint"
local CompaniesEndpoint = {}
CompaniesEndpoint.__index = CompaniesEndpoint

setmetatable(CompaniesEndpoint, { __index = BaseEndpoint })

function CompaniesEndpoint:init()
    self:enable_auth("post")
end

function CompaniesEndpoint:get()
    local where = {}

    if self.env.query.q ~= nil then
        local search = tostring(self.env.query.q)
        where["name__like"] = "%" .. search .. "%"
    end

    local total_count = self.model["Companies"]
        :get()
        :where(where)
        :count()

    local limit, page, total_pages = self:pagination(total_count)

    local offset = (page - 1) * limit
    local results = self.model["Companies"]
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

function CompaniesEndpoint:post()
    self:permission("edit_companies")

    local data = self.body()

    if not data then
        return self.send({ error = "Data required" }, 400)
    end

    local status, results = pcall(function()
        local company = self.model["Companies"](data)
        company:save()
        return company
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send({ result = results:to_table() }, 201)
end

return CompaniesEndpoint
