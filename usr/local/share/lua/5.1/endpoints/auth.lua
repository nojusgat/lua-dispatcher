local Endpoint = require "endpoint"

local ProtectedEndpoint = setmetatable({}, Endpoint)
ProtectedEndpoint.__index = ProtectedEndpoint

function ProtectedEndpoint:new(...)
    return setmetatable(Endpoint:new(...), ProtectedEndpoint)
end

ProtectedEndpoint:enable_auth()

function ProtectedEndpoint:get()
    self.send({ data = self.auth_data })
end

function ProtectedEndpoint:delete()
    self.send({ text = "Testing HTTP methods" })
end

return ProtectedEndpoint
