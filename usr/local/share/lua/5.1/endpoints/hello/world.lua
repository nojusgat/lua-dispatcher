local Endpoint = require("endpoint")

local HelloWorldEndpoint = setmetatable({}, Endpoint)
HelloWorldEndpoint.__index = HelloWorldEndpoint

function HelloWorldEndpoint:new(...)
    return setmetatable(Endpoint:new(...), HelloWorldEndpoint)
end

function HelloWorldEndpoint:get()
    self.send({ text = "Endpoint hierarchy /hello/world" })
end

return HelloWorldEndpoint
