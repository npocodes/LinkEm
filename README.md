# LinkEm
Client-Server Communication Module for Roblox.</br></br>
This module handles all the nasty bits of client/server communication and makes it easy.
It includes general/basic links for when many clients need to communicate to one game system/class.
Or specific links for when a class utilizes instances unique to a specific player or if you simply only
want one specific player to be able to communicate with the system/class on the server.
You can even send objects/instances to the client very simply and LinkEm will take care of ensuring
the object is ready to use and the client side can see/use it.

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


#### Send an obj to the client

Server:
```lua
--Create a new model to send to the client
--This could be any sort of model, all of its descendants will also be sent.
local myObject = Instance.new("Model")
myObject.Name = "PickleJar"

--Send the object. The first parameter is the object to send.
--The second parameter is the MsgSignal the client should listen for.
Link:SendObject(myObject, "NewPickleJar")

--We could listen for requests for pickle jars as well
Link:GetMsgSignal("RequestPickleJar"):Connect(function(data)
 print("The client has requested a new pickle jar!")
 Link:SendObject(myObject:Clone(), "NewPickleJar")
end)
```

Client:
```lua
--Listen for the MsgSignal specified by the server and call a function
--to handle the event.
Link:GetMsgSignal("NewPickleJar"):Connect(function(sentObj: Instance)
 print("The server sent me a", sentObj.Name)
end)

--Now if we needed to or wanted to...
--We could actually request a new pickle jar... as long as the server
--has a listener for a msg signal to respond to that request
Link:SendMsg("RequestPickleJar")
```
LinkEm will handle all the nasty bits of sending the object to the client.
Including making sure ALL of it is ready for the client to use before the event fires.
So can we also send an object from the client to the server?!?! NO you cannot. lol
This behavior is not desired which is why Roblox implemented safeguards for such a thing.
What we do is simply request objects for the server to produce and tell the client about them.
