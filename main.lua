local struct = require("custom.struct") -- Requires https://github.com/iryont/lua-struct

local espParser = {}

espParser.scriptName = "espParser"
espParser.config = jsonConfig.Load(
    espParser.scriptName,
    {
		espPath = "custom/esps/",
		useRequiredDataFiles = true,
		requiredDataFiles = "requiredDataFiles.json",
		files = {},
		loadOnStart = false
	},
    {
		"espPath",
		"useRequiredDataFiles",
		"requiredDataFiles",
		"files",
		"loadOnStart"
	}
)

local structTypes = {
    b = 1, --signed char
    B = 1, --unsigned char
    h = 2, --unsigned short
    H = 2, --unsigned short
    i = 4, --signed int
    I = 4, --unsigned int
    l = 8, --signed long
    L = 8, --unsigned long
    f = 4, --float
    d = 8, --double
    s = nil, --zero-terminated string
    cn = nil --sequence of exactly n chars corresponding to a single Lua string
}
local readPosition = 1
espParser.read = function(data, structType, pos)
	if pos ~= nil then readPosition = pos end
	local size = structTypes[structType]
	local str = ""
	if type(data) ~= "string" then
		if not size then
			local ct = {}
			local c = data:read(1)
			while c do
				table.insert(ct, c)
				if c == "\0" then break end
				c = data:read(1)
			end
			str = table.concat(ct)
		else
			str = data:read(size)
		end
	else
		str = data
	end
	local res = struct.unpack(structType, str, readPosition)
	if not size then
		size = string.len(res)
	end
	readPosition = readPosition + size
	return res
end
local v = espParser.read

local p = {
	byte = function(d) return v(d, "b", 1) end,
	float = function(d) return v(d, "f", 1) end,
	int = function(d) return v(d, "i", 1) end,
	str = function(d) return v(d, "s", 1) end,
	char = function(n)
		return function(d) return v(d, "c" .. n, 1) end
	end,
	TODO = function(d) return d end
}
local subRecordParsers = {
	TES3 = {
		HEDR = function(d)
			local res = {}
			res.version = v(d, "f", 1)
			res.unknown = v(d, "i")
			res.companyName = v(d, "c32")
			res.description = v(d, "c256")
			res.numRecords = v(d, "i")
			return res
		end,
		MAST = p.str,
		DATA = function(d)
			return v(d, "l", 1)
		end
	},
	GMST = {
		NAME = p.str,
		STRV = p.str,
		INTV = p.int,
		FLTV = p.float
	},
	GLOB = {
		NAME = p.str,
		FNAM = p.char(1),
		FLTV = p.float
	},
	CLAS = {
		NAME = p.str,
		FNAM = p.str,
		CLD = p.TODO,
		DESC = p.str
	},
	FACT = {
		NAME = p.str,
		FNAM = p.str,
		RNAM = p.str,
		FADT = p.TODO,
		ANAM = p.str,
		INTV = p.int
	},
	RACE = {
		NAME = p.str,
		FNAM = p.str,
		RADT = p.TODO,
		NPCS = p.str,
		DESC = p.str
	},
	SOUN = {
		NAME = p.str,
		FNAM = p.str,
		DATA = p.TODO,
	},
	SKIL = {
		INDX = p.int,
		SKDT = p.TODO,
		DESC = p.str
	},
	MGEF = {
		INDX = p.int,
		MEDT = p.TODO,
		ITEX = p.str,
		PTEX = p.str,
		CVFX = p.str,
		BVFX = p.str,
		HVFX = p.str,
		AVFX = p.str,
		DESC = p.str,
		CSND = p.str,
		BSND = p.str,
		HSND = p.str,
		ASND = p.str
	},
	SCPT = {
		SCHD = p.TODO,
		SCVR = p.TODO,
		SCDT = p.str,
		SCTX = p.str
	},
	REGN = {
		NAME = p.str,
		FNAM = p.str,
		WEAT = p.TODO,
		BNAM = p.str,
		CNAM = p.TODO,
		SNAM = p.TODO
	},
	BSGN = {
		NAME = p.str,
		FNAM = p.str,
		TNAM = p.str,
		DESC = p.str,
		NPCS = p.str
	},
	LTEX = { -- ?
	},
	STAT = {
		NAME = p.str,
		MODL = p.str
	},
	DOOR = {
		NAME = p.str,
		FNAM = p.str,
		MODL = p.str,
		SCIP = p.str,
		SNAM = p.str,
		ANAM = p.str
	},
	MISC = {
		NAME = p.str,
		MODL = p.str,
		FNAM = p.str,
		MCDT = function(d)
			return {
				Weight = v(d, "f", 1),
				Value = v(d, "i"),
				Unknown = v(d, "i")
			}
		end,
		ITEX = p.str,
		ENAM = p.str,
		SCRI = p.str
	},
	WEAP = {
		NAME = p.str,
		MODL = p.str,
		FNAM = p.str,
		WPDT = function(d)
			return {
				Weight = v(d, "f", 1),
				Value = v(d, "i"),
				Type = v(d, "h"),
				Health = v(d, "h"),
				Speed = v(d, "f"),
				Reach = v(d, "f"),
				EnchantPts = v(d, "h"),
				ChopMin = v(d, "b"),
				ChopMax = v(d, "b"),
				SlashMin = v(d, "b"),
				SlashMax = v(d, "b"),
				ThrustMin = v(d, "b"),
				ThrustMax = v(d, "b"),
				Flags = v(d, "i")
			}
		end,
		ITEX = p.str,
		ENAM = p.str,
		SCRI = p.str
	},
	CONT = {
		NAME = p.str,
		MODL = p.str,
		FNAM = p.str,
		CNDT = p.float,
		FLAG = p.TODO,
		NPCO = p.TODO	
	},
	SPEL = {
		NAME = p.str,
		FNAM = p.str,
		SPDT = p.TODO,
		ENAM = p.TODO
	},
	CREA = {
		NAME = p.str,
		MODL = p.str,
		FNAM = p.str,
		NPDT = p.TODO,
		FLAG = p.TODO,
		SCRI = p.str,
		NPCO = p.TODO,
		AIDT = p.TODO,
		AI_W = p.TODO,
		AI_T = p.TODO,
		AI_F = p.TODO,
		AI_E = p.TODO,
		AI_A = p.TODO,
		XSCL = p.float
	},
	BODY = {
		BYDT = p.TODO
	},
	LIGH = {
		NAME = p.str,
		FNAM = p.str,
		LHDT = function(d)
			return {
				Weight = v(d, "f", 1),
				Value = v(d, "i"),
				Time = v(d, "i"),
				Radius = v(d, "i"),
				Red = v(d, "b"),
				Green = v(d, "b"),
				Blue = v(d, "b"),
				--ColorRef = v(d, "i"),
				Null = v(d, "b"),
				Flags = v(d, "i")
			}
		end,
		SCPT = p.str,
		ITEX = p.str,
		MODL = p.str,
		SNAM = p.str
	},
	ENCH = {
		NAME = p.str,
		ENDT = p.TODO,
		ENAM = p.TODO
	},
	NPC_ = {
		NAME = p.str,
		FNAM = p.str,
		MODL = p.str,
		RNAM = p.str,
		ANAM = p.str,
		BNAM = p.str,
		CNAM = p.str,
		KNAM = p.str,
		NPDT = p.TODO,
		FLAG = p.int,
		NPCO = p.TODO,
		NPCS = p.str,
		AIDT = p.TODO,
		AI_W = p.TODO,
		AI_T = p.TODO,
		AI_F = p.TODO,
		AI_E = p.TODO,
		CNDT = p.str,
		AI_A = p.TODO,
		DODT = p.TODO,
		DNAM = p.str,
		XSCL = p.float
	},
	ARMO = {
		NAME = p.str,
		MODL = p.str,
		FNAM = p.str,
		AODT = function(d)
			return {
				Type = v(d, "i", 1),
				Weight = v(d, "f"),
				Value = v(d, "i"),
				Health = v(d, "i"),
				EnchantPts = v(d, "i"),
				Armour = v(d, "i")
			}
		end,
		ITEX = p.str,
		INDX = p.byte,
		BNAM = p.str,
		CNAM = p.str,
		SCRI = p.str,
		ENAM = p.str
	},
	CLOT = {
		NAME = p.str,
		MODL = p.str,
		FNAM = p.str,
		CTDT = function(d)
			return {
				Type = v(d, "i", 1),
				Weight = v(d, "f"),
				Value = v(d, "h"),
				EnchantPts = v(d, "h")
			}
		end,
		ITEX = p.str,
		INDX = p.byte,
		BNAM = p.str,
		CNAM = p.str,
		ENAM = p.str,
		SCRI = p.str
	},
	REPA = {
		NAME = p.str,
		MODL = p.str,
		FNAM = p.str,
		RIDT = function(d)
			return {
				Weight = v(d, "f", 1),
				Value = v(d, "i"),
				Uses = v(d, "i"),
				Quality = v(d, "f")
			}
		end,
		ITEX = p.str,
		SCRI = p.str
	},
	ACTI = {
		NAME = p.str,
		MODL = p.str,
		FNAM = p.str,
		SCRI = p.str
	},
	APPA = {
		NAME = p.str,
		MODL = p.str,
		FNAM = p.str,
		AADT = function(d)
			return {
				Type = v(d, "i", 1),
				Quality = v(d, "f"),
				Weight = v(d, "f"),
				Value = v(d, "i")
			}
		end,
		ITEX = p.str,
		SCRI = p.str
	},
	LOCK = {
		NAME = p.str,
		MODL = p.str,
		FNAM = p.str,
		LKDT = function(d)
			return {
				Weight = v(d, "f", 1),
				Value = v(d, "i"),
				Quality = v(d, "f"),
				Uses = v(d, "i")
			}
		end,
		ITEX = p.str,
		SCRI = p.str
	},
	PROB = {
		NAME = p.str,
		MODL = p.str,
		FNAM = p.str,
		PBDT = function(d)
			return {
				Weight = v(d, "f", 1),
				Value = v(d, "i"),
				Quality = v(d, "f"),
				Uses = v(d, "i")
			}
		end,
		ITEX = p.str,
		SCRI = p.str
	},
	INGR = {
		NAME = p.str,
		MODL = p.str,
		FNAM = p.str,
		IRDT = function(d)
			return {
				Weight = v(d, "f", 1),
				Value = v(d, "i"),
				Effects = {
					v(d, "i"),
					v(d, "i"),
					v(d, "i"),
					v(d, "i")
				},
				Skills = {
					v(d, "i"),
					v(d, "i"),
					v(d, "i"),
					v(d, "i")
				},
				Attributes = {
					v(d, "i"),
					v(d, "i"),
					v(d, "i"),
					v(d, "i")
				}
			}
		end,
		ITEX = p.str,
		SCRI = p.str
	},
	BOOK = {
		NAME = p.str,
		MODL = p.str,
		FNAM = p.str,
		BKDT = function(d)
			return {
				Weight = v(d, "f", 1),
				Value = v(d, "i"),
				Scroll = v(d, "i"),
				Skill = v(d, "i"),
				EnchantPts = v(d, "i")
			}
		end,
		ITEX = p.str,
		SCRI = p.str,
		TEXT = p.str
	},
	ALCH = {
		NAME = p.str,
		MODL = p.str,
		FNAM = p.str,
		ALDT = function(d)
			return {
				Weight = v(d, "f", 1),
				Value = v(d, "i"),
				AutoCalc = v(d, "i")
			}
		end,
		ENAM = p.TODO,
		TEXT = p.str,
		SCRI = p.str
	},
	LEVI = {
		NAME = p.str,
		DATA = p.int,
		NNAM = p.byte,
		INDX = p.int,
		INAM = p.str,
		INTV = p.TODO
	},
	LEVC = {
		NAME = p.str,
		DATA = p.int,
		NNAM = p.byte,
		INDX = p.int,
		CNAM = p.str,
		INTV = p.TODO
	},
	CELL = {
		NAME = p.str,
		DATA = p.TODO,
		RGNN = p.str,
		NAM0 = p.int,

		NAM5 = p.int,

		WHGT = p.float,
		AMBI = p.TODO,

		--[[ TODO
		FRMR = f.int,
		NAME = f.str,
		XSCL = f.float,
		DELE = f.int,
		DODT = f.TODO,
		DNAM = f.str,
		FLTV = f.int,
		KNAM = f.str,
		TNAM = f.str,
		UNAM = f.byte,
		ANAM = f.str,
		BNAM = f.str,
		INTV = f.int,
		NAM9 = f.int,
		XSOL = f.str,
		DATA = f.TODO
		]]
	},
	LAND = {
		INTV = p.TODO,
		DATA = p.int,
		VNML = p.TODO,
		WNAM = p.TODO,
		VCLR = p.TODO,
		VTEX = p.TODO
	},
	PGRD = {  }, --TODO
	SNDG = {
		NAME = p.str,
		DATA = p.int,
		SNAM = p.str,
		CNAM = p.str
	},
	DIAL = {
		NAME = p.str,
		DATA = p.byte
	},
	INFO = {
		INAM = p.str,
		PNAM = p.str,
		NNAM = p.str,
		DATA = p.TODO,
		ONAM = p.str,
		RNAM = p.str,
		CNAM = p.str,
		FNAM = p.str,
		ANAM = p.str,
		DNAM = p.str,
		NAME = p.str,
		SNAM = p.str,
		QSTN = p.byte,
		QSTF = p.byte,
		QSTR = p.byte,
		SCVR = p.TODO,
		INTV = p.int, --TODO
		FLTV = p.float, --TODO
		BNAM = p.str --TODO
	}
}

function espParser.parseRecord(stream)
	local record = {}
	local header = stream:read(16)
	record.name = v(header, "c4", 1)
	record.size = v(header, "i")
	record.header1 = v(header, "i")
	record.flags = v(header, "i")

	record.subRecords = {}
	local finish = stream:seek() + record.size
	local srs = {}
	while stream:seek() < finish do
		local subRecord = espParser.parseSubRecord(stream, record.name)
		local value = subRecord.value or subRecord.data
		if srs[subRecord.name] then
			if srs[subRecord.name] == 1 then
				record.subRecords[subRecord.name] = { record.subRecords[subRecord.name], value }
			else
				table.insert(record.subRecords[subRecord.name], value)
			end
			srs[subRecord.name] = srs[subRecord.name]  + 1
		else
			record.subRecords[subRecord.name] = value
			srs[subRecord.name] = 1
		end
	end

	return record
end

function espParser.parseSubRecord(stream, recordName)
	local subRecord = {}
	local header = stream:read(8)
	subRecord.name = v(header, "c4", 1)
	subRecord.size = v(header, "i")
	subRecord.data = stream:read(subRecord.size)
	local recordParsers = subRecordParsers[recordName]
	if recordParsers and recordParsers[subRecord.name] then
		subRecord.value = recordParsers[subRecord.name](subRecord.data)
	end
	subRecord.value = subRecord.value or subRecord.data
	return subRecord
end

--Global Function

espParser.processFiles = function()
	local files
    if espParser.config.requiredDataFiles then
        files = jsonInterface.load("requiredDataFiles.json")
    else
        files = espParser.config.files
	end

	tes3mp.LogMessage(enumerations.log.INFO, "[espParser] Started")
	customEventHooks.triggerHandlers("espParser_Start", customEventHooks.makeEventStatus(true, true), {files})

    for i = 1, #files do
		for file, _ in pairs(files[i]) do
			tes3mp.LogMessage(enumerations.log.INFO, "[espParser] Loading: " .. file)
			customEventHooks.triggerHandlers("espParser_File", customEventHooks.makeEventStatus(true, true), {file})
			local fullPath = tes3mp.GetDataPath() .. "/" .. espParser.config.espPath .. file
			fullPath = fullPath:gsub("\\", "/")
			local f = io.open(fullPath, "rb")

			if f == nil then error("[espParser] Could not open " .. fullPath) end
			while f:read(0) do
				local record = espParser.parseRecord(f)
				customEventHooks.triggerHandlers("espParser_Record", customEventHooks.makeEventStatus(true, true), {record, file})
			end
			customEventHooks.triggerHandlers("espParser_FileDone", customEventHooks.makeEventStatus(true, true), {file})
        end
	end

	tes3mp.LogMessage(enumerations.log.INFO, "[espParser] Finished")
	customEventHooks.triggerHandlers("espParser_Finish", customEventHooks.makeEventStatus(true, true), {files})
end

customEventHooks.registerHandler("OnServerInit", function()
	if espParser.config.loadOnStart then
		espParser.processFiles()
	end
end)

serverCommandHooks.registerCommand("espparser", function()
	espParser.processFiles()
end)