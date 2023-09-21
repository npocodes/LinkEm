--[[
	LINK MODULE -- [SERVER]
	Nathan Poole (Emskipo)
	8/14/2023
--]]

-- SERVICES --

local RepStor = game:GetService("ReplicatedStorage")


--( LINK MODULE )--

local Link = {}
Link.__index = Link


export type Link = {
	
	LinkName: string,
	Player: Player?,
	LinkActive: boolean,
	
	Linked: RBXScriptSignal,
	Message: RBXScriptSignal,
	
	SendMsg: (self: Link, msg: string, data: any?, players: {Players}?) -> nil,
	SendObj: (obj: Instance, msg: string) -> nil,
	GetMsgSignal: (self: Link, msg: string) -> RBXScriptSignal,
}

--Create Links Folder in RepStorage
Link.RepFolder = Instance.new("Folder")
Link.RepFolder.Name = "_Links_"
Link.RepFolder.Parent = RepStor


--{ PUBLIC }--

--Creates a new client/server link instance. If player is provided
--then the link will work only for the player specified.
function Link.New(linkName:string, player: Player?): Link
	if(not(linkName))then warn("A Link Name is required") return end
	
	local new = {}
	setmetatable(new, Link)
	
	--new.LinkId = Link.GetId()
	new.LinkName = linkName
	new.Player = player
	new.LinkActive = false
	
	-- Link Remote Event --
	new._Event = Instance.new("RemoteEvent")
	new._Event.Name = (player) and linkName..player.UserId or linkName
	new._EventConn = new._Event.OnServerEvent:Connect(function(...) new:_OnEvent(...) end)
	
	--Link Obj Folder --
	new._ObjFolder = Instance.new("Folder")
	new._ObjFolder.Name = "_Obj_"
	new._ObjFolder.Parent = new._Event
	
	--Finally Parent Event to the RepFolder
	new._Event.Parent = Link.RepFolder
	
	-- CUSTOM LINK EVENTS --
	new._LinkedEvent = Instance.new("BindableEvent")
	new.Linked = new._LinkedEvent.Event
	
	new._MessageEvent = Instance.new("BindableEvent")
	new.Message = new._MessageEvent.Event
	
	new._MsgEvents = {}--[Name] = RBXScriptSignal
	
	--Return this link
	return new
end

--Sends a message through this link to the client counter part
--If link is not player locked, then the msg will default to all
--clients. If a list of players is provided, then the msg will
--be sent to only the players listed.
function Link:SendMsg(msg:string, data: any?, players: {Players}?)
	if(not(self.Player))then
		--Not player specific link
		if(not(players and typeof(players) == "table"))then
			--Send to All players
			self._Event:FireAllClients(msg, data)
		else
			--Only for listed players
			for i = 1, #players do
				if(players[i] and players[i]:IsA("Player"))then
					self._Event:FireClient(players[i], msg, data)
				end
			end
		end
	else
		--This link is player specific
		if(players and typeof(players) == "table")then
			--For listed players
			for i = 1, #players do
				if(players[i] and players[i]:IsA("Player"))then
					self._Event:FireClient(players[i], msg, data)
				end
			end
		else
			--Only for specific player
			self._Event:FireClient(self.Player, msg, data)
		end
	end
end

--Sends an object instance to the client counter part
function Link:SendObj(obj: Instance, msg: string)
	if(msg)then obj:SetAttribute("_LinkMsg", msg) end
	local partCount = obj:GetDescendants()
	if(#partCount > 0)then obj:SetAttribute("_LinkPartCount", #partCount) end
	obj.Parent = self._Event["_Obj_"]
end

--Returns RBXScriptSignal for the specified msg on this link
function Link:GetMsgSignal(msg: string): RBXScriptSignal
	if(not(self._MsgEvents[msg]))then
		self._MsgEvents[msg] = Instance.new("BindableEvent")
	end
	return self._MsgEvents[msg].Event
end

--Handles reception of messages sent from the client
--and fires both the global and specific msg events
function Link:_OnEvent(player:Player, msg:string, data)
	if(self.Player)then 
		if(player ~= self.Player)then return end --Player Mis-Match
	end
	
	if(msg == "Linked")then
		self.LinkActive = true
		self._Event:FireClient(player, "Linked")--Respond
		print(self.LinkName, "Link Established")
		self._LinkedEvent:Fire()

	else
		if(not(self.Player))then
			self._MessageEvent:Fire(player, msg, data)
			if(self._MsgEvents[msg])then
				self._MsgEvents[msg]:Fire(player, data)
			end
		else
			--Link is player specific and we've already verified the player
			--there is no need to send the player instance
			self._MessageEvent:Fire(msg, data)
			if(self._MsgEvents[msg])then
				self._MsgEvents[msg]:Fire(data)
			end
		end
	end
end

--LAST LINE
return Link