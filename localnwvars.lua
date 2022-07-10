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
        fcRead = function() net.ReadString() end
    },
    ["number"] = {
        fcWrite = function(i) net.WriteInt(i, 32) end, -- since we don't know what the value will be, use 32 bits by default
        fcRead = function() net.ReadInt(i) end
    },
    ["boolean"] = {
        fcWrite = function(b) net.WriteBool(b) end,
        fcRead = function() net.ReadBool() end
    },
    ["table"] = { -- Please don't use it until you REALLY need it. Networked tables = bad.
        fcWrite = function(t) net.WriteTable(t) end,
        fcRead = function() net.ReadTable() end
    }
}

--[[ SERVER-SIDE ]]--
if SERVER then

    -- Network register
    util.AddNetworkString("LocalNWVar:RegisterType")
    util.AddNetworkString("LocalNWVar:Update")

    -- Set the value of a variable
    function PLAYER:SetLocalNWVar(sVarName, xValue)

        if not isstring(sVarName) or xValue == nil then return end
        if not IsValid(self) then return end

        local sType = type(xValue)

        if not tCallbacks[sType] or not isfunction(tCallbacks[sType].fcWrite) then 
            return false, Error(("[LocalNWVar] %s is not an valid LocalNWVar type"):format(sType))
        end

        -- Tell to the client that the network callback has changed for this var
        if LocalNWVars.tTypes[sVarName] ~= sType then

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
        LocalNWVars.tTypes[sVarName] = sType
        LocalNWVars.tValues[sVarName] = xValue
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
        if xValue == nil then
            return false, Error(("[LocalNWVar] An unknown error has occured while reading a %s"):format(sType))
        end

        LocalNWVars.tValues[sVarName] = xValue
        hook.Run("OnLocalNWVarChanged", self, sVarName, xValue)

    end)

end

--[[ SHARED-SIDE ]]--

-- Get the value from a variable name
function PLAYER:GetLocalNWVar(sVarName, xFallback)

    if not isstring(sVarName) then return xFallback end

    if LocalNWVars.tValues[sVarName] ~= nil then
        return LocalNWVars.tValues[sVarName]
    end

    return xFallback

end