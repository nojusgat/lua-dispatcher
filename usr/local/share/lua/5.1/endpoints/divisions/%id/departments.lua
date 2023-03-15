local BaseEndpoint = require "endpoints.BaseEndpoint"
local DivisionDepartmentsEndpoint = {}
DivisionDepartmentsEndpoint.__index = DivisionDepartmentsEndpoint

setmetatable(DivisionDepartmentsEndpoint, { __index = BaseEndpoint })

function DivisionDepartmentsEndpoint:get()
    local id = tonumber(self.env["%id"][1])
    local where = {
        ["divisions_departments.division_id"] = id
    }

    if self.env.query.q ~= nil then
        local search = tostring(self.env.query.q)
        where["departments.name__like"] = "%" .. search .. "%"
    end

    local total_count = self.model["DivisionsDepartments"]
        :get()
        :where(where)
        :inner_join(self.model["Departments"])
        :count()

    local limit, page, total_pages = self:pagination(total_count)

    local offset = (page - 1) * limit
    local results = self.model["DivisionsDepartments"]
        :get()
        :where(where)
        :limit(limit)
        :offset(offset)
        :inner_join(self.model["Departments"])
        :find()

    local formated_results = {}
    for _, value in pairs(results) do
        table.insert(formated_results, value:to_table().departments)
    end

    self.send({ results = formated_results, page = page, total_pages = total_pages, total_results = #results })
end

return DivisionDepartmentsEndpoint
