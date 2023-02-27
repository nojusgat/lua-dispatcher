local M = {}

M.path = "hello"

function M.handle(send, query)
    send({
        text = "Hello World",
        query = query
    }, 200)
end

return M