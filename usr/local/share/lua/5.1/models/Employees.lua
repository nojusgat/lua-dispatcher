local Employees = function (sql, Companies, Offices, Divisions, Departments, Groups)
    return sql:Table({
        name = "employees",
        columns = {
            {
                name = "id",
                type = "number",
                primary_key = true,
                auto_increment = true
            },
            {
                name = "name",
                type = "string",
                nullable = false
            },
            {
                name = "surname",
                type = "string",
                nullable = false
            },
            {
                name = "email",
                type = "string",
                nullable = false
            },
            {
                name = "phone_number",
                type = "string"
            },
            {
                name = "position",
                type = "string",
                nullable = false
            },
            {
                name = "company_id",
                type = "number",
                nullable = false,
                foreign_key = {
                    table = Companies,
                }
            },
            {
                name = "office_id",
                type = "number",
                nullable = false,
                foreign_key = {
                    table = Offices,
                }
            },
            {
                name = "division_id",
                type = "number",
                nullable = false,
                foreign_key = {
                    table = Divisions,
                }
            },
            {
                name = "department_id",
                type = "number",
                foreign_key = {
                    table = Departments,
                }
            },
            {
                name = "group_id",
                type = "number",
                foreign_key = {
                    table = Groups,
                }
            },
            {
                name = "photo_path",
                type = "string"
            },
        },
        -- drop_existing = true
    })
end

return Employees