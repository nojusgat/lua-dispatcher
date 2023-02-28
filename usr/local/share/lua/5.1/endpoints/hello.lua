local Endpoint = require "endpoint"

local HelloEndpoint = setmetatable({}, Endpoint)
HelloEndpoint.__index = HelloEndpoint

function HelloEndpoint:new(...)
    return setmetatable(Endpoint:new(...), HelloEndpoint)
end

function HelloEndpoint:get()
    self.send({ text = "Hello World", query = self.env.query })
end

function HelloEndpoint:post()
    local data = self.body()
    self.send({ text = "Hello World", data = data })
end

return HelloEndpoint
