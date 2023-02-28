local jwt = require "luajwt"
local Endpoint = require "endpoint"

local GenerateEndpoint = setmetatable({}, Endpoint)
GenerateEndpoint.__index = GenerateEndpoint

function GenerateEndpoint:new(...)
    return setmetatable(Endpoint:new(...), GenerateEndpoint)
end

function GenerateEndpoint:get()
    local payload = {
        user = "test",
        nbf = os.time(),
        exp = os.time() + 3600,
    }

    local token = jwt.encode(payload, self.jwt_secret_key, "HS256")
    self.send({ token = token })
end

return GenerateEndpoint
