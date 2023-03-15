local HelloWorldEndpoint = {}
HelloWorldEndpoint.__index = HelloWorldEndpoint

setmetatable(HelloWorldEndpoint, {__index = Endpoint})

function HelloWorldEndpoint:get()
    self.send({ text = "Endpoint hierarchy /hello/world" })
end

return HelloWorldEndpoint
