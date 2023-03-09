local jwt = require "luajwt"
local model = require "models.config"

local LoginEndpoint = {}
LoginEndpoint.__index = LoginEndpoint

setmetatable(LoginEndpoint, {__index = Endpoint})

function LoginEndpoint:post()
    self.send("")
end

return LoginEndpoint
