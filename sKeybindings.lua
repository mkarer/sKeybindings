--[[

	s:Keybindings

	Martin Karer / Sezz, 2014
	http://www.sezz.at

--]]
 
require "Window";
require "GameLib";
 
local sKeybindings = {};
local pairs, ipairs, GameLib, Apollo, strlen, tinsert = pairs, ipairs, GameLib, Apollo, string.len, table.insert;

-----------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------

local ktKeyMapping = {
	idAction = "a",
	idCategory = "c",
	iInputKeyLookupGroup = "i",
	arInputs = "n",
};

local ktKeyMappingInput = {
	eDevice = "d",
	eModifier = "m",
	nCode = "c",
};

local ktUnusedKeys = {
	strAction = 1,
	strActionLocalized = 1,
	nDisplayIndex = 1
};

local ktInputEmpty = {
	eDevice = 0,
	eModifier = 0,
	nCode = 0,
};

local knInputs = 8;

-----------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------

function sKeybindings:New(o)
	o = o or {};
	setmetatable(o, self);
	self.__index = self;

	return o;
end

function sKeybindings:Init()
	local bHasConfigureFunction = false;
	local strConfigureButtonText = "";
	local tDependencies = {
		-- "UnitOrPackageName",
	}
	Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies);
end

function sKeybindings:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("sKeybindings.xml");
	self.xmlDoc:RegisterCallback("OnDocLoaded", self);
end

function sKeybindings:OnDocLoaded()
	if (self.xmlDoc ~= nil and self.xmlDoc:IsLoaded()) then
		self.wndMain = Apollo.LoadForm(self.xmlDoc, "sKeybindingsForm", nil, self);
		if (self.wndMain == nil) then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.");
			return;
		end

		self.wndMain:Enable(false);
		self.wndMain:Show(fales, true);		
		self.xmlDoc = nil;
		Apollo.GetPackage("AceSerializer-3.0").tPackage:Embed(self);

		Apollo.RegisterSlashCommand("skb", "Show", self);
	end
end

function sKeybindings:Show()
	self.wndMain:FindChild("BtnBindingsToClipboard"):SetActionData(GameLib.CodeEnumConfirmButtonType.CopyToClipboard, self:GetKeyBindings());
	self.wndMain:Enable(true);
	self.wndMain:Show(true, true);
end

-----------------------------------------------------------------------------

function sKeybindings:GetKeyBindings()
	-- strip unimportant data + rename/shorten keys
	local tKeyBindings = GameLib.GetKeyBindings();

	for _, tKeyBinding in ipairs(tKeyBindings) do
		for k, v in pairs(ktKeyMapping) do
			tKeyBinding[v] = tKeyBinding[k];
			tKeyBinding[k] = nil;
		end

		for k, v in pairs(ktUnusedKeys) do
			tKeyBinding[k] = nil;
		end

		for i, tInput in ipairs(tKeyBinding.n) do
			if (tInput.nCode == 0) then
				tKeyBinding.n[i] = 0;
			else
				for k, v in pairs(ktKeyMappingInput) do
					tInput[v] = tInput[k];
					tInput[k] = nil;
				end
			end
		end
	end

	return self:Serialize(tKeyBindings);
end

function sKeybindings:ReplaceKeyBindings()
	local wndEditBox = self.wndMain:FindChild("EditBox");
	wndEditBox:SetText("");
	wndEditBox:PasteTextFromClipboard();

	local strClipboard = wndEditBox:GetText();
	if (strlen(strClipboard) > 0) then
		local bDeserialized, tKeyBindings = self:Deserialize(strClipboard);
		if (bDeserialized) then
			-- Get action strings
			local tActions = {};

			for _, k in ipairs(GameLib:GetKeyBindings()) do
				if not (tActions[k.idCategory]) then tActions[k.idCategory] = {}; end
				tActions[k.idCategory][k.idAction] = { k.strAction, k.strActionLocalized };
			end

			-- Revert key changes
			for _, tKeyBinding in ipairs(tKeyBindings) do
				for k, v in pairs(ktKeyMapping) do
					tKeyBinding[k] = tKeyBinding[v];
					tKeyBinding[v] = nil;
				end

				tKeyBinding.strAction = tActions[tKeyBinding.idCategory][tKeyBinding.idAction][1];
				tKeyBinding.strActionLocalized = tActions[tKeyBinding.idCategory][tKeyBinding.idAction][2];

				for i, tInput in ipairs(tKeyBinding.arInputs) do
					if (type(tInput) == "number" and tInput == 0) then
						tKeyBinding.arInputs[i] = ktInputEmpty;
					else
						for k, v in pairs(ktKeyMappingInput) do
							tInput[k] = tInput[v];
							tInput[v] = nil;
						end
					end
				end
			end

			GameLib.SetKeyBindings(tKeyBindings);
			Print("Done!");
			tActions = nil;
		else
			Print("An error occured - please try exporting the keybindings again.");
		end
	end
end

-----------------------------------------------------------------------------
-- sKeybindings Instance
-----------------------------------------------------------------------------

local sKeybindingsInst = sKeybindings:New();
sKeybindingsInst:Init();
