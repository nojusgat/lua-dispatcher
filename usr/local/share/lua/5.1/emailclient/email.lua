local curl = require "lcurl.safe"
local Email = {}

function Email:new(client)
    local instance = setmetatable({}, {
        __index = Email
    })
    assert(type(client) == "table", "Email client must be provided")
    instance.parent = client
    instance.email_from = nil
    instance.name_from = ""
    instance.email_to = nil
    instance.subject_text = nil
    instance.html = nil
    instance.plain = nil
    return instance
end

function Email:from(email, name)
    assert(type(email) == "string", "Invalid from email")
    assert(string.match(email, "^[%w._]+@%w+%.[%a.]+$"), "Invalid from email")
    self.email_from = "<" .. email .. ">"
    if name ~= nil and type(name) == "string" then
        self.name_from = " (" .. name .. ")"
    end
    return self
end

function Email:to(email)
    assert(type(email) == "string", "Invalid to email")
    assert(string.match(email, "^[%w._]+@%w+%.[%a.]+$"), "Invalid to email")
    self.email_to = "<" .. email .. ">"
    return self
end

function Email:subject(text)
    assert(type(text) == "string", "Invalid subject")
    self.subject_text = text
    return self
end

function Email:html_body(text)
    assert(type(text) == "string", "Invalid HTML Body")
    self.html = text
    return self
end

function Email:plain_body(text)
    assert(type(text) == "string", "Invalid Plain text body")
    self.plain = text
    return self
end

function Email:send()
    assert(type(self.email_from) == "string", "Please provide sender email address")
    assert(type(self.email_to) == "string", "Please provide receiver email address")
    assert(type(self.subject_text) == "string", "Please provide subject")

    local headers = {"To: " .. self.email_to, "From: " .. self.email_from .. self.name_from,
                     "Subject: " .. self.subject_text}

    local easy = curl.easy()
    local mime = easy:mime()
    do
        local alt = easy:mime()
        if self.html then
            alt:addpart():data(self.html, "text/html")
        end
        if self.plain then
            alt:addpart():data(self.plain)
        end
        assert(self.html or self.plain, "Please provide either a plain text body or an html body")
        mime:addpart():subparts(alt, "multipart/alternative", {"Content-Disposition: inline"})
    end

    local _, err = easy:setopt{
        url = self.parent.smtp,
        mail_from = self.email_from,
        mail_rcpt = {self.email_to},
        httpheader = headers,
        mimepost = mime,
        ssl_verifyhost = false,
        ssl_verifypeer = false,
        username = self.parent.username,
        password = self.parent.password
    }
    if err then
        easy:close()
        mime:free()
        return false, err
    end
    _, err = easy:perform()
    if err then
        easy:close()
        mime:free()
        return false, err
    end

    return true, nil
end

setmetatable(Email, {
    __call = Email.new
})
return Email
