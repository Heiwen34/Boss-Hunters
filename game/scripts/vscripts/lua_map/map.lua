MapHandler = class({})

MIN_POS_Y = -8191
MAX_POS_Y = 8191

MIN_POS_X = -8191
MAX_POS_X = 8191

MIN_POS_Z = 0

SPAWN_POS = GetGroundPosition(Vector(6456, 6944, 0), nil)

function MapHandler:CheckAndResolvePositions(hero)
	hero.lastAllowedPosition = hero.lastAllowedPosition or hero:GetAbsOrigin()
	if MapHandler:IsOutsideMapBounds(hero) then
		FindClearSpaceForUnit(hero, hero.lastAllowedPosition, true)
		hero:StopMotionControllers(true)
		return
	end
	if RoundManager.boundingBox and Entities:FindByName(nil, RoundManager.boundingBox.."_edge_collider") and hero then
		local collider = Entities:FindByName(nil, RoundManager.boundingBox.."_edge_collider")
		local dist = math.max(  FindRadius(collider) * 1.2, math.max(FindWidth(collider) * 1.1, FindLength(collider) * 1.1 ) )
		if CalculateDistance( hero, collider ) > dist then
			FindClearSpaceForUnit(hero, RoundManager:GetCurrentEvent():GetHeroSpawnPosition(), true)
		end
	end
	if GridNav:IsTraversable(hero:GetAbsOrigin()) then
		hero.lastAllowedPosition = hero:GetAbsOrigin()
	end
end

function OnWaterEnter(trigger)
    local ent = trigger.activator
	if not ent then return end
    ent.InWater = true

    if ent:IsHero() then
    	ent:AddNewModifier(ent, nil, "modifier_in_water", {})
    end
end

function OnWaterExit(trigger)
    local ent = trigger.activator
    if not ent then return end
    ent.InWater = false
    ent:RemoveModifierByName("modifier_in_water")
    return
end

function MapHandler:IsOutsideMapBounds(unit)
	local unitPos = unit:GetAbsOrigin()
	return (unitPos.x > MAX_POS_X or unitPos.x < MIN_POS_X) or (unitPos.y > MAX_POS_Y or unitPos.y < MIN_POS_Y) or (unitPos.z < MIN_POS_Z)
end

function FindWidth(unit)
	local width = 0
	for tag, vector in pairs( unit:GetBounds() ) do
		if math.abs(vector.x) < math.abs(vector.y) then
			width = width + math.abs(vector.x)
		else
			width = width + math.abs(vector.y)
		end
	end
	return width
end

function FindLength(unit)
	local length = 0
	for tag, vector in pairs( unit:GetBounds() ) do
		if math.abs(vector.x) > math.abs(vector.y) then
			length = length + math.abs(vector.x)
		else
			length = length + math.abs(vector.y)
		end
	end
	return length
end

function FindRadius(unit)
	local radius = 0
	local count = 0
	for tag, vector in pairs( unit:GetBounds() ) do
		count = count + 1
		radius = math.abs(vector.x) + math.abs(vector.y)
	end
	radius = radius / count
	return radius
end

function LeftBoundingBox(trigger)
	local unit = trigger.activator
	local edge = trigger.caller
	local distance = 0
	if RoundManager.boundingBox and unit and edge then
		if edge:GetName() == RoundManager.boundingBox.."_edge_collider" and not edge:IsTouching(unit) and unit.lastAllowedPosition then
			FindClearSpaceForUnit( unit, GetGroundPosition( unit.lastAllowedPosition, unit ), true )
			GridNav:DestroyTreesAroundPoint( unit.lastAllowedPosition, 120, true )
			unit:StopMotionControllers(true)
		end
	end
end