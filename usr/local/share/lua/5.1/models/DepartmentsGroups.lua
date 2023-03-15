local DepartmentsGroups = function (sql, Departments, Groups)
    return sql:Table({
        name = "departments_groups",
        columns = {
            {
                name = "department_id",
                type = "number",
                nullable = false,
                primary_key = true,
                foreign_key = {
                    table = Departments,
                    delete = "CASCADE"
                }
            },
            {
                name = "group_id",
                type = "number",
                nullable = false,
                primary_key = true,
                foreign_key = {
                    table = Groups,
                    delete = "CASCADE"
                }
            },
        }
    })
end

return DepartmentsGroups