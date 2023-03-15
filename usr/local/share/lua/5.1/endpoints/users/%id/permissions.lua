local BaseEndpoint = require "endpoints.BaseEndpoint"
local UserPermissionsEndpoint = {}
UserPermissionsEndpoint.__index = UserPermissionsEndpoint

setmetatable(UserPermissionsEndpoint, { __index = BaseEndpoint })

function UserPermissionsEndpoint:init()
    self:enable_auth("get")
    self:enable_auth("patch")
end

function UserPermissionsEndpoint:get()
    self:permission("read_permissions")

    local user_id = tonumber(self.env["%id"][1])

    local permissions = self.model["UserPermissions"]
        :get()
        :where({
            user_id = user_id
        })
        :find_one()

    if permissions == nil then
        return self.send({ error = "Permissions not found" }, 404)
    end

    local results = permissions:to_table()
    results.user_id = nil

    self.send({ result = results })
end

function UserPermissionsEndpoint:patch()
    self:permission("edit_permissions")

    local user_id = tonumber(self.env["%id"][1])
    local data = self.body()

    if not data then
        return self.send({ error = "Data required" }, 400)
    end

    local permissions = self.model["UserPermissions"]
        :get()
        :where({
            user_id = user_id
        })
        :find_one()

    if permissions == nil then
        return self.send({ error = "Permissions not found" }, 404)
    end

    data.user_id = nil

    local status, results = pcall(function()
        for key, value in pairs(data) do
            if value == cjson.null then value = nil end
            if value == "" then value = nil end
            permissions[key] = value
        end
        permissions:save()
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send("", 204)
end

return UserPermissionsEndpoint
