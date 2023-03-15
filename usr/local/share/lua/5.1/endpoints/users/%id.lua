local BaseEndpoint = require "endpoints.BaseEndpoint"
local UserEndpoint = {}
UserEndpoint.__index = UserEndpoint

setmetatable(UserEndpoint, { __index = BaseEndpoint })

function UserEndpoint:init()
    self:enable_auth("get")
    self:enable_auth("patch")
    self:enable_auth("delete")
end

function UserEndpoint:get()
    self:permission("system_admin")

    local id = tonumber(self.env["%id"][1])

    local user = self.model["Users"]
        :get()
        :select({ "id", "username", "name", "email", "avatar" })
        :where({ id = id })
        :find_one()

    if user == nil then
        return self.send({ error = "User not found" }, 404)
    end

    self.send({ result = user:to_table() })
end

function UserEndpoint:patch()
    self:permission("system_admin")

    local id = tonumber(self.env["%id"][1])
    local data = self.body()

    local user = self.model["Users"]
        :get()
        :where({ id = id })
        :find_one()

    if user == nil then
        return self.send({ error = "User not found" }, 404)
    end

    if not data then
        return self.send({ error = "Data required" }, 400)
    end

    data.password_salt = nil
    data.exp = nil
    if data.password then
        if tostring(data.password):len() < 8 then
            return self.send({ error = "Minimum password length is 8 characters" }, 400)
        end
        local password, password_salt = self:encrypt_password(data.password)
        data.password = password
        data.password_salt = password_salt
    end

    local last_avatar = nil
    if data.avatar then
        if data.avatar ~= cjson.null and data.avatar ~= "" then
            data.avatar = self:upload_image(data.avatar)
        end
        last_avatar = user.avatar
    end

    local status, results = pcall(function()
        for key, value in pairs(data) do
            if value == cjson.null then value = nil end
            if value == "" then value = nil end
            user[key] = value
        end
        user:save()
    end)

    if status == false then
        if data.avatar then
            os.remove(self.image_path .. data.avatar)
        end
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    if last_avatar then
        os.remove(self.image_path .. last_avatar)
    end

    self.send("", 204)
end

function UserEndpoint:delete()
    self:permission("system_admin")

    local id = tonumber(self.env["%id"][1])

    local user = self.model["Users"]
        :get()
        :where({ id = id })
        :find_one()

    if user == nil then
        return self.send({ error = "User not found" }, 404)
    end

    local status, results = pcall(function()
        user:delete()
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send("", 204)
end

return UserEndpoint
