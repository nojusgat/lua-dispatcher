local BaseEndpoint = require "endpoints.BaseEndpoint"
local CompanyOfficesEndpoint = {}
CompanyOfficesEndpoint.__index = CompanyOfficesEndpoint

setmetatable(CompanyOfficesEndpoint, { __index = BaseEndpoint })

function CompanyOfficesEndpoint:get()
    local id = tonumber(self.env["%id"][1])
    local where = {
        ["companies_offices.company_id"] = id
    }

    if self.env.query.q ~= nil then
        local search = tostring(self.env.query.q)
        where.__or = {}
        where.__or["offices.name__like"] = "%" .. search .. "%"
        where.__or["offices.street__like"] = "%" .. search .. "%"
        where.__or["offices.street_number__like"] = "%" .. search .. "%"
        where.__or["offices.city__like"] = "%" .. search .. "%"
        where.__or["offices.country__like"] = "%" .. search .. "%"
    end

    local total_count = self.model["CompaniesOffices"]
        :get()
        :where(where)
        :inner_join(self.model["Offices"])
        :count()

    local limit, page, total_pages = self:pagination(total_count)

    local offset = (page - 1) * limit
    local results = self.model["CompaniesOffices"]
        :get()
        :where(where)
        :limit(limit)
        :offset(offset)
        :inner_join(self.model["Offices"])
        :find()

    local formated_results = {}
    for _, value in pairs(results) do
        table.insert(formated_results, value:to_table().offices)
    end

    self.send({ results = formated_results, page = page, total_pages = total_pages, total_results = #results })
end

return CompanyOfficesEndpoint
