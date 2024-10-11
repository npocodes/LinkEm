--[[
	LINK MODULE -- [CLIENT]
	Emskipo
	8/14/2023
--]]


--{ SERVICES }--

local RepStor = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")


--( MODULE )--

local Link = {}
Link.__index = Link
Link.RepFolder = RepStor:FindFirstChild("_Links_")
repeat
	task.wait()--Yield until the links folder is found
	Link.RepFolder = RepStor:FindFirstChild("_Links_")
until Link.RepFolder


--{ TYPES }--

export type ClientLink = {

	LinkName: string,
	UsePlayer: boolean,
	LinkActive: boolean,

	Linked: RBXScriptSignal,
	Message: RBXScriptSignal,
	ObjectSent: RBXScriptSignal,

	SendMsg: (self: ClientLink, msg: string, data: any?) -> nil,
	GetMsgSignal: (self: ClientLink, msg: string) -> RBXScriptSignal,
}


--{ CONSTANTS }--

local CLIENT = Players.LocalPlayer--This Client's Player

local LINK_GUI = Instance.new("ScreenGui")
local linkFrame = Instance.new("Frame")
linkFrame.AnchorPoint = Vector2.new(.5,.5)
linkFrame.Position = UDim2.fromScale(.5,.5)
linkFrame.Size = UDim2.fromScale(.25,.25)
linkFrame.BackgroundTransparency = 1
linkFrame.Parent = LINK_GUI

local uiGridLayout = Instance.new("UIGridLayout")
uiGridLayout.Parent = linkFrame
uiGridLayout.CellSize = UDim2.fromScale(.2,.2)
uiGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiGridLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local linkTpl = Instance.new("TextLabel")
linkTpl.BackgroundColor3 = Color3.fromRGB(93,93,93)
linkTpl.TextScaled = true

local uicorner = Instance.new("UICorner")
uicorner.Parent = linkTpl

LINK_GUI.Parent = CLIENT.PlayerGui
LINK_GUI.Enabled = false


--{ PRIVATE }--


--Collects and sets the link objects created by
--the server
local function ServerLink(self: ClientLink, event)
	--Set the Event object.
	self._Event = event or self._Event
	--print("LinkObjFound:"..CLIENT.Name)

	--Wait for the Sync object
	self._SyncEvent = self._Event:WaitForChild(self._Event.Name)

	--Wait for the Obj Folder
	self._ObjFolder = self._Event:WaitForChild("_Obj_")

	--Begin Listening for events
	self._EventConn = self._Event.OnClientEvent:Connect(function(...) self:_OnEvent(...) end)

	--Inform Server we are Linked!
	self._Event:FireServer("Linked")

	--Begin Listening for Sent Objects
	self._ObjConn = self._ObjFolder.ChildAdded:Connect(function(...) self:_OnObject(...) end)
end

--Establishes a link to its server side counterpart
--via the server side created remote event for this link instance
local function LinkServer(self: ClientLink)
	local linkName = (self.UsePlayer) and self.LinkName..CLIENT.UserId or self.LinkName
	self._Event = Link.RepFolder:FindFirstChild(linkName)
	if(self._Event)then ServerLink(self) return end

	local repConn = nil
	repConn = Link.RepFolder.ChildAdded:Connect(function(child)
		if(child:IsA("RemoteEvent") and child.Name == linkName)then
			if(not(repConn))then return end --Already Disconnected
			repConn:Disconnect()
			repConn = nil

			ServerLink(self, child)
		end
	end)
end


--{ PUBLIC }--

--Creates a new client/server link instance. If usePlayer is set to true
--then the link will work only for the client player.
function Link.New(linkName: string, usePlayer: boolean?): ClientLink
	if(not(linkName))then warn("A Link Name is required") return end
	if(not(usePlayer))then usePlayer = false end
	
	--LINK_GUI.Enabled = true

	local newLinkGui = linkTpl:Clone()
	newLinkGui.Text = linkName
	newLinkGui.Parent = linkFrame

	local new = {}
	setmetatable(new, Link)
	
	new.LinkGui = newLinkGui
	new.LinkName = linkName
	new.UsePlayer = usePlayer
	new.LinkActive = false
	
	-- UNIQUE LINK REMOTE EVENT --
	new._Event = nil
	new._SyncEvent = nil
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
	LinkServer(new)
	
	return new
end


--Establishes a link to its server side counterpart
--via the server side created remote event for this link instance
function Link._LinkServer(self: ClientLink)
	local linkName = (self.UsePlayer) and self.LinkName..CLIENT.UserId or self.LinkName
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
function Link._OnEvent(self: ClientLink, msg: string, data)
	if(msg == "Linked")then
		self.LinkActive = true
		print(self.LinkName, "Link Established")
		self.LinkGui.BackgroundColor3 = if(self.UsePlayer)then Color3.fromRGB(46, 126, 42) else Color3.fromRGB(255, 176, 0)
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
function Link._OnObject(self: ClientLink, obj: Instance)
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
	
	--Move Object out the Obj folder --WE CAN"T DO THIS..
	--THE SERVER WILL NOT RECOGNIZE THIS PARENT CHANGE!!
	--obj.Parent = obj.Parent.Parent --DO WE REALLY NEED TO?
	--YES IT NEEDS TO BE MOVED TO A STORAGE LOCATION!!!
	--ELSE IT WILL FIRE THE OBJECT SENT EVENT WHENEVER
	--PUT BACK INTO THE DIRECTORY
	obj.Parent = self._Event

	--Fire the Object/Msg Events
	self._ObjectEvent:Fire(obj, msg)
	if(self._MsgEvents[msg])then
		self._MsgEvents[msg]:Fire(obj)
	end
end


--Sends a message through this link to the server counter part.
function Link.SendMsg(self: ClientLink, msg:string, data: any?)
	self._Event:FireServer(msg, data)
end


--Returns RBXScriptSignal for the specified msg on this link
function Link.GetMsgSignal(self: ClientLink, msg: string): RBXScriptSignal
	if(not(self._MsgEvents[msg]))then
		self._MsgEvents[msg] = Instance.new("BindableEvent")
	end
	return self._MsgEvents[msg].Event
end

--Request a direct response from the server
function Link.GetMsgResponse(self: ClientLink, msg: string, data: any?): any | "No Response"
	--(player: Player, msg: string, data): any | "No Response"
	return self._SyncEvent:InvokeServer(msg, data)
end

function Link.Destroy(self: ClientLink)
	if(not(self))then return end
end

--( RETURN )--
return Link