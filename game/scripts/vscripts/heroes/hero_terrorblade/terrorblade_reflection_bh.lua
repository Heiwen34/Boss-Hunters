terrorblade_reflection_bh = class({})

function terrorblade_reflection_bh:GetAOERadius()
	return self:GetTalentSpecialValueFor("radius")
end

function terrorblade_reflection_bh:OnSpellStart()
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()
	
	local radius = self:GetTalentSpecialValueFor("radius")
	local outgoing = self:GetTalentSpecialValueFor("illusion_outgoing_damage")
	local illusions = self:GetTalentSpecialValueFor("illusion_count")
	local duration = self:GetTalentSpecialValueFor("duration")
	
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( position, radius ) ) do
		enemy:AddNewModifier( caster, self, "modifier_terrorblade_reflection_bh_slow", {duration = duration})
	end
	
	for _, hero in ipairs( HeroList:GetRealHeroes() ) do
		for i = 1, illusions do
			local reflection = self:CreateReflection( hero, position + ActualRandomVector( radius, 125 ), duration, outgoing, caster )
			reflection:MoveToPositionAggressive( position )
		end
	end
end

function terrorblade_reflection_bh:CreateReflection( hero, position, duration, outgoing, caster)
	local illusion = hero:ConjureImage( position, duration, 100 - outgoing, -100, "modifier_terrorblade_conjureimage", self, false, caster )
	illusion:AddNewModifier(caster, self, "modifier_terrorblade_reflection_bh_illusion", {})
	
	illusion:AddAbility("terrorblade_zeal")
	return illusion
end

modifier_terrorblade_reflection_bh_illusion = class({})
LinkLuaModifier( "modifier_terrorblade_reflection_bh_illusion", "heroes/hero_terrorblade/terrorblade_reflection_bh", LUA_MODIFIER_MOTION_NONE )

function modifier_terrorblade_reflection_bh_illusion:CheckState()
	return {[MODIFIER_STATE_ATTACK_IMMUNE] = true,
			[MODIFIER_STATE_INVULNERABLE] = true,
			[MODIFIER_STATE_MAGIC_IMMUNE] = true,
			[MODIFIER_STATE_UNSELECTABLE] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
			[MODIFIER_STATE_UNTARGETABLE] = true,}
end

function modifier_terrorblade_reflection_bh_illusion:IsHidden()
	return true
end

modifier_terrorblade_reflection_bh_slow = class({})
LinkLuaModifier( "modifier_terrorblade_reflection_bh_slow", "heroes/hero_terrorblade/terrorblade_reflection_bh", LUA_MODIFIER_MOTION_NONE )

function modifier_terrorblade_reflection_bh_slow:OnCreated()
	self.slow = self:GetTalentSpecialValueFor("slow")
end

function modifier_terrorblade_reflection_bh_slow:OnRefresh()
	self.slow = self:GetTalentSpecialValueFor("slow")
end

function modifier_terrorblade_reflection_bh_slow:CheckState()
	return {[MODIFIER_STATE_ROOTED] = self:GetCaster():HasTalent("special_bonus_unique_terrorblade_reflection_2")}
end

function modifier_terrorblade_reflection_bh_slow:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_terrorblade_reflection_bh_slow:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end