# LinkEm
Client-Server Communication Module for Roblox 
</br>
</br>

## Usage Examples
</br>

#### Create a new basic Link

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

#### Use a basic Link

Client:
```lua
Link:SendMsg("I Want Pickles", 5)
Link:GetMsgSignal("Pickles Given"):Connect(function(data)
 print("I was given", data, "pickles.")
 --Output: I was given 5 pickles.
end)
```

Server:
```lua
Link:GetMsgSignal("I Want Pickles"):Connect(function(player, data)
 Link:SendMsg("Pickles Given", data, player)
end)
```
</br>
</br>

#### Create a new specific Link

Server:
```lua
 --Require the LinkEm Class into your work
local LinkEm = require(game:GetService("ServerScriptService").LinkEm) --Server Side

--Create a new Link to use and specify a player/client this link is for.
--This tells LinkEm that this link should only work for the client specified.
local Link = LinkEm.New("MyLinkName", playerObj)

--Wait for the link to be established
Link.Linked:Wait() 
```

Client:
```lua
 --Require the LinkEm Class into your work
local LinkEm = require(game:GetService("ReplicatedStorage").LinkEm) --Client Side

--Create a new Link to use and set the "UsePlayer" parameter to true
--This tells LinkEm that this link should only work for this client.
local Link = LinkEm.New("MyLinkName", true)

--Wait for the link to be established
Link.Linked:Wait() 
```
</br>

#### Use a specific Link

Client:
```lua
Link:SendMsg("I Want Pickles", 5)
Link:GetMsgSignal("Pickles Given"):Connect(function(data)
 print("I was given", data, "pickles.")
 --Output: I was given 5 pickles.
end)
```

Server:
```lua
Link:GetMsgSignal("I Want Pickles"):Connect(function(data)
 Link:SendMsg("Pickles Given", data)
end)
```
Because this link is specific to the player we gave when it was created.
We no longer have to specify or check the player. LinkEm will automatically
ignore any signals on this link for other clients.
</br>
</br>
