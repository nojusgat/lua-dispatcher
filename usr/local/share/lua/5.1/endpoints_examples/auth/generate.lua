local GenerateEndpoint = {}
GenerateEndpoint.__index = GenerateEndpoint

setmetatable(GenerateEndpoint, {__index = Endpoint})

function GenerateEndpoint:get()
    local payload = {
        user = "test",
        nbf = os.time(),
        exp = os.time() + 3600,
    }

    local token = self.jwt:encode(payload)
    self.send({ token = token })
end

return GenerateEndpoint
