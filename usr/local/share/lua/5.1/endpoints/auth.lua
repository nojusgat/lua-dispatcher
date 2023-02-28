local Endpoint = require "endpoint"

local ProtectedEndpoint = {}
ProtectedEndpoint.__index = ProtectedEndpoint

setmetatable(ProtectedEndpoint, { __index = Endpoint })

function ProtectedEndpoint:init()
    self:enable_auth()
end

function ProtectedEndpoint:get()
    self.send({ data = self.auth_data })
end

function ProtectedEndpoint:delete()
    self.send({ text = "Testing HTTP methods" })
end

return ProtectedEndpoint
