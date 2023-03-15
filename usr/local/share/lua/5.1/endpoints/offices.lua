local BaseEndpoint = require "endpoints.BaseEndpoint"
local OfficesEndpoint = {}
OfficesEndpoint.__index = OfficesEndpoint

setmetatable(OfficesEndpoint, { __index = BaseEndpoint })

function OfficesEndpoint:init()
    self:enable_auth("post")
end

function OfficesEndpoint:get()
    local where = {}

    if self.env.query.q ~= nil then
        local search = tostring(self.env.query.q)
        where.__or = {}
        where.__or["name__like"] = "%" .. search .. "%"
        where.__or["street__like"] = "%" .. search .. "%"
        where.__or["street_number__like"] = "%" .. search .. "%"
        where.__or["city__like"] = "%" .. search .. "%"
        where.__or["country__like"] = "%" .. search .. "%"
    end

    local total_count = self.model["Offices"]
        :get()
        :where(where)
        :count()

    local limit, page, total_pages = self:pagination(total_count)

    local offset = (page - 1) * limit
    local results = self.model["Offices"]
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

function OfficesEndpoint:post()
    self:permission("edit_offices")

    local data = self.body()

    if not data then
        return self.send({ error = "Data required" }, 400)
    end

    local status, results = pcall(function()
        local office = self.model["Offices"](data)
        office:save()
        return office
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send({ result = results:to_table() }, 201)
end

return OfficesEndpoint
