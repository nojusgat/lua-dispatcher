local BaseEndpoint = require "endpoints.BaseEndpoint"
local UsersEndpoint = {}
UsersEndpoint.__index = UsersEndpoint

setmetatable(UsersEndpoint, { __index = BaseEndpoint })

function UsersEndpoint:init()
    self:enable_auth("get")
    self:enable_auth("post")
end

function UsersEndpoint:get()
    self:permission("system_admin")

    local where = {}

    if self.env.query.q ~= nil then
        local search = tostring(self.env.query.q)
        where.__or = {}
        where.__or["username__like"] = "%" .. search .. "%"
        where.__or["name__like"] = "%" .. search .. "%"
        where.__or["email__like"] = "%" .. search .. "%"
    end

    local total_count = self.model["Users"]
        :get()
        :where(where)
        :count()

    local limit, page, total_pages = self:pagination(total_count)

    local offset = (page - 1) * limit
    local results = self.model["Users"]
        :get()
        :select({ "id", "username", "name", "email", "avatar" })
        :where(where)
        :limit(limit)
        :offset(offset)
        :find()

    local formated_results = {}
    for _, value in pairs(results) do
        table.insert(formated_results, value:to_table())
    end

    self.send({ results = formated_results, page = page, total_pages = total_pages, total_results = #results })
end

function UsersEndpoint:post()
    self:permission("system_admin")

    local data = self.body()

    if not data then
        return self.send({ error = "Data required" }, 400)
    end

    data.exp = nil
    local password_not_encrypted = string.random(8)
    if data.password then
        if tostring(data.password):len() < 8 then
            return self.send({ error = "Minimum password length is 8 characters" }, 400)
        end
        password_not_encrypted = data.password
    end

    local password, password_salt = self:encrypt_password(password_not_encrypted)
    data.password = password
    data.password_salt = password_salt

    if data.avatar then
        data.avatar = self:upload_image(data.avatar)
    end

    local status, results = pcall(function()
        local user = self.model["Users"](data)
        user:save()
        return user
    end)

    if status == false then
        if data.avatar then
            os.remove(self.image_path() .. data.avatar)
        end
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    local permissions = self.model["UserPermissions"]({
        user_id = results.id,
        edit_employees = false,
        delete_employees = false,
        edit_companies = false,
        delete_companies = false,
        edit_offices = false,
        delete_offices = false,
        edit_structure = false,
        delete_structure = false,
        read_permissions = false,
        edit_permissions = false
    })
    permissions:save()

    results = results:to_table()
    results.password = password_not_encrypted
    results.password_salt = nil

    self.send({ result = results }, 201)
end

return UsersEndpoint
