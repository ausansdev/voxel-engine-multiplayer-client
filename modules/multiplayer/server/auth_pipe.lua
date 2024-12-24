local Pipeline = require "lib/pipeline"
local Proto = require "multiplayer/proto/core"
local session = require "multiplayer/global"
local ConnectionMessage = require "multiplayer/messages/connection"

local AuthPipe = Pipeline.new()

---Проверка никнейма на уникальность
---@param username string Никнейм
---@return boolean 
local function unique_username(username)
    for index, client in ipairs(session.server.clients) do
        if client.username == username then
            return false
        end
    end
    return true
end

AuthPipe:add_middleware(function(message)
    local client = message.__client
    local network = message.__network

    return message
end)

AuthPipe:add_middleware(function(message)
    local client = message.__client
    local network = message.__network
    local event = message.event
    local payload = event.payload

    if payload.Connect then
        local hasUsername = payload.Connect.username ~= nil
        local uniqueUsername = unique_username(payload.Connect.username)
        local checkVersion = payload.Connect.version == "0.25.3"
        local accept = hasUsername and uniqueUsername and checkVersion

        if accept then
            local Accept = ConnectionMessage.ConnectionAccepted.new(event.request_uuid)
            console.log(payload.Connect.username.." присоединился к игре")
            session.server:queue_response(Accept)

            return {true, payload.Connect.username}
        else
            local Reject = ConnectionMessage.ConnectionRejected.new(event.request_uuid, "unknown error")

            if not hasUsername then Reject = ConnectionMessage.ConnectionRejected.new("username has'nt be empty")
            elseif not uniqueUsername then Reject = ConnectionMessage.ConnectionRejected.new("player with this username already logged in")
            elseif not checkVersion then Reject = ConnectionMessage.ConnectionRejected.new("game version not approved")
            end

            console.log("Подключение отвергнуто: ",Reject.payload.ConnectionRejected)
            session.server:queue_response(Reject)

            return {false}
        end
    end

    return {false}
end)

return AuthPipe
