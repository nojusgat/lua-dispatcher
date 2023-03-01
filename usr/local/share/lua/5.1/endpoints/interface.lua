local InterfaceEndpoint = {}
InterfaceEndpoint.__index = InterfaceEndpoint

setmetatable(InterfaceEndpoint, { __index = Endpoint })

function InterfaceEndpoint:post()
    local data = self.body()
    if not data then
        return self.send({ error = "Post data required" }, "400 Bad Request")
    end
    if not data.name or data.name == cjson.null or data.name == "" then
        return self.send({ error = "Field 'name' not provided" }, "400 Bad Request")
    end

    local example = UCIOrm:init("example")
    local created = example:create("interface")
    if not created then
        return self.send({ error = "Failed to create interface" }, "500 Internal Server Error")
    end

    example.options.name = data.name
    example.options.proto = 'static'
    example.options.address = '192.168.1.1'
    example.options.netmask = '255.255.255.0'
    example.options.gateway = '192.168.1.0'
    example.options.dns = { "8.8.8.8", "1.1.1.1" }
    example:save()

    self.send({ interface = example.options(), name = example.options.name }, "201 Created")
end

return InterfaceEndpoint
