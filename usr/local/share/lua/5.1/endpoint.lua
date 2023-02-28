local jwt = require "luajwt"

local Endpoint = {}
Endpoint.__index = Endpoint

function Endpoint:new(recv, send, env, jwt_secret_key)
    local instance = {}
    self.enabled_authorization = {}

    self.body = recv
    self.send = send
    self.env = env

    self.jwt_secret_key = jwt_secret_key
    setmetatable(instance, self)
    return instance
end

function Endpoint:enable_auth(method)
    if not method then
        self.enabled_authorization = { post = true, put = true, get = true, delete = true }
        return
    end

    method = string.lower(method)
    if self.enabled_authorization == nil then
        self.enabled_authorization = { [method] = true }
    else
        self.enabled_authorization[method] = true
    end
end

function Endpoint:authorized(method)
    if not self.enabled_authorization[method] then
        return true
    end

    if self.env.auth_headers.type ~= "Bearer" then
        return false
    end

    local decoded = jwt.decode(self.env.auth_headers.token, self.jwt_secret_key, true)
    if not decoded then
        return false
    end

    self.auth_data = decoded
    return true
end

function Endpoint:handle_request()
    local method = string.lower(self.env.REQUEST_METHOD)
    if not self[method] then
        return self.send({ error = "Method Not Allowed" }, "405 Method Not Allowed")
    end

    if self:authorized(method) then
        return self[method](self)
    end

    self.send({ error = "Unauthorized" }, "401 Unauthorized")
end

return Endpoint
