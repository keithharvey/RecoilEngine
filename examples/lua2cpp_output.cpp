// Generated C++ code from Lua script using Lua2Cpp system
// Original file: lua2cpp_example.lua

#include <memory>
#include <string>
#include <vector>
#include <cmath>
#include <algorithm>
#include <iostream>

// Spring RTS includes
#include "Sim/Units/Unit.h"
#include "Sim/Units/UnitDef.h"
#include "Sim/Weapons/Weapon.h"
#include "System/Log/ILog.h"
#include "System/SpringMath.h"

// Generated unit class
class CommanderUnit {
private:
    // Unit properties
    std::string name;
    double health;
    double maxHealth;
    double armor;
    double speed;
    bool isAlive;
    
    // Position and state
    float3 position;
    int team;
    
    // Spring engine references
    CUnit* springUnit;
    
public:
    CommanderUnit() 
        : name("Commander")
        , health(1000.0)
        , maxHealth(1000.0)
        , armor(10.0)
        , speed(5.0)
        , isAlive(false)
        , team(0)
        , springUnit(nullptr) {
    }
    
    ~CommanderUnit() = default;
    
    // Unit behavior functions
    bool Create() {
        LOG("Unit created: " + name);
        health = maxHealth;
        isAlive = true;
        return true;
    }
    
    bool TakeDamage(double damage, const std::string& weaponType) {
        if (!isAlive) {
            return false;
        }
        
        double actualDamage = damage - armor;
        if (actualDamage < 0) {
            actualDamage = 0;
        }
        
        health = health - actualDamage;
        
        if (health <= 0) {
            Die();
            return true;
        }
        
        // Visual feedback
        if (actualDamage > 50) {
            LOG("Unit " + name + " took heavy damage: " + std::to_string(actualDamage));
        }
        
        return false;
    }
    
    bool Heal(double amount) {
        if (!isAlive) {
            return false;
        }
        
        health = std::min(health + amount, maxHealth);
        LOG("Unit " + name + " healed to " + std::to_string(health) + "/" + std::to_string(maxHealth));
        return true;
    }
    
    bool Die() {
        isAlive = false;
        health = 0;
        LOG("Unit " + name + " has been destroyed!");
        
        // Create explosion effect
        float3 pos = GetPosition();
        Spring::CreateExplosion(pos.x, pos.y, pos.z, "commander_explosion");
        
        return true;
    }
    
    bool MoveTo(const float3& targetPos) {
        if (!isAlive) {
            return false;
        }
        
        float3 currentPos = GetPosition();
        double distance = std::sqrt(
            std::pow(targetPos.x - currentPos.x, 2) + 
            std::pow(targetPos.y - currentPos.y, 2) + 
            std::pow(targetPos.z - currentPos.z, 2)
        );
        
        if (distance < 10) {
            LOG("Unit " + name + " reached target");
            return true;
        }
        
        // Calculate movement
        float3 direction(
            (targetPos.x - currentPos.x) / distance,
            (targetPos.y - currentPos.y) / distance,
            (targetPos.z - currentPos.z) / distance
        );
        
        float3 newPos(
            currentPos.x + direction.x * speed,
            currentPos.y + direction.y * speed,
            currentPos.z + direction.z * speed
        );
        
        SetPosition(newPos);
        return false;
    }
    
    bool Attack(CommanderUnit* target) {
        if (!isAlive) {
            return false;
        }
        
        if (!target || !target->isAlive) {
            return false;
        }
        
        double weaponDamage = 100.0;
        double weaponRange = 50.0;
        
        float3 myPos = GetPosition();
        float3 targetPos = target->GetPosition();
        
        double distance = std::sqrt(
            std::pow(targetPos.x - myPos.x, 2) + 
            std::pow(targetPos.y - myPos.y, 2) + 
            std::pow(targetPos.z - myPos.z, 2)
        );
        
        if (distance > weaponRange) {
            LOG("Target out of range!");
            return false;
        }
        
        // Deal damage to target
        target->TakeDamage(weaponDamage, "laser");
        
        // Visual feedback
        LOG("Unit " + name + " attacks for " + std::to_string(weaponDamage) + " damage");
        
        return true;
    }
    
    void Update() {
        if (!isAlive) {
            return;
        }
        
        // Regenerate health slowly
        if (health < maxHealth) {
            Heal(1.0);
        }
        
        // Check for nearby enemies
        std::vector<int> enemies = Spring::GetUnitsInRadius(GetPosition(), 100.0);
        for (int enemyID : enemies) {
            CUnit* enemy = Spring::GetUnitByID(enemyID);
            if (enemy && enemy->team != team) {
                // Note: This would need proper type conversion in real implementation
                // CommanderUnit* enemyUnit = static_cast<CommanderUnit*>(enemy);
                // Attack(enemyUnit);
                break;
            }
        }
    }
    
    // Animation functions
    bool PlayAnimation(const std::string& animName, double speed) {
        if (!isAlive) {
            return false;
        }
        
        LOG("Playing animation: " + animName + " at speed " + std::to_string(speed));
        return true;
    }
    
    bool StopAnimation() {
        LOG("Stopping current animation");
        return true;
    }
    
    // Utility functions
    double GetHealthPercentage() const {
        return (health / maxHealth) * 100.0;
    }
    
    bool IsDamaged() const {
        return health < maxHealth;
    }
    
    bool IsCritical() const {
        return health < (maxHealth * 0.25);
    }
    
    // Getters and setters
    const std::string& GetName() const { return name; }
    double GetHealth() const { return health; }
    double GetMaxHealth() const { return maxHealth; }
    double GetArmor() const { return armor; }
    double GetSpeed() const { return speed; }
    bool IsAlive() const { return isAlive; }
    
    void SetHealth(double h) { health = h; }
    void SetMaxHealth(double mh) { maxHealth = mh; }
    void SetArmor(double a) { armor = a; }
    void SetSpeed(double s) { speed = s; }
    
    float3 GetPosition() const {
        if (springUnit) {
            return springUnit->pos;
        }
        return position;
    }
    
    void SetPosition(const float3& pos) {
        position = pos;
        if (springUnit) {
            springUnit->pos = pos;
        }
    }
    
    void SetSpringUnit(CUnit* unit) {
        springUnit = unit;
        if (unit) {
            team = unit->team;
        }
    }
    
private:
    void LOG(const std::string& message) {
        // In real implementation, this would use Spring's logging system
        std::cout << "[CommanderUnit] " << message << std::endl;
    }
};

// Factory function to create unit instances
std::unique_ptr<CommanderUnit> CreateCommanderUnit() {
    return std::make_unique<CommanderUnit>();
}

// Memory management wrapper
class CommanderUnitWrapper {
private:
    std::unique_ptr<CommanderUnit> unit;
    
public:
    CommanderUnitWrapper() : unit(std::make_unique<CommanderUnit>()) {}
    
    CommanderUnit* GetUnit() { return unit.get(); }
    const CommanderUnit* GetUnit() const { return unit.get(); }
    
    // RAII - automatic cleanup
    ~CommanderUnitWrapper() = default;
};

// Export for Spring RTS integration
extern "C" {
    CommanderUnit* CreateCommanderUnit_C() {
        return new CommanderUnit();
    }
    
    void DestroyCommanderUnit_C(CommanderUnit* unit) {
        delete unit;
    }
    
    bool CommanderUnit_Create(CommanderUnit* unit) {
        return unit->Create();
    }
    
    bool CommanderUnit_TakeDamage(CommanderUnit* unit, double damage, const char* weaponType) {
        return unit->TakeDamage(damage, std::string(weaponType));
    }
    
    bool CommanderUnit_Heal(CommanderUnit* unit, double amount) {
        return unit->Heal(amount);
    }
    
    bool CommanderUnit_Die(CommanderUnit* unit) {
        return unit->Die();
    }
    
    bool CommanderUnit_MoveTo(CommanderUnit* unit, float x, float y, float z) {
        return unit->MoveTo(float3(x, y, z));
    }
    
    bool CommanderUnit_Attack(CommanderUnit* unit, CommanderUnit* target) {
        return unit->Attack(target);
    }
    
    void CommanderUnit_Update(CommanderUnit* unit) {
        unit->Update();
    }
    
    bool CommanderUnit_PlayAnimation(CommanderUnit* unit, const char* animName, double speed) {
        return unit->PlayAnimation(std::string(animName), speed);
    }
    
    bool CommanderUnit_StopAnimation(CommanderUnit* unit) {
        return unit->StopAnimation();
    }
    
    double CommanderUnit_GetHealthPercentage(CommanderUnit* unit) {
        return unit->GetHealthPercentage();
    }
    
    bool CommanderUnit_IsDamaged(CommanderUnit* unit) {
        return unit->IsDamaged();
    }
    
    bool CommanderUnit_IsCritical(CommanderUnit* unit) {
        return unit->IsCritical();
    }
} 