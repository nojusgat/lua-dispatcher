local DownloadEndpoint = {}
DownloadEndpoint.__index = DownloadEndpoint

setmetatable(DownloadEndpoint, { __index = Endpoint })

function DownloadEndpoint:get()
    local file = assert(io.open("/www/cgi-bin/api_dispatcher.lua", "rb"))
    local data = file:read("*a")
    file:close()
    self.send_file(data, "api_dispatcher.lua")
end

return DownloadEndpoint
