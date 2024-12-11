local socketlib = require "lib/socketlib"
local session = require "multiplayer/global"
local command = require "multiplayer/console"
local uuid    = require "lib/uuid"

function on_world_tick()
    if session.client then
        session.client:world_tick()
    end

    if session.server then
        session.server:tick()
    end

    print( uuid.getUUID() )
end

function on_player_tick(playerid)
    if session.client then
        session.client:player_tick(playerid)
    end
end

function on_world_quit()
    if session.client then
        session.client:disconnect()
    end
end

function on_block_placed(blockid, x, y, z, playerid)
    
end

function on_block_replaced(blockid, x, y, z, playerid)
    
end

function on_block_broken(blockid, x, y, z, playerid)
    
end