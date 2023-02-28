local Endpoint = require("endpoint")

local HelloEndpoint = setmetatable({}, Endpoint)
HelloEndpoint.__index = HelloEndpoint

function HelloEndpoint:new(...)
    return setmetatable(Endpoint:new(...), HelloEndpoint)
end

HelloEndpoint:authorize_get()

function HelloEndpoint:get()
    self.send({ text = "Hello World", query = self.env.query })
end

return HelloEndpoint
