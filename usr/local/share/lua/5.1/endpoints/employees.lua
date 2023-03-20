local BaseEndpoint = require "endpoints.BaseEndpoint"
local EmployeesEndpoint = {}
EmployeesEndpoint.__index = EmployeesEndpoint

setmetatable(EmployeesEndpoint, { __index = BaseEndpoint })

function EmployeesEndpoint:init()
    self:enable_auth("post")
end

function EmployeesEndpoint:get()
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

    local where = {}
    if self.env.query.company_id ~= nil then
        where[prepend_where .. "company_id__in"] = self:query_to_number_table("company_id")
    end
    if self.env.query.office_id ~= nil then
        where[prepend_where .. "office_id__in"] = self:query_to_number_table("office_id")
    end
    if self.env.query.division_id ~= nil then
        where[prepend_where .. "division_id__in"] = self:query_to_number_table("division_id")
    end
    if self.env.query.department_id ~= nil then
        where[prepend_where .. "department_id__in"] = self:query_to_number_table("department_id")
    end
    if self.env.query.group_id ~= nil then
        where[prepend_where .. "group_id__in"] = self:query_to_number_table("group_id")
    end

    if self.env.query.q ~= nil then
        local search = tostring(self.env.query.q)
        where.__or = {}
        where.__or[prepend_where .. "name__like"] = "%" .. search .. "%"
        where.__or[prepend_where .. "surname__like"] = "%" .. search .. "%"
        where.__or[prepend_where .. "position__like"] = "%" .. search .. "%"
        where.__or[prepend_where .. "phone_number__like"] = "%" .. search .. "%"
        where.__or[prepend_where .. "email__like"] = "%" .. search .. "%"
    end

    local pre_results = self.model["Employees"]:get():where(where)

    if expand.company_id then
        pre_results = pre_results:left_join(self.model["Companies"])
    end
    if expand.office_id then
        pre_results = pre_results:left_join(self.model["Offices"])
    end
    if expand.division_id then
        pre_results = pre_results:left_join(self.model["Divisions"])
    end
    if expand.department_id then
        pre_results = pre_results:left_join(self.model["Departments"])
    end
    if expand.group_id then
        pre_results = pre_results:left_join(self.model["Groups"])
    end

    local total_count = pre_results:count()
    local limit, page, total_pages = self:pagination(total_count)

    local offset = (page - 1) * limit
    local results = pre_results:limit(limit):offset(offset):find()

    local formated_results = {}
    for _, value in pairs(results) do
        table.insert(formated_results, value:to_table())
    end

    self.send({ results = formated_results, page = page, total_pages = total_pages, total_results = #results })
end

function EmployeesEndpoint:post()
    self:permission("edit_employees")

    local data = self.body()

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

    if data.photo then
        data.photo = self:upload_image(data.photo)
    end

    local status, results = pcall(function()
        local employee = self.model["Employees"](data)
        employee:save()
        return employee
    end)

    if status == false then
        if data.photo then
            os.remove(self.image_path() .. data.photo)
        end
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send({ result = results:to_table() }, 201)
end

return EmployeesEndpoint
