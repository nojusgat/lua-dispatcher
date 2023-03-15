local BaseEndpoint = require "endpoints.BaseEndpoint"
local CompanyOfficeEndpoint = {}
CompanyOfficeEndpoint.__index = CompanyOfficeEndpoint

setmetatable(CompanyOfficeEndpoint, { __index = BaseEndpoint })

function CompanyOfficeEndpoint:init()
    self:enable_auth("patch")
    self:enable_auth("delete")
end

function CompanyOfficeEndpoint:get()
    local company_id = tonumber(self.env["%id"][1])
    local office_id = tonumber(self.env["%id"][2])

    local office = self.model["CompaniesOffices"]
        :get()
        :where({
            ["companies_offices.company_id"] = company_id,
            ["companies_offices.office_id"] = office_id
        })
        :inner_join(self.model["Offices"])
        :find_one()

    if office == nil then
        return self.send({ error = "Company office not found" }, 404)
    end

    self.send({ result = office:to_table().offices })
end

function CompanyOfficeEndpoint:patch()
    self:permission("edit_structure")

    local company_id = tonumber(self.env["%id"][1])
    local office_id = tonumber(self.env["%id"][2])

    local status, results = pcall(function()
        local office = self.model["CompaniesOffices"]({
            company_id = company_id,
            office_id = office_id
        })
        office:save()
        return office
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send("", 204)
end

function CompanyOfficeEndpoint:delete()
    self:permission("delete_structure")

    local company_id = tonumber(self.env["%id"][1])
    local office_id = tonumber(self.env["%id"][2])

    local office = self.model["CompaniesOffices"]
        :get()
        :where({ company_id = company_id, office_id = office_id })
        :find_one()

    if office == nil then
        return self.send({ error = "Company office not found" }, 404)
    end

    local status, results = pcall(function()
        office:delete()
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send("", 204)
end

return CompanyOfficeEndpoint
