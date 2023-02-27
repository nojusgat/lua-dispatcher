local M = {}

M.path = "test/123"

function M.handle(send, query)
    send("test", 200)
end

return M