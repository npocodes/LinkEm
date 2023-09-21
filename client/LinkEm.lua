--[[
	LINK MODULE -- [CLIENT]
	Nathan Poole (Emskipo)
	8/14/2023
--]]

-- SERVICES --

local RepStor = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")


-- LOCAL DATA --

local Player = Players.LocalPlayer--This Client's Player


--( LINK MODULE )--

local Link = {}
Link.__index = Link
Link.RepFolder = RepStor:FindFirstChild("_Links_")--COULD STALL OUT!!
repeat
	task.wait()--Yield until the links folder is found
	Link.RepFolder = RepStor:FindFirstChild("_Links_")
until Link.RepFolder


export type Link = {

	LinkName: string,
	UsePlayer: boolean,
	LinkActive: boolean,
	
	Linked: RBXScriptSignal,
	Message: RBXScriptSignal,
	ObjectSent: RBXScriptSignal,
	
	SendMsg: (self: Link, msg: string, data: any?) -> nil,
	GetMsgSignal: (self: Link, msg: string) -> RBXScriptSignal,
}


--Creates a new client/server link instance. If usePlayer is set to true
--then the link will work only for the client player.
function Link.New(linkName: string, usePlayer: boolean?): Link
	if(not(linkName))then warn("A Link Name is required") return end
	if(not(usePlayer))then usePlayer = false end
	
	local new = {}
	setmetatable(new, Link)
	
	new.LinkName = linkName
	new.UsePlayer = usePlayer
	new.LinkActive = false
	
	-- UNIQUE LINK REMOTE EVENT --
	new._Event = nil
	new._EventConn = nil
	new._ObjConn = nil
	new._ObjFolder = nil
	
	-- CUSTOM LINK EVENTS --
	new._LinkedEvent = Instance.new("BindableEvent")
	new.Linked = new._LinkedEvent.Event
	
	new._MessageEvent = Instance.new("BindableEvent")
	new.Message = new._MessageEvent.Event
	
	new._ObjectEvent = Instance.new("BindableEvent")
	new.ObjectSent = new._ObjectEvent.Event
	
	new._MsgEvents = {}
	
	new:_LinkServer()
	
	return new
end


--Establishes a link to its server side counterpart
--via the server side created remote event for this link instance
function Link:_LinkServer()
	local linkName = (self.UsePlayer) and self.LinkName..Player.UserId or self.LinkName
	self._Event = Link.RepFolder:FindFirstChild(linkName)
	if(not(self._Event))then
		local repConn = nil
		repConn = Link.RepFolder.ChildAdded:Connect(function(child)
			if(child:IsA("RemoteEvent") and child.Name == linkName)then

				--Set the Event object.
				self._Event = child
				
				--Wait for the Obj Folder
				self._ObjFolder = self._Event:WaitForChild("_Obj_")
				
				--Begin Listening for events
				self._EventConn = self._Event.OnClientEvent:Connect(function(...) self:_OnEvent(...) end)

				--Inform Server we are Linked!
				self._Event:FireServer("Linked")

				--Begin Listening for Sent Objects
				self._ObjConn = self._ObjFolder.ChildAdded:Connect(function(...) self:_OnObject(...) end)

				--Disconnect()
				if(repConn)then repConn:Disconnect() end
				repConn = nil
			end
		end)
	else
		--Wait for the Obj Folder
		self._ObjFolder = self._Event:WaitForChild("_Obj_")
		
		--Begin Listening for events
		self._EventConn = self._Event.OnClientEvent:Connect(function(...) self:_OnEvent(...) end)

		--Inform Server we are Linked!
		self._Event:FireServer("Linked")

		--Begin Listening for Sent Objects
		self._ObjConn = self._ObjFolder.ChildAdded:Connect(function(...) self:_OnObject(...) end)
	end
end


--Handles reception of messages sent from the server
--and fires both the global and specific msg events
function Link:_OnEvent(msg, data)
	if(msg == "Linked")then
		self.LinkActive = true
		print(self.LinkName, "Link Established")
		self._LinkedEvent:Fire()
	else
		self._MessageEvent:Fire(msg, data)
		if(self._MsgEvents[msg])then
			self._MsgEvents[msg]:Fire(data)
		end
	end
end


--Handles reception of objects from the server and fires the
--object event. The obj and msg are passed with the event.
function Link:_OnObject(obj: Instance)
	--Check for Msg Attribute
	local msg = obj:GetAttribute("_LinkMsg")
	if(msg)then obj:SetAttribute("_LinkMsg") end--Clear the attribute
	
	--Check for Part Count and wait for all parts
	local partCount = obj:GetAttribute("_LinkPartCount")
	if(partCount)then
		local count = 0
		repeat
			task.wait()
			count = #obj:GetDescendants()
		until count == partCount
		obj:SetAttribute("_LinkPartCount")--Clear Attribute
	end
	
	--Move Object out the Obj folder
	obj.Parent = obj.Parent.Parent
	
	--Fire the Object/Msg Events
	self._ObjectEvent:Fire(obj, msg)
	if(self._MsgEvents[msg])then
		self._MsgEvents[msg]:Fire(obj)
	end
end


--Sends a message through this link to the server counter part.
function Link:SendMsg(msg:string, data: any?)
	self._Event:FireServer(msg, data)
end


--Returns RBXScriptSignal for the specified msg on this link
function Link:GetMsgSignal(msg: string): RBXScriptSignal
	if(not(self._MsgEvents[msg]))then
		self._MsgEvents[msg] = Instance.new("BindableEvent")
	end
	return self._MsgEvents[msg].Event
end


--LAST LINE
return Link