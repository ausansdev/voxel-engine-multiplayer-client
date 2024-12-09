local Pipeline = require "lib/pipeline"
local Proto = require "multiplayer/proto/core"
local CommandMessage = require "multiplayer/messages/command"
local session = require "multiplayer/global"
local Network = require "lib/network"

local AuthPipe = require "multiplayer/server/auth_pipe"

local ServerPipe = Pipeline.new()
local network = nil
local client = nil

ServerPipe:add_middleware(function(_client)
    client = _client
    network = Network.new(_client.socket)
    local data = Proto.recv_text(network)
    if data then
        if pcall(function()
            json.parse(data)
        end) then

            local message = json.parse(data)
            if message then
                return message
            end
        end
    end

    return nil
end)

ServerPipe:add_middleware(function(message)
    if message.Close then
        if network then
            network:disconnect()
            table.remove_value(session.server.clients, client)
            return nil
        end
    end

    return message
end)

ServerPipe:add_middleware(function(message)

    local status, client_id, username = unpack(AuthPipe:process({network, message}) or {false})

    if status then
        client.active = true
        client.username = username
        client.client_id = client_id
    end

    return message
end)


ServerPipe:add_middleware(function(message)

    if client.active then
        return message
    end

    return nil
end)

ServerPipe:add_middleware(function(message)
    if message.Status then
        Proto.send_text(network, CommandMessage.StatusResponse.new())
    elseif message.Players then
        Proto.send_text(network, CommandMessage.PlayersResponse.new(session.server.clients))
    end

    return message
end)

ServerPipe:add_middleware(function(message)
    if message.PlayerPosition then
        Proto.send_text(network, json.tostring({
            EventPool = {
                {
                    PlayerMoved = {
                        client_id = client.client_id,
                        x = message.PlayerPosition.x,
                        y = message.PlayerPosition.y,
                        z = message.PlayerPosition.z,
                        yaw = message.PlayerPosition.yaw,
                        pitch = message.PlayerPosition.pitch,
                    }
                }
            }
        }))
    end

    return message
end)

return ServerPipe
