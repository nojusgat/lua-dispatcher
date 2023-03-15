local BaseEndpoint = require "endpoints.BaseEndpoint"
local GroupEndpoint = {}
GroupEndpoint.__index = GroupEndpoint

setmetatable(GroupEndpoint, { __index = BaseEndpoint })

function GroupEndpoint:init()
    self:enable_auth("patch")
    self:enable_auth("delete")
end

function GroupEndpoint:get()
    local id = tonumber(self.env["%id"][1])

    local group = self.model["Groups"]
        :get()
        :where({ id = id })
        :find_one()

    if group == nil then
        return self.send({ error = "Group not found" }, 404)
    end

    self.send({ result = group:to_table() })
end

function GroupEndpoint:patch()
    self:permission("edit_structure")

    local id = tonumber(self.env["%id"][1])
    local data = self.body()

    local group = self.model["Groups"]
        :get()
        :where({ id = id })
        :find_one()

    if group == nil then
        return self.send({ error = "Group not found" }, 404)
    end

    if not data then
        return self.send({ error = "Data required" }, 400)
    end

    local status, results = pcall(function()
        for key, value in pairs(data) do
            if value == cjson.null then value = nil end
            if value == "" then value = nil end
            group[key] = value
        end
        group:save()
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send("", 204)
end

function GroupEndpoint:delete()
    self:permission("delete_structure")

    local id = tonumber(self.env["%id"][1])

    local group = self.model["Groups"]
        :get()
        :where({ id = id })
        :find_one()

    if group == nil then
        return self.send({ error = "Group not found" }, 404)
    end

    local status, results = pcall(function()
        group:delete()
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send("", 204)
end

return GroupEndpoint
