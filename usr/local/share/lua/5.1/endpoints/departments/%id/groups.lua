local BaseEndpoint = require "endpoints.BaseEndpoint"
local DepartmentGroupsEndpoint = {}
DepartmentGroupsEndpoint.__index = DepartmentGroupsEndpoint

setmetatable(DepartmentGroupsEndpoint, { __index = BaseEndpoint })

function DepartmentGroupsEndpoint:get()
    local id = tonumber(self.env["%id"][1])
    local where = {
        ["departments_groups.department_id"] = id
    }

    if self.env.query.q ~= nil then
        local search = tostring(self.env.query.q)
        where["groups.name__like"] = "%" .. search .. "%"
    end

    local total_count = self.model["DepartmentsGroups"]
        :get()
        :where(where)
        :inner_join(self.model["Groups"])
        :count()

    local limit, page, total_pages = self:pagination(total_count)

    local offset = (page - 1) * limit
    local results = self.model["DepartmentsGroups"]
        :get()
        :where(where)
        :limit(limit)
        :offset(offset)
        :inner_join(self.model["Groups"])
        :find()

    local formated_results = {}
    for _, value in pairs(results) do
        table.insert(formated_results, value:to_table().groups)
    end

    self.send({ results = formated_results, page = page, total_pages = total_pages, total_results = #results })
end

return DepartmentGroupsEndpoint
