local BaseEndpoint = require "endpoints.BaseEndpoint"
local DivisionEndpoint = {}
DivisionEndpoint.__index = DivisionEndpoint

setmetatable(DivisionEndpoint, { __index = BaseEndpoint })

function DivisionEndpoint:init()
    self:enable_auth("patch")
    self:enable_auth("delete")
end

function DivisionEndpoint:get()
    local id = tonumber(self.env["%id"][1])

    local division = self.model["Divisions"]
        :get()
        :where({ id = id })
        :find_one()

    if division == nil then
        return self.send({ error = "Division not found" }, 404)
    end

    self.send({ result = division:to_table() })
end

function DivisionEndpoint:patch()
    self:permission("edit_structure")

    local id = tonumber(self.env["%id"][1])
    local data = self.body()

    local division = self.model["Divisions"]
        :get()
        :where({ id = id })
        :find_one()

    if division == nil then
        return self.send({ error = "Division not found" }, 404)
    end

    if not data then
        return self.send({ error = "Data required" }, 400)
    end

    local status, results = pcall(function()
        for key, value in pairs(data) do
            if value == cjson.null then value = nil end
            if value == "" then value = nil end
            division[key] = value
        end
        division:save()
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send("", 204)
end

function DivisionEndpoint:delete()
    self:permission("delete_structure")

    local id = tonumber(self.env["%id"][1])

    local division = self.model["Divisions"]
        :get()
        :where({ id = id })
        :find_one()

    if division == nil then
        return self.send({ error = "Division not found" }, 404)
    end

    local status, results = pcall(function()
        division:delete()
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send("", 204)
end

return DivisionEndpoint
