local Email = require "emailclient.email"
local EmailClient = {}

function EmailClient:new(config)
    local instance = setmetatable({}, {
        __index = EmailClient,
        __call = EmailClient.email
    })
    assert(type(config) == "table", "Email client config must be a table")
    assert(type(config.smtp) == "string", "You must provide smtp server url")
    assert(type(config.username) == "string", "You must provide smtp username")
    assert(type(config.password) == "string", "You must provide smtp password")
    instance.smtp = config.smtp
    instance.username = config.username
    instance.password = config.password
    return instance
end

function EmailClient:email()
    return Email(self)
end

setmetatable(EmailClient, {
    __call = EmailClient.new
})
return EmailClient
