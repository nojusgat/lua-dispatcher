local model = require "models.config"
local digest = require "openssl.digest"

function string.random(chars, sets)
    if not sets then
        sets = {{97, 122}, {65, 90}, {48, 57}, {35, 38}}
    end
    local str = ""
    for i = 1, chars do
        math.randomseed(os.clock() ^ -5)
        local charset = sets[math.random(1, #sets)]
        str = str .. string.char(math.random(charset[1], charset[2]))
    end
    return str
end

function string.fromhex(str)
    return (str:gsub('..', function(cc)
        return string.char(tonumber(cc, 16))
    end))
end

function string.tohex(str)
    return (str:gsub('.', function(c)
        return string.format('%02X', string.byte(c))
    end))
end

local BaseEndpoint = {}
BaseEndpoint.__index = BaseEndpoint

setmetatable(BaseEndpoint, {
    __index = Endpoint
})

BaseEndpoint.model = model
BaseEndpoint.image_path = "/www/images/"

BaseEndpoint.email_client = require "emailclient"({
    smtp = "smtps://smtp.gmail.com:465",
    username = "",
    password = ""
})

function BaseEndpoint:query_to_number(query, allow_zero_or_less)
    local value
    if string.match(self.env.query[query], "^%d+$") then
        value = tonumber(self.env.query[query])
        if allow_zero_or_less ~= true and value <= 0 then
            self.send({
                error = query .. " can not be 0 or less"
            }, 400)
            os.exit()
        end
    else
        self.send({
            error = query .. " is not a valid number"
        }, 400)
        os.exit()
    end
    return value
end

function BaseEndpoint:query_to_number_table(query, allow_zero_or_less)
    local numbers = {}
    for number in string.gmatch(self.env.query[query], "(%d+),?") do
        local value = tonumber(number)
        table.insert(numbers, value)
        if allow_zero_or_less ~= true and value <= 0 then
            self.send({
                error = query .. " can not be 0 or less"
            }, 400)
            os.exit()
        end
    end
    if #numbers == 0 then
        self.send({
            error = query .. " is not a valid number"
        }, 400)
        os.exit()
    end
    return numbers
end

function BaseEndpoint:query_to_string_table(query, allowed)
    if not allowed then
        allowed = {}
    end
    local strings = {}
    local counter = 0
    for value in string.gmatch(self.env.query[query], "([^,]+),?") do
        if allowed[value] then
            strings[value] = true
            counter = counter + 1
        end
    end
    if counter == 0 then
        self.send({
            error = query .. " is not a valid query"
        }, 400)
        os.exit()
    end
    strings["__n"] = counter
    return strings
end

function BaseEndpoint:pagination(total_count, limit)
    local page = 1

    if not total_count or type(total_count) ~= "number" then
        total_count = 0
    end
    if not limit or type(limit) ~= "number" then
        limit = 25
    end

    if self.env.query.limit ~= nil then
        limit = self:query_to_number("limit", true)
    end
    if self.env.query.page ~= nil then
        page = self:query_to_number("page")
    end

    local total_pages = math.ceil(total_count / limit) > 0 and math.ceil(total_count / limit) or 1
    if limit == 0 then
        total_pages = 1
        page = 1
    end

    if page > total_pages then
        self.send({
            error = "Page does not exist"
        }, 400)
        os.exit()
    end

    return limit, page, total_pages
end

function BaseEndpoint:upload_image(image)
    if type(image) ~= "table" or not image.data or not image.filename or not image.mime then
        self.send({
            error = "Avatar should be a file"
        }, 400)
        os.exit()
    end

    local allowed_mime_types = {
        ["image/jpeg"] = "jpg",
        ["image/png"] = "png",
        ["image/webp"] = "webp"
    }

    local file_type = image.mime
    if not allowed_mime_types[file_type] then
        self.send({
            error = "File format not accepted"
        }, 400)
        os.exit()
    end

    local random_string = string.random("5", {{97, 122}, {65, 90}, {48, 57}})
    local file_name = random_string .. "_" .. os.time() .. "." .. allowed_mime_types[file_type]

    local file = io.open(self.image_path .. file_name, "wb")
    if not file then
        self.send({
            error = "Failed to upload file"
        }, 500)
        os.exit()
    end
    file:write(image.data)
    file:close()

    return file_name
end

function BaseEndpoint:encrypt_password(plain_text, salt)
    salt = salt or string.random(32)
    local password = digest.new("sha256"):final(salt .. plain_text)
    password = string.tohex(password)
    password = string.lower(password)
    return password, salt
end

function BaseEndpoint:permission(permission)
    if permission == "system_admin" then
        if self.auth_data.user.system_admin ~= true then
            self.send({
                error = "Permission denied"
            }, 403)
            os.exit()
        end
        return
    end
    if self.auth_data.user.permissions[permission] ~= true then
        self.send({
            error = "Permission denied"
        }, 403)
        os.exit()
    end
end

function BaseEndpoint:authorize()
    local id = tonumber(self.auth_data.user.id)

    local user = model["Users"]:get():select({"id", "username", "name", "email", "avatar", "system_admin", "exp"})
        :where({
            id = id
        }):find_one()

    if user == nil or tostring(user.exp) ~= tostring(self.auth_data.exp) then
        return false
    end

    self.auth_data.user_model = user

    local permissions = model["UserPermissions"]:get():where({
        user_id = user.id
    }):find_one()

    if permissions then
        permissions = permissions:to_table()
        permissions.user_id = nil
    end

    user = user:to_table()
    user.permissions = permissions or {}
    user.exp = nil

    self.auth_data.user = user

    return true
end

return BaseEndpoint
