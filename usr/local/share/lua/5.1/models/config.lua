local sqlite = require "sqliteorm.instance"
local sql = sqlite("database.db", {
    foreign_keys = true
})

local UserPermissions = require "models.UserPermissions"
local Users = require "models.Users"
local Companies = require "models.Companies"
local Offices = require "models.Offices"
local Departments = require "models.Departments"
local Divisions = require "models.Divisions"
local Groups = require "models.Groups"
local Employees = require "models.Employees"
local CompaniesOffices = require "models.CompaniesOffices"
local DepartmentsGroups = require "models.DepartmentsGroups"
local DivisionsDepartments = require "models.DivisionsDepartments"
local OfficesDivisions = require "models.OfficesDivisions"

local config = {}
config["Users"] = Users(sql)
config["UserPermissions"] = UserPermissions(sql, config["Users"])
config["Companies"] = Companies(sql)
config["Offices"] = Offices(sql)
config["Departments"] = Departments(sql)
config["Divisions"] = Divisions(sql)
config["Groups"] = Groups(sql)
config["Employees"] = Employees(sql, config["Companies"], config["Offices"], config["Divisions"], config["Departments"], config["Groups"])
config["CompaniesOffices"] = CompaniesOffices(sql, config["Companies"], config["Offices"])
config["DepartmentsGroups"] = DepartmentsGroups(sql, config["Departments"], config["Groups"])
config["DivisionsDepartments"] = DivisionsDepartments(sql, config["Divisions"], config["Departments"])
config["OfficesDivisions"] = OfficesDivisions(sql, config["Offices"], config["Divisions"])

return config, sql
