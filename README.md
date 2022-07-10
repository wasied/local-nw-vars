# local-nw-vars
A Garry's Mod library allowing you to use networked variables local to a player

# Why LocalNWVars instead of NWVars?
Because when you're setting a NWVar on a player, the value is broadcasted to every player connected in the server.  
A lot of beginners are using it anyway because it's easier. That is a bad behavior.  

Anyway, this is not an issue anymore since LocalNWVars is out and you can use it exactly like NWVar but they are synchronized only with the player specified. 

# Setup
Just drag the file into your gamemode/addon and **include it by yourself** (it's a **shared** file).  
Once it's done, you can use it. Not that hard, heh?

# Usage
Use it exactly as NWVars but replace it by LocalNWVar.  
You **DON'T** need to register a variable in order to use it (it's done automatically).

### Set a value on a player **(server-side only)**
```lua
Player:SetLocalNWVar(uniqueVarName, anyValue)
```
**uniqueVarName** *(string)* is used to identify the variable clientside  
**anyValue** *(string, number, boolean or table)* is the value that will be defined  

### Get a value from a player
```lua
Player:GetLocalNWVar(uniqueVarName, fallbackValue)
```
**uniqueVarName** *(string)* is used to identify the variable that has been set serverside.  
**fallbackValue** ***(optional)*** *(any)* is the value that will be returned in the case the variable has not been defined yet.  

# Example
Serverside lua file
```lua
hook.Add("PlayerLoadout", "LocalNWVarExample", function(pPlayer)
  pPlayer:SetLocalNWVar("Hunger", math.random(1, 100)) -- set a random value between 1 and 100
end)
```

Clientside lua file
```lua
hook.Add("HUDPaint", "LocalNWVarExample", function()
  
  local iHunger = LocalPlayer():GetLocalNWVar("Hunger", 100)
  
  surface.SetDrawColor(color_white)
  surface.DrawRect(50, 50, iHunger, 40)

end)
```
