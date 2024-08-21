-- LocalNWVar - Allowing you to use NWVars but local to a player
-- You can use this library for variables you want to network only to a single player (hunger, stamina...)
-- Made by Wasied :)
LocalNWVars = LocalNWVars or {}
LocalNWVars.tTypes = LocalNWVars.tTypes or {}
LocalNWVars.tValues = LocalNWVars.tValues or {}

local PLAYER = FindMetaTable("Player")

-- Callbacks depending on the type of the var we want to send
-- Don't hesitate to issue/PR to add new types :)
local tCallbacks = {
    ["string"] = {
        fcWrite = function(s) net.WriteString(s) end,
        fcRead = function() return net.ReadString() end
    },
    ["number"] = {
        fcWrite = function(i) net.WriteInt(i, 32) end, -- since we don't know what the value will be, use 32 bits by default
        fcRead = function() return net.ReadInt(32) end
    },
    ["boolean"] = {
        fcWrite = function(b) net.WriteBool(b) end,
        fcRead = function() return net.ReadBool() end
    },
    ["table"] = {
        fcWrite = function(t) net.WriteTable(t) end,
        fcRead = function() return net.ReadTable() end
    },
    ["Vector"] = {
        fcWrite = function(v) net.WriteVector(v) end,
        fcRead = function() return net.ReadVector() end
    },
    ["Angle"] = {
        fcWrite = function(a) net.WriteAngle(a) end,
        fcRead = function() return net.ReadAngle() end
    },
    ["Entity"] = {
        fcWrite = function(e) net.WriteEntity(e) end,
        fcRead = function() return net.ReadEntity() end
    },
    ["Player"] = {
        fcWrite = function(p) net.WritePlayer(p) end,
        fcRead = function() return net.ReadPlayer() end
    },
    ["Vehicle"] = {
        fcWrite = function(e) net.WriteEntity(e) end,
        fcRead = function() return net.ReadEntity() end
    },
    ["nil"] = { -- Reset a variable
        fcWrite = function() end,
        fcRead = function() end
    }
}

--[[ SERVER-SIDE ]]--
if SERVER then

    -- Network register
    util.AddNetworkString("LocalNWVar:RegisterType")
    util.AddNetworkString("LocalNWVar:Update")

    -- Set the value of a variable
    function PLAYER:SetLocalNWVar(sVarName, xValue)

        if not IsValid(self) then return end

        if not isstring(sVarName) then
            return false, Error(("[LocalNWVar] %s is not an valid LocalNWVar name"):format(sVarName))
        end

        local sType = type(xValue)
        if not tCallbacks[sType] or not isfunction(tCallbacks[sType].fcWrite) then
            return false, Error(("[LocalNWVar] %s is not an valid LocalNWVar type"):format(sType))
        end

        LocalNWVars.tTypes[self] = LocalNWVars.tTypes[self] or {}
        LocalNWVars.tValues[self] = LocalNWVars.tValues[self] or {}

        -- Tell to the client that the network callback has changed for this var
        if LocalNWVars.tTypes[self][sVarName] ~= sType then

            net.Start("LocalNWVar:RegisterType")
                net.WriteString(sVarName)
                net.WriteString(sType)
            net.Send(self)

        end

        -- Update the var with the good network callback
        net.Start("LocalNWVar:Update")
            net.WriteString(sVarName)
            tCallbacks[sType].fcWrite(xValue)
        net.Send(self)

        -- Register the type to avoid registering every time the value has changed
        LocalNWVars.tTypes[self][sVarName] = (sType ~= "nil" and sType or nil)
        LocalNWVars.tValues[self][sVarName] = xValue

        hook.Run("OnLocalNWVarChanged", self, sVarName, xValue)

    end

--[[ CLIENT-SIDE ]]--
else

    -- Update types cache when a var has changed its type
    net.Receive("LocalNWVar:RegisterType", function()
        LocalNWVars.tTypes[net.ReadString()] = net.ReadString()
    end)

    -- Receive the new value for a var and update it
    net.Receive("LocalNWVar:Update", function()

        local sVarName = net.ReadString()
        if not isstring(LocalNWVars.tTypes[sVarName]) then return end

        local sType = LocalNWVars.tTypes[sVarName]
        local tNetCallback = tCallbacks[sType]

        if not istable(tNetCallback) then
            return false, Error(("[LocalNWVar] %s is not an valid LocalNWVar type"):format(sType))
        end

        if not isfunction(tNetCallback.fcRead) then return end

        local xValue = tNetCallback.fcRead()
        LocalNWVars.tValues[sVarName] = xValue

        if xValue == nil then
            LocalNWVars.tTypes[sVarName] = nil
        end

        hook.Run("OnLocalNWVarChanged", sVarName, xValue)

    end)

end

--[[ SHARED-SIDE ]]--

-- Get the value from a variable name
function PLAYER:GetLocalNWVar(sVarName, xFallback)

    if not isstring(sVarName) then return xFallback end

    local tValues = LocalNWVars.tValues
    if SERVER then tValues = tValues[self] end

    if tValues and tValues[sVarName] ~= nil then
        return tValues[sVarName]
    end

    return xFallback

end