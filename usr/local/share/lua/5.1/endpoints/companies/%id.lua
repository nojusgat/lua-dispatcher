local BaseEndpoint = require "endpoints.BaseEndpoint"
local CompanyEndpoint = {}
CompanyEndpoint.__index = CompanyEndpoint

setmetatable(CompanyEndpoint, { __index = BaseEndpoint })

function CompanyEndpoint:init()
    self:enable_auth("patch")
    self:enable_auth("delete")
end

function CompanyEndpoint:get()
    local id = tonumber(self.env["%id"][1])

    local company = self.model["Companies"]
        :get()
        :where({ id = id })
        :find_one()

    if company == nil then
        return self.send({ error = "Company not found" }, 404)
    end

    self.send({ result = company:to_table() })
end

function CompanyEndpoint:patch()
    self:permission("edit_companies")

    local id = tonumber(self.env["%id"][1])
    local data = self.body()

    local company = self.model["Companies"]
        :get()
        :where({ id = id })
        :find_one()

    if company == nil then
        return self.send({ error = "Company not found" }, 404)
    end

    if not data then
        return self.send({ error = "Data required" }, 400)
    end

    local status, results = pcall(function()
        for key, value in pairs(data) do
            if value == cjson.null then value = nil end
            if value == "" then value = nil end
            company[key] = value
        end
        company:save()
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send("", 204)
end

function CompanyEndpoint:delete()
    self:permission("delete_companies")

    local id = tonumber(self.env["%id"][1])

    local company = self.model["Companies"]
        :get()
        :where({ id = id })
        :find_one()

    if company == nil then
        return self.send({ error = "Company not found" }, 404)
    end

    local status, results = pcall(function()
        company:delete()
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send("", 204)
end

return CompanyEndpoint
