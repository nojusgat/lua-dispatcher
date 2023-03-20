local BaseEndpoint = require "endpoints.BaseEndpoint"
local UserProfileEndpoint = {}
UserProfileEndpoint.__index = UserProfileEndpoint

setmetatable(UserProfileEndpoint, { __index = BaseEndpoint })

function UserProfileEndpoint:init()
    self:enable_auth("get")
    self:enable_auth("patch")
end

function UserProfileEndpoint:get()
    self.send({ result = self.auth_data.user })
end

function UserProfileEndpoint:patch()
    local data = self.body()

    if not data then
        return self.send({ error = "Data required" }, 400)
    end

    data.system_admin = nil
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
        last_avatar = self.auth_data.user_model.avatar
    end

    local status, results = pcall(function()
        for key, value in pairs(data) do
            if value == cjson.null then value = nil end
            if value == "" then value = nil end
            self.auth_data.user_model[key] = value
        end
        self.auth_data.user_model:save()
    end)

    if status == false then
        if data.avatar then
            os.remove(self.image_path() .. data.avatar)
        end
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    if last_avatar then
        os.remove(self.image_path() .. last_avatar)
    end

    self.send("", 204)
end

return UserProfileEndpoint
