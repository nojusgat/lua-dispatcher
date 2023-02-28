local Endpoint = {}
Endpoint.__index = Endpoint

function Endpoint:new(send, env)
    local instance = {}
    setmetatable(instance, self)
    self.enabled_authorization = {}
    self.send = send
    self.env = env
    return instance
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

function Endpoint:authorized(method)
    if not self.enabled_authorization[method] then
        return true
    end

    if self.env.auth_headers.type ~= "Bearer" then
        return false
    end

    return true
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

return Endpoint
