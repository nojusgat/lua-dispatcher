local HelloEndpoint = {}
HelloEndpoint.__index = HelloEndpoint

setmetatable(HelloEndpoint, { __index = Endpoint })

function HelloEndpoint:get()
    self.send({ text = "Hello World", query = self.env.query })
end

function HelloEndpoint:post()
    local data = self.body()
    self.send({ text = "Hello World", data = data })
end

return HelloEndpoint
