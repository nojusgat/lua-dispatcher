local BaseEndpoint = require "endpoints.BaseEndpoint"
local DepartmentGroupEndpoint = {}
DepartmentGroupEndpoint.__index = DepartmentGroupEndpoint

setmetatable(DepartmentGroupEndpoint, { __index = BaseEndpoint })

function DepartmentGroupEndpoint:init()
    self:enable_auth("patch")
    self:enable_auth("delete")
end

function DepartmentGroupEndpoint:get()
    local department_id = tonumber(self.env["%id"][1])
    local group_id = tonumber(self.env["%id"][2])

    local group = self.model["DepartmentsGroups"]
        :get()
        :where({
            ["departments_groups.department_id"] = department_id,
            ["departments_groups.group_id"] = group_id
        })
        :inner_join(self.model["Groups"])
        :find_one()

    if group == nil then
        return self.send({ error = "Department group not found" }, 404)
    end

    self.send({ result = group:to_table().groups })
end

function DepartmentGroupEndpoint:patch()
    self:permission("edit_structure")

    local department_id = tonumber(self.env["%id"][1])
    local group_id = tonumber(self.env["%id"][2])

    local status, results = pcall(function()
        local group = self.model["DepartmentsGroups"]({
            department_id = department_id,
            group_id = group_id
        })
        group:save()
        return group
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send("", 204)
end

function DepartmentGroupEndpoint:delete()
    self:permission("delete_structure")

    local department_id = tonumber(self.env["%id"][1])
    local group_id = tonumber(self.env["%id"][2])

    local group = self.model["DepartmentsGroups"]
        :get()
        :where({
            department_id = department_id,
            group_id = group_id
        })
        :find_one()

    if group == nil then
        return self.send({ error = "Department group not found" }, 404)
    end

    local status, results = pcall(function()
        group:delete()
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send("", 204)
end

return DepartmentGroupEndpoint
