local model = require "models.config"

local EmployeesEndpoint = {}
EmployeesEndpoint.__index = EmployeesEndpoint

setmetatable(EmployeesEndpoint, { __index = Endpoint })

function EmployeesEndpoint:get()
    local function query_to_number(query, allow_zero_or_less)
        local value
        if string.match(self.env.query[query], "^%d+$") then
            value = tonumber(self.env.query[query])
            if allow_zero_or_less ~= true and value <= 0 then
                self.send({ error = query .. " can not be 0 or less" }, 400)
                os.exit()
            end
        else
            self.send({ error = query .. " is not a valid number" }, 400)
            os.exit()
        end
        return value
    end

    local function query_to_number_table(query, allow_zero_or_less)
        local numbers = {}
        for number in string.gmatch(self.env.query[query], "(%d+),?") do
            local value = tonumber(number)
            table.insert(numbers, value)
            if allow_zero_or_less ~= true and value <= 0 then
                self.send({ error = query .. " can not be 0 or less" }, 400)
                os.exit()
            end
        end
        if #numbers == 0 then
            self.send({ error = query .. " is not a valid number" }, 400)
            os.exit()
        end
        return numbers
    end

    local limit, page = 25, 1
    if self.env.query.limit ~= nil then
        limit = query_to_number("limit", true)
    end
    if self.env.query.page ~= nil then
        page = query_to_number("page")
    end

    local where = {}
    if self.env.query.company ~= nil then
        where["employees.company_id__in"] = query_to_number_table("company")
    end
    if self.env.query.division ~= nil then
        where["employees.division_id__in"] = query_to_number_table("division")
    end
    if self.env.query.department ~= nil then
        where["employees.department_id__in"] = query_to_number_table("department")
    end
    if self.env.query.group ~= nil then
        where["employees.group_id__in"] = query_to_number_table("group")
    end
    if self.env.query.office ~= nil then
        where["employees.office_id__in"] = query_to_number_table("office")
    end

    if self.env.query.q ~= nil then
        local search = tostring(self.env.query.q)
        where.__or = {}
        where.__or["employees.name__like"] = "%" .. search .. "%"
        where.__or["employees.surname__like"] = "%" .. search .. "%"
        where.__or["employees.position__like"] = "%" .. search .. "%"
        where.__or["employees.phone_number__like"] = "%" .. search .. "%"
        where.__or["employees.email__like"] = "%" .. search .. "%"
        where.__or["offices.city__like"] = "%" .. search .. "%"
        where.__or["offices.country__like"] = "%" .. search .. "%"
        where.__or["offices.name__like"] = "%" .. search .. "%"
        where.__or["offices.street__like"] = "%" .. search .. "%"
    end

    local total_count = model["Employees"]:get():where(where):left_join(model["Offices"]):count()
    local total_pages = math.ceil(total_count / limit) > 0 and math.ceil(total_count / limit) or 1
    if limit == 0 then
        total_pages = 1
        page = 1
    end

    if page > total_pages then
        return self.send({ error = "Page does not exist" }, 400)
    end

    local offset = (page - 1) * limit
    local results = model["Employees"]
        :get()
        :where(where)
        :left_join(model["Offices"])
        :limit(limit)
        :offset(offset)
        :find()

    local formated_results = {}
    for _, value in pairs(results) do
        table.insert(formated_results, value:to_table())
    end

    self.send({ results = formated_results, page = page, total_pages = total_pages, total_results = #results })
end

function EmployeesEndpoint:post()
    local data = self.body()

    local status, results = pcall(function()
        local employee = model["Employees"](data)
        employee:save()
        return employee
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end
    self.send(results:to_table(), 201)
end

return EmployeesEndpoint
