local BaseEndpoint = require "endpoints.BaseEndpoint"
local OfficeEndpoint = {}
OfficeEndpoint.__index = OfficeEndpoint

setmetatable(OfficeEndpoint, { __index = BaseEndpoint })

function OfficeEndpoint:init()
    self:enable_auth("patch")
    self:enable_auth("delete")
end

function OfficeEndpoint:get()
    local id = tonumber(self.env["%id"][1])

    local office = self.model["Offices"]
        :get()
        :where({ id = id })
        :find_one()

    if office == nil then
        return self.send({ error = "Office not found" }, 404)
    end

    self.send({ result = office:to_table() })
end

function OfficeEndpoint:patch()
    self:permission("edit_offices")

    local id = tonumber(self.env["%id"][1])
    local data = self.body()

    local office = self.model["Offices"]
        :get()
        :where({ id = id })
        :find_one()

    if office == nil then
        return self.send({ error = "Office not found" }, 404)
    end

    if not data then
        return self.send({ error = "Data required" }, 400)
    end

    local status, results = pcall(function()
        for key, value in pairs(data) do
            if value == cjson.null then value = nil end
            if value == "" then value = nil end
            office[key] = value
        end
        office:save()
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send("", 204)
end

function OfficeEndpoint:delete()
    self:permission("delete_offices")

    local id = tonumber(self.env["%id"][1])

    local office = self.model["Offices"]
        :get()
        :where({ id = id })
        :find_one()

    if office == nil then
        return self.send({ error = "Office not found" }, 404)
    end

    local status, results = pcall(function()
        office:delete()
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send("", 204)
end

return OfficeEndpoint
