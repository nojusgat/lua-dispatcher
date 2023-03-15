local jwt = require "luajwt"
local crypto = require "crypto"

local BaseEndpoint = require "endpoints.BaseEndpoint"
local LoginEndpoint = {}
LoginEndpoint.__index = LoginEndpoint

setmetatable(LoginEndpoint, { __index = BaseEndpoint })

function LoginEndpoint:post()
    local data = self.body()

    if not data then
        return self.send({ error = "Email or password not provided" }, 400)
    end

    if not data.email or data.email == cjson.null or data.email == "" then
        return self.send({ error = "Email is not provided" }, 400)
    end

    if not data.password or data.password == cjson.null or data.password == "" then
        return self.send({ error = "Password is not provided" }, 400)
    end

    if not string.match(data.email, "^[%w._]+@%w+%.[%a.]+$") then
        return self.send({ error = "Email address is not valid" }, 400)
    end

    local user = self.model["Users"]
        :get()
        :where({ email = data.email })
        :find_one()

    if user == nil then
        return self.send({ error = "Invalid email address or password" }, 400)
    end

    local password = crypto.digest("sha256", user.password_salt .. data.password)
    if user.password ~= password then
        return self.send({ error = "Incorrect password" }, 400)
    end

    local user_data = user:to_table()
    user_data.password = nil
    user_data.password_salt = nil

    local permissions = self.model["UserPermissions"]
        :get()
        :where({ user_id = user_data.id })
        :find_one()

    if permissions then
        permissions = permissions:to_table()
        permissions.user_id = nil
    end

    user_data.permissions = permissions or {}

    local exp = os.time() + 3600

    local payload = {
        user = user_data,
        nbf = os.time(),
        exp = exp,
    }

    user.exp = exp
    user:save()

    local token = jwt.encode(payload, self.jwt_secret_key, "HS256")
    self.send({ user = user_data, token = token })
end

return LoginEndpoint
