# LinkEm - Client-Server Communication Module for Roblox
  
### Basic Usage Examples


</br>

#### Create a new Link (General Link, not player specific)

This should be done on both the client and server.
```lua
 --Require the LinkEm Class into your work
local LinkEm = require(game:GetService("ReplicatedStorage").LinkEm) --Client Side
--local LinkEm = require(game:GetService("ServerScriptService").LinkEm) --Server Side

--Create a new Link to use
local Link = LinkEm.New("MyLinkName")
Link.Linked:Wait() --Wait for the link to be established

-- OR Connect to the Linked event for this link and do something when its established.
Link.Linked:Connect(function()
 print("Link established!")
end)

```
</br>

#### Use a Link

From Client
```lua
Link:SendMsg("I Want Pickles", 5)
Link:GetMsgSignal("Pickles Given"):Connect(function(data)
 print("I was given", data, "pickles.")
 --Output: I was given 5 pickles.
end)
```

From Server
```lua
Link:GetMsgSignal("I Want Pickles"):Connect(function(player, data)
 Link:SendMsg("Pickles Given", data, player)
end)
```
