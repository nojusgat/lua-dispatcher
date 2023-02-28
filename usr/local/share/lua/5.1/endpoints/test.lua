local Endpoint = require "endpoint"

local TestEndpoint = {}
TestEndpoint.__index = TestEndpoint

setmetatable(TestEndpoint, {__index = Endpoint})

function TestEndpoint:get()
    self.send({ text = "Test endpoint" })
end

return TestEndpoint
