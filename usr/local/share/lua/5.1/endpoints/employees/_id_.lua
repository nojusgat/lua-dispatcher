local model = require "models.config"

local EmployeeEndpoint = {}
EmployeeEndpoint.__index = EmployeeEndpoint

setmetatable(EmployeeEndpoint, { __index = Endpoint })

function EmployeeEndpoint:get()
    local id = tonumber(self.env._id_[1])

    local employee = model["Employees"]
        :get()
        :where({ ["employees.id"] = id })
        :left_join(model["Companies"])
        :left_join(model["Offices"])
        :left_join(model["Divisions"])
        :left_join(model["Departments"])
        :left_join(model["Groups"])
        :find_one()

    if employee == nil then
        return self.send({ error = "Id not found" }, 404)
    end
    self.send(employee:to_table())
end

return EmployeeEndpoint