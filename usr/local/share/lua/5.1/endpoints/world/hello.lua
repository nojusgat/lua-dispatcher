local Endpoint = require("endpoint")

local WorldHelloEndpoint = setmetatable({}, Endpoint)
WorldHelloEndpoint.__index = WorldHelloEndpoint

function WorldHelloEndpoint:new(...)
    return setmetatable(Endpoint:new(...), WorldHelloEndpoint)
end

function WorldHelloEndpoint:get()
    self.send({ text = "Endpoint hierarchy /world/hello" })
end

return WorldHelloEndpoint
