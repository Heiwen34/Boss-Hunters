LinkLuaModifier( "modifier_fury_swipes_bonus_damage", "scripts/vscripts/lua_abilities/heroes/ursa.lua" ,LUA_MODIFIER_MOTION_NONE )

function fury_swipes_check_stacks( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local modifierName = "modifier_fury_swipes_target"
	local modifierNameB = "modifier_fury_swipes_bonus_damage"
	
	target.stacks = target:GetModifierStackCount( modifierName, ability )
	ability:ApplyDataDrivenModifier( caster, caster, modifierNameB, {} )
end

function ScepterFunction(keys) -- handles purge rules
	local caster = keys.caster
	local ability = keys.ability
	
	local RemovePositiveBuffs = false
	local RemoveDebuffs = true
	local BuffsCreatedThisFrameOnly = false
	local RemoveStuns = false
	local RemoveExceptions = false
	if caster:HasScepter() then
		RemoveStuns = true
		RemoveExceptions = true
		ability:ApplyDataDrivenModifier(caster,caster, "modifier_claw_scepter", {})
	end
	
	local duration = ability:GetTalentSpecialValueFor("duration")
	caster:Purge( RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
	ability:ApplyDataDrivenModifier( caster, caster, "Modifier_Claw", {duration = duration} )
	ability:ApplyDataDrivenModifier( caster, caster, "modifier_claw_damage_reduction", {duration = duration} )
	ability:ApplyDataDrivenModifier( caster, caster, "modifier_ursa_enrage", {duration = duration} )
end

function fury_swipes_attack( keys )
	-- Variables
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local modifierName = "modifier_fury_swipes_target"
	local damageType = ability:GetAbilityDamageType()
	
	if target:IsBuilding() then return end
	if caster:IsIllusion() then return end

	-- Necessary value from KV
	local duration = ability:GetTalentSpecialValueFor( "duration")

	local current_stack = target.stacks or 1

	-- Check if unit already have stack
	-- Apply modifier to target
	ability:ApplyDataDrivenModifier( caster, target, modifierName, { Duration = duration } )
	target:SetModifierStackCount( modifierName, ability, current_stack )
	
	if caster:HasModifier( "modifier_claw_scepter" ) then
        local ability_claw = caster:FindAbilityByName("ursa_claw")
		local damage = ( target.stacks ) * (ability:GetTalentSpecialValueFor("bonus_damage_per_stack"))
        local percent = ability_claw:GetTalentSpecialValueFor("Pierce_percent_fury")*0.01
        local multiplier = ability_claw:GetTalentSpecialValueFor("physical_fury_damage_mult")*0.01
        local damageTable_fury = {victim = target,
                        attacker = caster,
                        damage = damage*percent*multiplier/get_aether_multiplier(caster),
                        ability = keys.ability,
                        damage_type = DAMAGE_TYPE_PURE,
                        }
        ApplyDamage(damageTable_fury)
    end
	

end

-- FURY SWIPES DAMAGE MODIFIERS
if modifier_fury_swipes_bonus_damage == nil then
	modifier_fury_swipes_bonus_damage = class({})
end

function modifier_fury_swipes_bonus_damage:DeclareFunctions()
	return 
	{ 
		MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL,
	}
end

function modifier_fury_swipes_bonus_damage:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
function modifier_fury_swipes_bonus_damage:IsHidden()
	return true
end

function modifier_fury_swipes_bonus_damage:GetModifierProcAttack_BonusDamage_Physical(params)
    local caster = params.attacker
    local target = params.target
	local multiplier = 1
	local adder = 1
    if caster:IsIllusion() then return 0 end
	if caster:HasModifier( "Modifier_Claw" ) then
        local ability_claw = caster:FindAbilityByName("ursa_claw")
		multiplier = ability_claw:GetTalentSpecialValueFor("physical_fury_damage_mult")*0.01
	end
	if caster:HasModifier( "modifier_overpower_buff_datadriven" ) and caster:HasScepter() then
		adder = caster:FindAbilityByName("ursa_overpower_ebf"):GetTalentSpecialValueFor("fury_swipes_per_hit_scepter")
	end
	local nFurySwipes = ( target.stacks + adder) * (self:GetAbility():GetTalentSpecialValueFor("bonus_damage_per_stack")) * multiplier
    
    target.stacks = target.stacks + adder
    return nFurySwipes
end

function Pierce_skill(keys)
    local caster = keys.caster
    local target = keys.target
    local ability = keys.ability
    local percent = ability:GetTalentSpecialValueFor("Pierce_percent", ability:GetLevel()-1)
    local damage = keys.damage_on_hit*percent*0.01
    local damageTable = {victim = target,
                attacker = caster,
                damage = damage/get_aether_multiplier(caster),
                ability = keys.ability,
                damage_type = DAMAGE_TYPE_PURE,
                }
    ApplyDamage(damageTable)
end

function overpower_init( keys )
	local caster = keys.caster
	local ability = keys.ability
	local modifierName = "modifier_overpower_buff_datadriven"
	local duration = ability:GetTalentSpecialValueFor( "duration_tooltip")
	local max_stack = ability:GetTalentSpecialValueFor( "max_attacks")
	
	ability:ApplyDataDrivenModifier( caster, caster, modifierName, { } )
	ability:ApplyDataDrivenModifier( caster, caster, "modifier_overpower_attackspeed", {duration = duration} )
	caster:SetModifierStackCount( modifierName, ability, max_stack )
end

function overpower_decrease_stack( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	
	local max_stack = ability:GetTalentSpecialValueFor( "max_attacks")
	local armorreduc = ability:GetTalentSpecialValueFor( "debuff_minus_armor")
	local armorreducperc = ability:GetTalentSpecialValueFor( "debuff_altminus_armor") / 100
	local armor = target:GetPhysicalArmorBaseValue()
	
	local modifierName = "modifier_overpower_buff_datadriven"
	local demodifierName = "modifier_overpower_debuff_datadriven"
	if math.abs(max_stack*armorreduc) < math.abs(max_stack*armorreducperc*armor) then
		demodifierName = "modifier_overpower_altdebuff_datadriven"
	end
	local current_stack = caster:GetModifierStackCount( modifierName, ability )
	local current_destack = target:GetModifierStackCount( demodifierName, ability )
	local duration = ability:GetTalentSpecialValueFor("debuff_duration")
	if demodifierName == "modifier_overpower_altdebuff_datadriven" then
		local stackmodifier = "modifier_overpower_altdebuff_datadriven_stacks"
		local sunder = armorreducperc*armor
		target:RemoveModifierByName(stackmodifier)
		ability:ApplyDataDrivenModifier( caster, target, stackmodifier, {duration = duration} )
		target:SetModifierStackCount( stackmodifier, ability, (current_destack + 1 ) * sunder)
	end
	
	
	
	-- PLACE AND REFRESH DEBUFF --
	target:RemoveModifierByName(demodifierName)
	ability:ApplyDataDrivenModifier( caster, target, demodifierName, {duration = duration} )
	target:SetModifierStackCount( demodifierName, ability, current_destack + 1)
	
	if current_stack > 1 then
		caster:SetModifierStackCount( modifierName, ability, current_stack - 1 )
	else
		caster:RemoveModifierByName( modifierName )
	end
end