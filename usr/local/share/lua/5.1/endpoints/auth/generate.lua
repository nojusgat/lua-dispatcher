local jwt = require "luajwt"

local GenerateEndpoint = {}
GenerateEndpoint.__index = GenerateEndpoint

setmetatable(GenerateEndpoint, {__index = Endpoint})

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
