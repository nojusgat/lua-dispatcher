local BaseEndpoint = require "endpoints.BaseEndpoint"
local DepartmentEndpoint = {}
DepartmentEndpoint.__index = DepartmentEndpoint

setmetatable(DepartmentEndpoint, { __index = BaseEndpoint })

function DepartmentEndpoint:init()
    self:enable_auth("patch")
    self:enable_auth("delete")
end

function DepartmentEndpoint:get()
    local id = tonumber(self.env["%id"][1])

    local department = self.model["Departments"]
        :get()
        :where({ id = id })
        :find_one()

    if department == nil then
        return self.send({ error = "Department not found" }, 404)
    end

    self.send({ result = department:to_table() })
end

function DepartmentEndpoint:patch()
    self:permission("edit_structure")

    local id = tonumber(self.env["%id"][1])
    local data = self.body()

    local department = self.model["Departments"]
        :get()
        :where({ id = id })
        :find_one()

    if department == nil then
        return self.send({ error = "Department not found" }, 404)
    end

    if not data then
        return self.send({ error = "Data required" }, 400)
    end

    local status, results = pcall(function()
        for key, value in pairs(data) do
            if value == cjson.null then value = nil end
            if value == "" then value = nil end
            department[key] = value
        end
        department:save()
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send("", 204)
end

function DepartmentEndpoint:delete()
    self:permission("delete_structure")

    local id = tonumber(self.env["%id"][1])

    local department = self.model["Departments"]
        :get()
        :where({ id = id })
        :find_one()

    if department == nil then
        return self.send({ error = "Division not found" }, 404)
    end

    local status, results = pcall(function()
        department:delete()
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send("", 204)
end

return DepartmentEndpoint
