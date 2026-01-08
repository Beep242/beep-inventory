function suiteffect(class,time,pos,target)
    local e = ents.Create(class)
    if not IsValid(e) then return end
    e:SetPos(pos)
    e:Spawn()
    if IsValid(target) then
        e:SetParent(target)
    end
    e:time(time)
end


BCORE.Inventory:CreateSuit("BP1 Crusader", {
    Health = {
        Common={min=400,max=1200}, Uncommon={min=1200,max=2500}, Rare={min=2500,max=4000},
        Epic={min=4000,max=7000}, Legendary={min=7000,max=12000}, Celestial={min=12000,max=20000},
        God={min=20000,max=30000}, Glitched={min=30000,max=50000}, ["????????"]={min=50000,max=100000}
    },
    Armor = {
        Common={min=40,max=180}, Uncommon={min=180,max=350}, Rare={min=350,max=700},
        Epic={min=700,max=1500}, Legendary={min=1500,max=3000}, Celestial={min=3000,max=6000},
        God={min=6000,max=12000}, Glitched={min=12000,max=25000}, ["????????"]={min=25000,max=50000}
    },
    Resistance = {
        Common={min=0.5,max=0.8}, Uncommon={min=0.45,max=0.75}, Rare={min=0.4,max=0.7},
        Epic={min=0.35,max=0.65}, Legendary={min=0.3,max=0.6}, Celestial={min=0.25,max=0.55},
        God={min=0.2,max=0.5}, Glitched={min=0.15,max=0.45}, ["????????"]={min=0.1,max=0.4}
    },
    Speed = {
        Common={min=1.1,max=1.4}, Uncommon={min=1.2,max=1.5}, Rare={min=1.3,max=1.6},
        Epic={min=1.4,max=1.7}, Legendary={min=1.5,max=1.8}, Celestial={min=1.6,max=2.0},
        God={min=1.7,max=2.2}, Glitched={min=1.8,max=2.5}, ["????????"]={min=2.0,max=3.0}
    },
    Jump = {
        Common={min=1.0,max=1.3}, Uncommon={min=1.1,max=1.4}, Rare={min=1.2,max=1.5},
        Epic={min=1.3,max=1.6}, Legendary={min=1.4,max=1.7}, Celestial={min=1.5,max=1.8},
        God={min=1.6,max=2.0}, Glitched={min=1.7,max=2.2}, ["????????"]={min=1.8,max=2.5}
    },
    Regen = {
        Common={min=3,max=7}, Uncommon={min=7,max=15}, Rare={min=15,max=25},
        Epic={min=25,max=40}, Legendary={min=40,max=60}, Celestial={min=60,max=100},
        God={min=100,max=150}, Glitched={min=150,max=250}, ["????????"]={min=250,max=500}
    }
}, "Wield the power of holy crusades with unstoppable force.", "models/player/charple.mdl",
function(ply,dmginfo,item)
    if ply.DeflectActive then
        dmginfo:SetDamage(0)
    else
        dmginfo:SetDamage(dmginfo:GetDamage() * (item.customData.Resistance or 1))
    end
end,
{
    DashStrike = {KeyBind=KEY_E, Cooldown=10, LastUsed=0, description="Dash forward quickly and strike all enemies in your path.", Action=function(ply)
        local vel = ply:GetForward() * 1000
        ply:SetVelocity(vel)
        for _, ent in ipairs(ents.FindInSphere(ply:GetPos() + ply:GetForward()*50, 100)) do
            if ent:IsPlayer() and ent ~= ply then
                local dmg = DamageInfo()
                dmg:SetDamage(50)
                dmg:SetAttacker(ply)
                dmg:SetInflictor(ply)
                ent:TakeDamageInfo(dmg)
            end
        end
    end},

    HolyWrath = {KeyBind=KEY_J, Cooldown=2, LastUsed=0, description="Spawn the Crusader weapon that deals massive damage for 2 minutes.", Action=function(ply)
        if not IsValid(ply) then return end
        for _, wep in ipairs(ply:GetWeapons()) do
            if wep:GetClass() == "tfa_crucible" then
                ply:StripWeapon("tfa_crucible")
            end
        end
        ply:Give("tfa_crucible")
        local wep = ply:GetWeapon("tfa_crucible")
        if not IsValid(wep) then return end
        wep:SetModelScale(5, 0)
        local vm = ply:GetViewModel()
        if IsValid(vm) then
            vm:SetModelScale(5, 0)
        end
        
        wep.CrusaderActive = true
        ply:SelectWeapon("tfa_crucible")
        timer.Simple(120, function()
            if IsValid(ply) then
                ply:StripWeapon("tfa_crucible")
            end
        end)
    end},

    Deflection = {KeyBind=KEY_Q, Cooldown=60, LastUsed=0, description="Deflect all incoming damage for 10 seconds.", Action=function(ply)
        ply.DeflectActive = true
        suiteffect("pfx4_0b",5,ply:GetPos(),ply)
        timer.Simple(10, function() if IsValid(ply) then ply.DeflectActive = false end end)
    end},

    DivineRegen = {KeyBind=KEY_F, Cooldown=90, LastUsed=0, description="Regenerate your armor and AP 3x faster for 15 seconds.", Action=function(ply)
        local item = ply.currentsuit
        if not item then return end
        local regenMult = 3
        ply:ChatPrint("Divine Regen active!")
        local regenTimer = "DivineRegen_" .. ply:SteamID()
        timer.Create(regenTimer, 1, 15, function()
            if not IsValid(ply) or not ply.currentsuit then timer.Remove(regenTimer) return end
            local armor = item.customData.Armor or 100
            item.customData.Armor = math.min(item.customData.Armor + armor*regenMult/15, armor)
            local ap = item.customData.Health or 50
            item.customData.Health = math.min(item.customData.Health + ap*regenMult/15, ap)
        end)
    end},

HolyShield = {
    KeyBind = KEY_G,
    Cooldown = 40,
    LastUsed = 0,
    description = "Spawn a holy shield in front of you that blocks bullets for 15 seconds.",
    Action = function(ply)
        if not IsValid(ply) then return end

        local shield = ents.Create("prop_physics")
        if not IsValid(shield) then return end

        shield:SetModel("models/hunter/tubes/tube4x4x3c.mdl")
        shield:SetPos(ply:GetPos() + ply:GetForward() * 100 + Vector(0, 0, 16))
        shield:SetAngles(Angle(180, ply:EyeAngles().y, 0))
        shield:Spawn()

        shield:SetSolid(SOLID_VPHYSICS)
        shield:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        shield:SetRenderMode(RENDERMODE_TRANSALPHA)
        shield:SetColor(Color(200, 200, 255, 180))
        shield:SetMaterial("models/debug/debugwhite")

        local phys = shield:GetPhysicsObject()
        if IsValid(phys) then
            phys:EnableMotion(false)
        end

        local shieldTimer = "HolyShield_" .. ply:SteamID64()
        local lerpSpeed = 100

        timer.Create(shieldTimer, 0.05, 300, function()
            if not IsValid(ply) or not IsValid(shield) then
                shield:Remove()
                timer.Remove(shieldTimer)
                return
            end

            local forward = Vector(ply:GetAimVector().x, ply:GetAimVector().y, 0):GetNormalized()
            local targetPos = ply:GetPos() + forward * 100 + Vector(0, 0, 80)
            local targetAng = Angle(180, ply:EyeAngles().y, 0)

            shield:SetPos(LerpVector(FrameTime() * lerpSpeed, shield:GetPos(), targetPos))
            shield:SetAngles(LerpAngle(FrameTime() * lerpSpeed, shield:GetAngles(), targetAng))
        end)


        timer.Simple(15, function()
            if IsValid(shield) then
                shield:Remove()
            end
            timer.Remove(shieldTimer)
        end)
    end
}
})

BCORE.Inventory:CreateSuit("[ERROR: DIVINITY_NOT_FOUND]", {
    Health = defaultRanges(250,2500),
    Armor = defaultRanges(200,2000),
    Resistance = defaultRanges(10,70),
    Speed = defaultRanges(150,400),
    Jump = defaultRanges(120,350),
    Regen = defaultRanges(60,300)
}, "The system cannot resolve your existence.", "models/player/combine_super_soldier.mdl",
function(ply,dmginfo,item)
    dmginfo:SetDamage(dmginfo:GetDamage()*0.25)
end,
{
    RealitySkip={KeyBind=KEY_E,Cooldown=4,LastUsed=0,description="Skip reality forward.", Action=function(ply)
        suiteffect("pfx5_00_s",2,ply:GetPos(),ply)
        ply:SetPos(ply:GetPos()+ply:GetForward()*600+Vector(0,0,60))
        suiteffect("pfx5_00_alt_s",2,ply:GetPos(),ply)
    end},
    ExistentialCrash={KeyBind=KEY_F,Cooldown=20,LastUsed=0,description="Crash existence around you.", Action=function(ply)
        suiteffect("pfx_glitch_crash",8,ply:GetPos(),ply)
        for _,ent in ipairs(player.GetAll()) do
            if ent~=ply then
                suiteffect("pfx_glitch_target",6,ent:GetPos(),ent)
                ent:SetVelocity((ent:GetPos()-ply:GetPos()):GetNormalized()*1800)
                ent:TakeDamage(350,ply,ply)
            end
        end
    end},
    UndefinedState={KeyBind=KEY_Q,Cooldown=45,LastUsed=0,description="You cannot be interacted with.", Action=function(ply)
        suiteffect("pfx_glitch_phase",10,ply:GetPos(),ply)
        ply:SetNoDraw(true)
        ply:SetNotSolid(true)
        ply:GodEnable()
        timer.Simple(10,function()
            if IsValid(ply) then
                ply:SetNoDraw(false)
                ply:SetNotSolid(false)
                ply:GodDisable()
            end
        end)
    end}
})

BCORE.Inventory:CreateSuit("Void God [CORRUPTED]", {
    Health = defaultRanges(300,3000),
    Armor = defaultRanges(250,2500),
    Resistance = defaultRanges(5,50),
    Speed = defaultRanges(200,500),
    Jump = defaultRanges(150,400),
    Regen = defaultRanges(80,400)
}, "Everything returns to zero.", "models/player/zombie_soldier.mdl",
function(ply,dmginfo,item)
    dmginfo:SetDamage(dmginfo:GetDamage()*0.2)
end,
{
    Singularity={KeyBind=KEY_E,Cooldown=12,LastUsed=0,description="Create a collapsing void.", Action=function(ply)
        suiteffect("pfx5_00_s",10,ply:GetPos(),ply)
        for i=1,20 do
            timer.Simple(i*0.3,function()
                if not IsValid(ply) then return end
                for _,ent in ipairs(ents.FindInSphere(ply:GetPos(),600)) do
                    if ent:IsPlayer() and ent~=ply then
                        ent:SetVelocity((ply:GetPos()-ent:GetPos()):GetNormalized()*2000)
                        ent:TakeDamage(40,ply,ply)
                        suiteffect("pfx8_06",2,ent:GetPos(),ent)
                    end
                end
            end)
        end
    end},
    OblivionTouch={KeyBind=KEY_Q,Cooldown=6,LastUsed=0,description="Touch = deletion.", Action=function(ply)
        local tr=ply:GetEyeTrace()
        if not IsValid(tr.Entity) or not tr.Entity:IsPlayer() then return end
        if tr.HitPos:Distance(ply:GetPos())>180 then return end
        suiteffect("pfx5_00_alt",3,tr.Entity:GetPos(),tr.Entity)
        tr.Entity:TakeDamage(9999,ply,ply)
    end},
    AbyssalReign={KeyBind=KEY_F,Cooldown=60,LastUsed=0,description="You own the map.", Action=function(ply)
        suiteffect("pfx_void_reign",15,ply:GetPos(),ply)
        for _,ent in ipairs(player.GetAll()) do
            if ent~=ply then
                ent:SetWalkSpeed(60)
                ent:SetRunSpeed(100)
                suiteffect("pfx5_00_alt_s", 15, Vector(ent:GetPos().x, ent:GetPos().y , ent:GetPos().z + 50), ent)
                timer.Simple(15,function()
                    if IsValid(ent) then
                        ent:SetWalkSpeed(200)
                        ent:SetRunSpeed(400)
                    end
                end)
            end
        end
    end}
})




