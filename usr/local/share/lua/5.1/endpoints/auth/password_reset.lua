local BaseEndpoint = require "endpoints.BaseEndpoint"
local PasswordResetEndpoint = {}
PasswordResetEndpoint.__index = PasswordResetEndpoint

setmetatable(PasswordResetEndpoint, {
    __index = BaseEndpoint
})

function PasswordResetEndpoint:post()
    local data = self.body()

    if not data then
        return self.send({
            error = "Data required"
        }, 400)
    end

    if not data.email or type(data.email) ~= "string" or data.email == "" then
        return self.send({
            error = "Email is required"
        }, 400)
    end

    if not string.match(data.email, "^[%w._]+@%w+%.[%a.]+$") then
        return self.send({
            error = "Email address is not valid"
        }, 400)
    end

    local user = self.model["Users"]:get():where({
        email = data.email
    }):find_one()

    if user == nil then
        return self.send({
            error = "Email does not exist"
        }, 400)
    end

    local resetCode = self.model["UserPasswordReset"]:get():where({ user_id = user.id}):find_one()
    if resetCode ~= nil then
        resetCode:delete()
    end

    local randomCode = string.random(12, {{48, 57}})
    resetCode = self.model["UserPasswordReset"]({
        user_id = user.id,
        code = randomCode,
        expire = os.time() + 3600
    })

    local email_config = UCIOrm:init("rest_api", "email")
    local email = self.email_client()
        :from(email_config:get("email"), email_config:get("name"))
        :to(user.email)
        :subject("Password Reset Request")
        :plain_body("Hi " .. (user.name or user.username) .. ",\n\n" .. "We've received a request to reset your password.\n\n" ..
                    "If you did not make the request, just ignore this message. Otherwise, you can reset your password.\n\n" ..
                    "Your password reset code is:\n" .. randomCode .. "\n\n" .. "Thanks,\n" .. email_config:get("name"))

    local status, err = email:send()
    if status == false then
        return self.send({
            error = "Failed to send email error " .. err:no()
        }, 500)
    end

    resetCode:save()

    self.send({
        result = "Email sent! Check your email for a password reset code"
    })
end

function PasswordResetEndpoint:patch()
    local data = self.body()

    if not data then
        return self.send({
            error = "Data required"
        }, 400)
    end

    if not data.code or not tonumber(data.code) then
        return self.send({
            error = "Code is required"
        }, 400)
    end

    local resetCode = self.model["UserPasswordReset"]
        :get()
        :inner_join(self.model["Users"])
        :where({ ["user_password_reset.code"] = tonumber(data.code) })
        :find_one()

    if resetCode == nil then
        return self.send({
            error = "Invalid code"
        }, 400)
    end

    if resetCode.expire <= os.time() then
        return self.send({
            error = "Code is expired"
        }, 400)
    end

    if not data.password or type(data.password) ~= "string" or data.password == "" then
        return self.send({
            error = "Password is required"
        }, 400)
    end

    if data.password:len() < 8 then
        return self.send({
            error = "Minimum password length is 8 characters"
        }, 400)
    end

    local password, password_salt = self:encrypt_password(data.password)
    resetCode.users.password = password
    resetCode.users.password_salt = password_salt
    resetCode.users:save()
    resetCode:delete()

    self.send({ result = "Password changed" })
end

return PasswordResetEndpoint
