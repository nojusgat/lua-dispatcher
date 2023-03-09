local DepartmentsGroups = function (sql, Departments, Groups)
    return sql:Table({
        name = "departments_groups",
        columns = {
            {
                name = "id",
                type = "number",
                primary_key = true,
                auto_increment = true
            },
            {
                name = "department_id",
                type = "number",
                nullable = false,
                foreign_key = {
                    table = Departments,
                    delete = "CASCADE"
                }
            },
            {
                name = "group_id",
                type = "number",
                nullable = false,
                foreign_key = {
                    table = Groups,
                    delete = "CASCADE"
                }
            },
        }
    })
end

return DepartmentsGroups