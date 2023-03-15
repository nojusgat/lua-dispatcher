local BaseEndpoint = require "endpoints.BaseEndpoint"
local EmployeeEndpoint = {}
EmployeeEndpoint.__index = EmployeeEndpoint

setmetatable(EmployeeEndpoint, { __index = BaseEndpoint })

function EmployeeEndpoint:init()
    self:enable_auth("patch")
    self:enable_auth("delete")
end

function EmployeeEndpoint:get()
    local id = tonumber(self.env["%id"][1])
    local expand = {}
    if self.env.query.expand ~= nil then
        expand = self:query_to_string_table("expand", {
            company_id = true,
            office_id = true,
            division_id = true,
            department_id = true,
            group_id = true
        })
    end

    local prepend_where = ""
    if expand.__n and expand.__n > 0 then
        prepend_where = "employees."
    end

    local pre_employee = self.model["Employees"]
        :get()
        :where({ [prepend_where .. "id"] = id })

    if expand.company_id then
        pre_employee = pre_employee:left_join(self.model["Companies"])
    end
    if expand.office_id then
        pre_employee = pre_employee:left_join(self.model["Offices"])
    end
    if expand.division_id then
        pre_employee = pre_employee:left_join(self.model["Divisions"])
    end
    if expand.department_id then
        pre_employee = pre_employee:left_join(self.model["Departments"])
    end
    if expand.group_id then
        pre_employee = pre_employee:left_join(self.model["Groups"])
    end

    local employee = pre_employee:find_one()

    if employee == nil then
        return self.send({ error = "Employee not found" }, 404)
    end

    self.send({ result = employee:to_table() })
end

function EmployeeEndpoint:patch()
    self:permission("edit_employees")

    local id = tonumber(self.env["%id"][1])
    local data = self.body()

    local employee = self.model["Employees"]
        :get()
        :where({ id = id })
        :find_one()

    if employee == nil then
        return self.send({ error = "Employee not found" }, 404)
    end

    if not data then
        return self.send({ error = "Data required" }, 400)
    end

    if tonumber(data.company_id) and tonumber(data.office_id) then
        local company_office = self.model["CompaniesOffices"]:get():where({
            company_id = data.company_id,
            office_id = data.office_id
        }):find_one()

        if not company_office then
            return self.send({ error = "Company does not have the provided office" }, 400)
        end
    end

    if tonumber(data.office_id) and tonumber(data.division_id) then
        local office_division = self.model["OfficesDivisions"]:get():where({
            office_id = data.office_id,
            division_id = data.division_id
        }):find_one()

        if not office_division then
            return self.send({ error = "Office does not have the provided division" }, 400)
        end
    end

    if tonumber(data.division_id) and tonumber(data.department_id) then
        local division_department = self.model["DivisionsDepartments"]:get():where({
            division_id = data.division_id,
            department_id = data.department_id
        }):find_one()

        if not division_department then
            return self.send({ error = "Division does not have the provided department" }, 400)
        end
    end

    if tonumber(data.department_id) and tonumber(data.group_id) then
        local department_group = self.model["DepartmentsGroups"]:get():where({
            department_id = data.department_id,
            group_id = data.group_id
        }):find_one()

        if not department_group then
            return self.send({ error = "Department does not have the provided group" }, 400)
        end
    end

    local last_photo = nil
    if data.photo then
        if data.photo ~= cjson.null and data.photo ~= "" then
            data.photo = self:upload_image(data.photo)
        end
        last_photo = employee.photo
    end

    local status, results = pcall(function()
        for key, value in pairs(data) do
            if value == cjson.null then value = nil end
            if value == "" then value = nil end
            employee[key] = value
        end
        employee:save()
    end)

    if status == false then
        if data.photo then
            os.remove(self.image_path .. data.photo)
        end
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    if last_photo then
        os.remove(self.image_path .. last_photo)
    end

    self.send("", 204)
end

function EmployeeEndpoint:delete()
    self:permission("delete_employees")

    local id = tonumber(self.env["%id"][1])
    local employee = self.model["Employees"]
        :get()
        :where({ id = id })
        :find_one()

    if employee == nil then
        return self.send({ error = "Employee not found" }, 404)
    end

    if employee.photo then
        os.remove(self.image_path .. employee.photo)
    end

    local status, results = pcall(function()
        employee:delete()
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send("", 204)
end

return EmployeeEndpoint
