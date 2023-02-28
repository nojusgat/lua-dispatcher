local Endpoint = require("endpoint")

local TestEndpoint = setmetatable({}, Endpoint)
TestEndpoint.__index = TestEndpoint

function TestEndpoint:new(...)
    return setmetatable(Endpoint:new(...), TestEndpoint)
end

function TestEndpoint:get()
    self.send({ text = "Test endpoint", query = self.env.query })
end

return TestEndpoint
