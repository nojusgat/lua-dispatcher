local UploadEndpoint = {}
UploadEndpoint.__index = UploadEndpoint

setmetatable(UploadEndpoint, { __index = Endpoint })

function UploadEndpoint:post()
    local data = self.body()
    if not data then
        return self.send({ error = "Post data required" }, 400)
    end

    if not data.uploadfile or not data.uploadfile.data then
        return self.send({ error = "File required" }, 400)
    end

    -- local file_type = data.uploadfile.mime
    local file_name = data.uploadfile.headers.filename
    local file_data = data.uploadfile.data

    local file = io.open("/tmp/" .. file_name, "wb")
    if not file then
        return self.send({ error = "Failed to upload file" }, 500)
    end
    file:write(file_data)
    file:close()

    self.send("File " .. file_name .. " uploaded")
end

return UploadEndpoint
