local BaseEndpoint = require "endpoints.BaseEndpoint"
local OfficeDivisionEndpoint = {}
OfficeDivisionEndpoint.__index = OfficeDivisionEndpoint

setmetatable(OfficeDivisionEndpoint, { __index = BaseEndpoint })

function OfficeDivisionEndpoint:init()
    self:enable_auth("patch")
    self:enable_auth("delete")
end

function OfficeDivisionEndpoint:get()
    local office_id = tonumber(self.env["%id"][1])
    local division_id = tonumber(self.env["%id"][2])

    local division = self.model["OfficesDivisions"]
        :get()
        :where({
            ["offices_divisions.office_id"] = office_id,
            ["offices_divisions.division_id"] = division_id
        })
        :inner_join(self.model["Divisions"])
        :find_one()

    if division == nil then
        return self.send({ error = "Office division not found" }, 404)
    end

    self.send({ result = division:to_table().divisions })
end

function OfficeDivisionEndpoint:patch()
    self:permission("edit_structure")

    local office_id = tonumber(self.env["%id"][1])
    local division_id = tonumber(self.env["%id"][2])

    local status, results = pcall(function()
        local division = self.model["OfficesDivisions"]({
            office_id = office_id,
            division_id = division_id
        })
        division:save()
        return division
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send("", 204)
end

function OfficeDivisionEndpoint:delete()
    self:permission("delete_structure")

    local office_id = tonumber(self.env["%id"][1])
    local division_id = tonumber(self.env["%id"][2])

    local division = self.model["OfficesDivisions"]
        :get()
        :where({
            office_id = office_id,
            division_id = division_id
        })
        :find_one()

    if division == nil then
        return self.send({ error = "Office division not found" }, 404)
    end

    local status, results = pcall(function()
        division:delete()
    end)

    if status == false then
        local error = string.match(results, ": (.+)$")
        return self.send({ error = error }, 400)
    end

    self.send("", 204)
end

return OfficeDivisionEndpoint
