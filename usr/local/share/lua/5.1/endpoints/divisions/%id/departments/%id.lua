local BaseEndpoint = require "endpoints.BaseEndpoint"
local DivisionDepartmentEndpoint = {}
DivisionDepartmentEndpoint.__index = DivisionDepartmentEndpoint

setmetatable(DivisionDepartmentEndpoint, { __index = BaseEndpoint })

function DivisionDepartmentEndpoint:init()
    self:enable_auth("patch")
    self:enable_auth("delete")
end

function DivisionDepartmentEndpoint:get()
    local division_id = tonumber(self.env["%id"][1])
    local department_id = tonumber(self.env["%id"][2])

    local department = self.model["DivisionsDepartments"]
        :get()
        :where({
            ["divisions_departments.division_id"] = division_id,
            ["divisions_departments.department_id"] = department_id
        })
        :inner_join(self.model["Departments"])
        :find_one()

    if department == nil then
        return self.send({ error = "Division department not found" }, 404)
    end

    self.send({ result = department:to_table().departments })
end

function DivisionDepartmentEndpoint:patch()
    self:permission("edit_structure")

    local division_id = tonumber(self.env["%id"][1])
    local department_id = tonumber(self.env["%id"][2])

    local status, results = pcall(function()
        local department = self.model["DivisionsDepartments"]({
            division_id = division_id,
            department_id = department_id
        })
        department:save()
        return department
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send("", 204)
end

function DivisionDepartmentEndpoint:delete()
    self:permission("delete_structure")

    local division_id = tonumber(self.env["%id"][1])
    local department_id = tonumber(self.env["%id"][2])

    local department = self.model["DivisionsDepartments"]
        :get()
        :where({
            division_id = division_id,
            department_id = department_id
        })
        :find_one()

    if department == nil then
        return self.send({ error = "Division department not found" }, 404)
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

return DivisionDepartmentEndpoint
