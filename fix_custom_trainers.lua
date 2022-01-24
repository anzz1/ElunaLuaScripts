
-- so yeah the default SkillRaceClassInfo.dbc (3.3.5.12340) has an oversight and the DK frost skill tree (771) has been
-- marked twice and the duplicate entry has wrong classmask, so if you want to make a custom trainer with all classes spells
-- then annoyingly you will see dk frost spells on all other classes too. you could remove either that entry from the skillraceclassinfo.dbc
-- or change the spell class mask in spell.dbc. also warlock mounts have the similar issue of wrong class mask in spell.dbc, but paladin mounts work fine.
-- anyway,
--
-- tl;dr: custom trainers with all class spells work now with only this fix. no more warlock mount or dk frost spells in trainer menu for other classes.

local DK_FROST_SPELLS = {3714,51416,51417,57330,51423,56815,51418,51409,51424,51419,57623,51410,51425,55268,51411}

require("ObjectVariables")

local CLASS_DEATHKNIGHT     = 6
local CLASS_WARLOCK         = 9

local SPELL_PKT_SIZE = 38 -- (4+1+4+4+4+1+4+4+4+4+4)

local function onSendTrainerList(event, packet, player)
    if (player:GetData("_trainerfix_skip_hook")) then
        player:SetData("_trainerfix_skip_hook", nil)
        return true
    end

    local class = player:GetClass()
    local trainerGUID = packet:ReadGUID()
    local trainerType = packet:ReadLong()
    local spellCount = packet:ReadLong()

    local c = 0
    local newSpells = {}
    for i = 1, spellCount do
        local spellId = packet:ReadLong()
        local skip = false

        if (class ~= CLASS_WARLOCK and (spellId == 1710 or spellId == 23161)) then
            skip = true
        end
        if (not skip and class ~= CLASS_DEATHKNIGHT) then
            for _, v in ipairs(DK_FROST_SPELLS) do
                if(spellId == v) then
                    skip = true
                    break
                end
            end
        end
        if (skip) then
            packet:ReadUByte() -- usable
            packet:ReadLong()  -- moneyCost
            packet:ReadLong()  -- pointCost1
            packet:ReadLong()  -- pointCost2
            packet:ReadUByte() -- reqLevel
            packet:ReadLong()  -- reqSkillLine
            packet:ReadLong()  -- reqSkillRank
            packet:ReadLong()  -- reqAbility1
            packet:ReadLong()  -- reqAbility2
            packet:ReadLong()  -- reqAbility3
        else
            c = c + 1
            newSpells[c] = {}
            newSpells[c].spellId = spellId
            newSpells[c].usable = packet:ReadUByte()
            newSpells[c].moneyCost = packet:ReadLong()
            newSpells[c].pointCost1 = packet:ReadLong()
            newSpells[c].pointCost2 = packet:ReadLong()
            newSpells[c].reqLevel = packet:ReadUByte()
            newSpells[c].reqSkillLine = packet:ReadLong()
            newSpells[c].reqSkillRank = packet:ReadLong()
            newSpells[c].reqAbility1 = packet:ReadLong()
            newSpells[c].reqAbility2 = packet:ReadLong()
            newSpells[c].reqAbility3 = packet:ReadLong()
        end
    end
    local greeting = packet:ReadString()

    if (#newSpells ~= spellCount) then
        local newpacket = CreatePacket(433, packet:GetSize()-((spellCount-#newSpells)*SPELL_PKT_SIZE))
        newpacket:WriteGUID(trainerGUID)
        newpacket:WriteLong(trainerType)
        newpacket:WriteLong(c)
        for i = 1, c do
            newpacket:WriteLong(newSpells[i].spellId)
            newpacket:WriteUByte(newSpells[i].usable)
            newpacket:WriteLong(newSpells[i].moneyCost)
            newpacket:WriteLong(newSpells[i].pointCost1)
            newpacket:WriteLong(newSpells[i].pointCost2)
            newpacket:WriteUByte(newSpells[i].reqLevel)
            newpacket:WriteLong(newSpells[i].reqSkillLine)
            newpacket:WriteLong(newSpells[i].reqSkillRank)
            newpacket:WriteLong(newSpells[i].reqAbility1)
            newpacket:WriteLong(newSpells[i].reqAbility2)
            newpacket:WriteLong(newSpells[i].reqAbility3)
        end
        newpacket:WriteString(greeting)
        player:SetData("_trainerfix_skip_hook", true)
        player:SendPacket(newpacket)
        return false
    end
    return true
end

RegisterPacketEvent(433, 7, onSendTrainerList) -- PACKET_EVENT_ON_PACKET_SEND (SMSG_TRAINER_LIST)
