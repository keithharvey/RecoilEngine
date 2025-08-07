-- Example Lua script for Spring RTS unit behavior
-- This would be converted to C++ using the Lua2Cpp system

local unit = {}
unit.name = "Commander"
unit.health = 1000
unit.maxHealth = 1000
unit.armor = 10
unit.speed = 5.0

-- Unit behavior functions
function unit:Create()
    Spring.Echo("Unit created: " .. self.name)
    self.health = self.maxHealth
    self.isAlive = true
    return true
end

function unit:TakeDamage(damage, weaponType)
    if not self.isAlive then
        return false
    end
    
    local actualDamage = damage - self.armor
    if actualDamage < 0 then
        actualDamage = 0
    end
    
    self.health = self.health - actualDamage
    
    if self.health <= 0 then
        self:Die()
        return true
    end
    
    -- Visual feedback
    if actualDamage > 50 then
        Spring.Echo("Unit " .. self.name .. " took heavy damage: " .. actualDamage)
    end
    
    return false
end

function unit:Heal(amount)
    if not self.isAlive then
        return false
    end
    
    self.health = math.min(self.health + amount, self.maxHealth)
    Spring.Echo("Unit " .. self.name .. " healed to " .. self.health .. "/" .. self.maxHealth)
    return true
end

function unit:Die()
    self.isAlive = false
    self.health = 0
    Spring.Echo("Unit " .. self.name .. " has been destroyed!")
    
    -- Create explosion effect
    local pos = self:GetPosition()
    Spring.CreateExplosion(pos.x, pos.y, pos.z, "commander_explosion")
    
    return true
end

function unit:MoveTo(targetPos)
    if not self.isAlive then
        return false
    end
    
    local currentPos = self:GetPosition()
    local distance = math.sqrt(
        (targetPos.x - currentPos.x)^2 + 
        (targetPos.y - currentPos.y)^2 + 
        (targetPos.z - currentPos.z)^2
    )
    
    if distance < 10 then
        Spring.Echo("Unit " .. self.name .. " reached target")
        return true
    end
    
    -- Calculate movement
    local direction = {
        x = (targetPos.x - currentPos.x) / distance,
        y = (targetPos.y - currentPos.y) / distance,
        z = (targetPos.z - currentPos.z) / distance
    }
    
    local newPos = {
        x = currentPos.x + direction.x * self.speed,
        y = currentPos.y + direction.y * self.speed,
        z = currentPos.z + direction.z * self.speed
    }
    
    self:SetPosition(newPos)
    return false
end

function unit:Attack(target)
    if not self.isAlive then
        return false
    end
    
    if not target or not target.isAlive then
        return false
    end
    
    local weaponDamage = 100
    local weaponRange = 50
    
    local myPos = self:GetPosition()
    local targetPos = target:GetPosition()
    
    local distance = math.sqrt(
        (targetPos.x - myPos.x)^2 + 
        (targetPos.y - myPos.y)^2 + 
        (targetPos.z - myPos.z)^2
    )
    
    if distance > weaponRange then
        Spring.Echo("Target out of range!")
        return false
    end
    
    -- Deal damage to target
    target:TakeDamage(weaponDamage, "laser")
    
    -- Visual feedback
    Spring.Echo("Unit " .. self.name .. " attacks for " .. weaponDamage .. " damage")
    
    return true
end

function unit:Update()
    if not self.isAlive then
        return
    end
    
    -- Regenerate health slowly
    if self.health < self.maxHealth then
        self:Heal(1)
    end
    
    -- Check for nearby enemies
    local enemies = Spring.GetUnitsInRadius(self:GetPosition(), 100)
    for i, enemyID in ipairs(enemies) do
        local enemy = Spring.GetUnitByID(enemyID)
        if enemy and enemy.team ~= self.team then
            self:Attack(enemy)
            break
        end
    end
end

-- Animation functions
function unit:PlayAnimation(animName, speed)
    if not self.isAlive then
        return false
    end
    
    Spring.Echo("Playing animation: " .. animName .. " at speed " .. speed)
    return true
end

function unit:StopAnimation()
    Spring.Echo("Stopping current animation")
    return true
end

-- Utility functions
function unit:GetHealthPercentage()
    return (self.health / self.maxHealth) * 100
end

function unit:IsDamaged()
    return self.health < self.maxHealth
end

function unit:IsCritical()
    return self.health < (self.maxHealth * 0.25)
end

-- Return the unit object
return unit 