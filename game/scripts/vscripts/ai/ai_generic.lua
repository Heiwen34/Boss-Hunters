--[[
Broodking AI
]]

require( "ai/ai_core" )

-- GENERIC AI FOR SIMPLE CHASE ATTACKERS

function Spawn( entityKeyValues )
	Timers:CreateTimer(function()
		if thisEntity and not thisEntity:IsNull() then
			return AIThink(thisEntity)
		end
	end)
end


function AIThink(thisEntity)
	if thisEntity and not thisEntity:IsNull() then
		if not thisEntity:IsDominated() then
			AICore:AttackHighestPriority( thisEntity )
			return 0.25
		else return 0.25 end
	end
end