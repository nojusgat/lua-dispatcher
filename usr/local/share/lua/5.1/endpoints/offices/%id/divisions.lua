local BaseEndpoint = require "endpoints.BaseEndpoint"
local OfficeDivisionsEndpoint = {}
OfficeDivisionsEndpoint.__index = OfficeDivisionsEndpoint

setmetatable(OfficeDivisionsEndpoint, { __index = BaseEndpoint })

function OfficeDivisionsEndpoint:get()
    local id = tonumber(self.env["%id"][1])
    local where = {
        ["offices_divisions.office_id"] = id
    }

    if self.env.query.q ~= nil then
        local search = tostring(self.env.query.q)
        where["divisions.name__like"] = "%" .. search .. "%"
    end

    local total_count = self.model["OfficesDivisions"]
        :get()
        :where(where)
        :inner_join(self.model["Divisions"])
        :count()

    local limit, page, total_pages = self:pagination(total_count)

    local offset = (page - 1) * limit
    local results = self.model["OfficesDivisions"]
        :get()
        :where(where)
        :limit(limit)
        :offset(offset)
        :inner_join(self.model["Divisions"])
        :find()

    local formated_results = {}
    for _, value in pairs(results) do
        table.insert(formated_results, value:to_table().divisions)
    end

    self.send({ results = formated_results, page = page, total_pages = total_pages, total_results = #results })
end

return OfficeDivisionsEndpoint
