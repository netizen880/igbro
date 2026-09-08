if getgenv().LeanCombat then pcall(getgenv().LeanCombat.Destroy) end
if getgenv().LeanNPCESP then pcall(getgenv().LeanNPCESP.Unload) end
if getgenv().CodexNPCESP then pcall(getgenv().CodexNPCESP.Destroy) end
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/vcqz23/settings/refs/heads/main/V2"))()

-- Register dropdown setters so saved ESP configurations restore all selections.
-- Use the library's supported theme slots before constructing controls.
do
    local palette={
        Accent=Color3.fromRGB(225,225,225),
        Background=Color3.fromRGB(10,10,10),
        SectionBackground=Color3.fromRGB(17,17,17),
        ElementBackground=Color3.fromRGB(26,26,26),
        ElementOutline=Color3.fromRGB(52,52,52),
        Inline=Color3.fromRGB(35,35,35),
        Other=Color3.fromRGB(22,22,22),
        TabButtons=Color3.fromRGB(25,25,25),
        Unselected=Color3.fromRGB(158,158,158),
        TextColor=Color3.fromRGB(245,245,245),
    }
    for name,color in pairs(palette) do Library:Refresh(name,color) end
end
do
    local addKeyPicker = Library.AddKeyPicker
    Library.AddKeyPicker = function(self,data)
        if data and data.Text=="Menu bind" and data.Default==nil and data.Key==nil then
            data=table.clone(data)
            data.Default=Enum.KeyCode.RightShift
        end
        return addKeyPicker(self,data)
    end
    local addDropdown = Library.AddDropdown
    Library.AddDropdown = function(self,data)
        local control = addDropdown(self,data)
        Library.ConfigFlags[control.Flag] = control.Set
        return control
    end
end

-- Create window
local MainWindow = Library:CreateWindow({
    Title = "Lean",
    SubText = "V1.7 | BRM5",
    IsMobile = false,

    -- "wave" | "rainbow" | "pulse" | "gradient"
    SubWaveColorA = Color3.fromRGB(245, 245, 245),
    SubWaveColorB = Color3.fromRGB(140, 140, 140),
    SubWaveSpeed = 1,
    SubWaveStyle = "wave",

    TitleWaveColorA = Color3.fromRGB(245, 245, 245),
    TitleWaveColorB = Color3.fromRGB(140, 140, 140),
    TitleWaveSpeed = 1,
    TitleWaveStyle = "wave",
})

local SilentAimPage, TriggerPage = MainWindow:AddTab({Text="Combat",Pages={"Silent Aim","Trigger Bot"}})
local NpcPage, PlayersPage, ZombiePage, CorpsePage, SharedPage = MainWindow:AddTab({Text="Visuals",Pages={"NPCs","Players","Zombies","Corpses","Settings"}})
-- Combat targeting uses the same custom actor registry as the NPC ESP.
local AimPlayers = game:GetService("Players")
local AimRunService = game:GetService("RunService")
local AimUIS = game:GetService("UserInputService")
local AimLocalPlayer = AimPlayers.LocalPlayer
local AimCamera = workspace.CurrentCamera
local Silent = {
    Enabled=false,Targets={NPCs=true,Players=true},HitPart="Head",Hitscan=false,TeamCheck=false,VisibleCheck=true,
    MaxDistance=1000,HitChance=100,StickyAim=false,FOVEnabled=true,ShowFOV=true,FOV=120,
    FOVColor=Color3.fromRGB(150,80,255),FillFOV=false,FOVFillColor=Color3.fromRGB(150,80,255),
    FOVFillTransparency=.4,GradientFOV=false,
    GradientSpin=false,GradientSpinSpeed=1,
    GradientColorA=Color3.fromRGB(150,80,255),GradientColorB=Color3.fromRGB(255,110,60),
    AutoPrediction=true,BulletDropCompensation=true,
}
local TriggerBotSettings = {
    Enabled=false,Targets={NPCs=true,Players=true},TeamCheck=false,VisibleCheck=true,
    MaxDistance=1000,ReactionTime=50,ShootTime=100,Magnetic=false,
}
local Combat = {
    Silent=Silent,Trigger=TriggerBotSettings,active=true,actors={},samples={},parts={},
    sticky=nil,target=nil,nextScan=0,lastShot=0,targetSince=0,triggerActor=nil,
    connections={},drawings={},hookState="Waiting for game adapter",
}
local SilentKeyPicker,TriggerKeyPicker
-- Page containers control visibility; keep their two labels readable during fades.
for _,page in ipairs({SilentAimPage,TriggerPage}) do
    local label=page.Items.Text.Instance
    local function restoreText()
        if label.TextTransparency~=0 then label.TextTransparency=0 end
    end
    restoreText()
    table.insert(Combat.connections,label:GetPropertyChangedSignal("TextTransparency"):Connect(restoreText))
end
local HitPartOptions={"Head","HumanoidRootPart","UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm",
    "LeftUpperLeg","RightUpperLeg","Closest Part","Random"}
local function aim_getMouseLocation() return AimUIS:GetMouseLocation() end
function Combat.SetTargets(settings,selected)
    local result={}
    if type(selected)=="table" then
        for _,v in ipairs(selected) do if v=="NPCs" or v=="Players" or v=="Zombies" then result[v]=true end end
    end
    settings.Targets=result
    Combat.target=nil;Combat.sticky=nil;Combat.triggerActor=nil
end
function Combat.Service()
    if Combat.service then return Combat.service end
    if Combat.resolveAt and os.clock()<Combat.resolveAt then return nil end
    Combat.resolveAt=os.clock()+2
    for _,m in ipairs(getloadedmodules()) do
        if m.Name=="ClientService" then
            local ok,value=pcall(require,m)
            if ok and type(value)=="table" and value.Replicator then Combat.service=value;break end
        end
    end
    return Combat.service
end
function Combat.Kind(actor)
    local c=Combat.Service()
    local registry=c and c.Replicator and c.Replicator.Actors
    if not registry or not actor or not actor.UID or registry[actor.UID]~=actor then return nil end
    if actor.IsLocalPlayer or actor.Owner==AimLocalPlayer or actor==c.Replicator.LocalActor then return nil end
    if actor.Zombie==true then return "Zombies" end
    if actor.Owner==nil then return "NPCs" end
    if typeof(actor.Owner)=="Instance" and actor.Owner:IsA("Player") then return "Players" end
end
function Combat.IsAlive(actor)
    if not actor or actor.Alive==false then return false end
    if actor.Zombie then
        return type(actor.Health)=="table" or (type(actor.Health)=="number" and actor.Health>0)
    end
    return type(actor.Health)=="number" and actor.Health>0
end
function Combat.Allowed(actor,settings)
    local kind=Combat.Kind(actor)
    if not kind or not settings.Targets[kind] then return false end
    if not Combat.IsAlive(actor) then return false end
    if not actor.Character or not actor.Character.Parent then return false end
    if settings.TeamCheck and kind=="Players" and AimLocalPlayer.Team~=nil and actor.Owner.Team==AimLocalPlayer.Team then return false end
    return true
end
function Combat.Origin(camera)
    local c=Combat.Service();local me=c and c.Replicator and c.Replicator.LocalActor
    return me and me.Position or camera.CFrame.Position
end
function Combat.Sync(force)
    if not force and os.clock()<Combat.nextScan then return end
    Combat.nextScan=os.clock()+.05
    local c=Combat.Service();local registry=c and c.Replicator and c.Replicator.Actors or {}
    local list={};local now=os.clock()
    for _,a in pairs(registry) do
        if Combat.Kind(a) and typeof(a.Position)=="Vector3" then
            list[#list+1]=a
            local old=Combat.samples[a]
            local vel=Vector3.zero
            if old and old.model==a.Character and old.root==a.RootPart and now>old.time then
                local measured=(a.Position-old.position)/(now-old.time)
                if measured.Magnitude<300 then vel=old.velocity:Lerp(measured,.5) end
            end
            Combat.samples[a]={position=a.Position,time=now,velocity=vel,model=a.Character,root=a.RootPart}
            -- Parts may be replaced or arrive after the model during replication.
            local parts,seen={},{}
            local function add(p)
                if typeof(p)=="Instance" and p:IsA("BasePart") and a.Character
                    and p:IsDescendantOf(a.Character) and not seen[p] then
                    seen[p]=true;parts[#parts+1]=p
                end
            end
            for _,p in pairs(a.Parts or {}) do add(p) end
            if a.Character then for _,p in ipairs(a.Character:GetChildren()) do add(p) end end
            Combat.parts[a]={model=a.Character,list=parts}
        end
    end
    for a in pairs(Combat.samples) do if not a.UID or registry[a.UID]~=a then Combat.samples[a]=nil;Combat.parts[a]=nil end end
    Combat.actors=list
end
function Combat.PartCFrame(actor,part)
    if not Combat.IsAlive(actor) then return part.CFrame end
    local root=actor.RootPart
    if not root or root:IsDescendantOf(workspace) then return part.CFrame end
    -- Parked WorldModel rigs are in local coordinates: apply the actor rotation,
    -- not just its translation. Live rigs already contain their rendered pose.
    local pose=typeof(actor.CFrame)=="CFrame" and actor.CFrame.Rotation or CFrame.identity
    local actorFrame=pose+actor.Position
    return actorFrame*root.CFrame:ToObjectSpace(part.CFrame)
end
function Combat.PartPosition(actor,part)
    return Combat.PartCFrame(actor,part).Position
end
local combatRayParams=RaycastParams.new()
combatRayParams.FilterType=Enum.RaycastFilterType.Exclude
combatRayParams.IgnoreWater=false
-- Match the collision group used by this game's projectile raycasts.
pcall(function() combatRayParams.CollisionGroup="9" end)
function Combat.Visible(actor,point,camera)
    local c=Combat.Service();local me=c and c.Replicator and c.Replicator.LocalActor
    local excluded={camera}
    if me and me.Character then excluded[#excluded+1]=me.Character end
    combatRayParams.FilterDescendantsInstances=excluded
    local hit=workspace:Raycast(camera.CFrame.Position,point-camera.CFrame.Position,combatRayParams)
    if not hit then return true end
    if actor.Character and hit.Instance:IsDescendantOf(actor.Character) then return true end
    -- Render rigs and collision bodies may be separate. Use the same actor
    -- identity mapping that the game's bullet-impact handler uses.
    local replicator=c and c.Replicator
    local registry=replicator and replicator.Actors
    if not registry or registry[actor.UID]~=actor then return false end
    local uid=hit.Instance:GetAttribute("ActorUID")
    if uid==actor.UID then return true end
    if type(replicator.GetFromBodyPart)=="function" then
        local ok,resolvedUID=pcall(replicator.GetFromBodyPart,replicator,hit.Instance)
        if ok and resolvedUID==actor.UID then return true end
    end
    return false
end
function Combat.PickPart(actor,settings,camera,mouse)
    local parts=actor.Parts or {}
    local option=settings.HitPart
    local function valid(part)
        return typeof(part)=="Instance" and part:IsA("BasePart") and actor.Character
            and part:IsDescendantOf(actor.Character)
    end
    if option=="HumanoidRootPart" then
        return valid(actor.RootPart) and actor.RootPart or actor.Character:FindFirstChild("HumanoidRootPart")
    end
    if option=="Closest Part" or option=="Random" then
        local best,distance,pool=nil,math.huge,{}
        for _,part in ipairs((Combat.parts[actor] or {}).list or {}) do
            if valid(part) then
                if option=="Random" then pool[#pool+1]=part else
                    local sp,on=camera:WorldToViewportPoint(Combat.PartPosition(actor,part))
                    if on then local d=(Vector2.new(sp.X,sp.Y)-mouse).Magnitude;if d<distance then best,distance=part,d end end
                end
            end
        end
        if option=="Random" then return #pool>0 and pool[math.random(#pool)] or nil end
        return best
    end
    local part=parts[option]
    if valid(part) then return part end
    part=actor.Character:FindFirstChild(option)
    if valid(part) then return part end
    part=actor.Character:FindFirstChild("Head")
    if valid(part) then return part end
    if valid(parts.Head) then return parts.Head end
    if valid(actor.RootPart) then return actor.RootPart end
end
function Combat.Predict(actor,part,settings,camera)
    -- Screen selection uses the current position; shot prediction uses muzzle speed.
    return Combat.PartPosition(actor,part)
end
function Combat.FindTarget(settings,camera,mouse,sticky)
    Combat.Sync()
    camera=camera or workspace.CurrentCamera;mouse=mouse or aim_getMouseLocation()
    local origin=Combat.Origin(camera)
    local function candidate(a)
        if not Combat.Allowed(a,settings) or (a.Position-origin).Magnitude>settings.MaxDistance then return nil end
        local function check(part)
            if not part or not part.Parent or not part:IsDescendantOf(a.Character) then return nil end
            local point=Combat.PartPosition(a,part)
            local sp,on=camera:WorldToViewportPoint(point)
            if not on then return nil end
            local d=(Vector2.new(sp.X,sp.Y)-mouse).Magnitude
            if settings.FOVEnabled and d>settings.FOV then return nil end
            if (settings.VisibleCheck or settings.Hitscan) and not Combat.Visible(a,point,camera) then return nil end
            return {actor=a,part=part,position=point,distance=d}
        end
        local preferred=Combat.PickPart(a,settings,camera,mouse)
        local selected=check(preferred)
        if selected or not settings.Hitscan then return selected end
        local best
        for _,part in ipairs((Combat.parts[a] or {}).list or {}) do
            if part~=preferred and part~=a.RootPart then
                local hit=check(part)
                if hit and (not best or hit.distance<best.distance) then best=hit end
            end
        end
        return best
    end
    if settings.StickyAim and sticky then local current=candidate(sticky);if current then return current end end
    local best
    for _,a in ipairs(Combat.actors) do
        local current=candidate(a)
        if current and (not best or current.distance<best.distance) then best=current end
    end
    return best
end
function Combat.RayBox(origin,direction,cf,size)
    local p=cf:PointToObjectSpace(origin)
    local d=cf:VectorToObjectSpace(direction)
    local half=size*.5;local lo,hi=0,math.huge
    for _,axis in ipairs({"X","Y","Z"}) do
        if math.abs(d[axis])<1e-6 then if math.abs(p[axis])>half[axis] then return nil end
        else
            local a,b=(-half[axis]-p[axis])/d[axis],(half[axis]-p[axis])/d[axis]
            if a>b then a,b=b,a end
            lo=math.max(lo,a);hi=math.min(hi,b);if hi<lo then return nil end
        end
    end
    return lo
end
function Combat.TriggerTarget(settings,camera,mouse)
    if settings.Magnetic then
        local selected=Combat.target
        if Silent.Enabled and Combat.silentActive and selected and Combat.Allowed(selected.actor,settings)
            and (selected.actor.Position-Combat.Origin(camera)).Magnitude<=settings.MaxDistance
            and (not settings.VisibleCheck or Combat.Visible(selected.actor,selected.position,camera)) then return selected.actor end
        return nil
    end
    Combat.Sync()
    local ray=camera:ViewportPointToRay(mouse.X,mouse.Y)
    local closest,nearest=nil,settings.MaxDistance
    -- Test all actor bodies before applying the target filter: an excluded player
    -- in front of an NPC must block the trigger, rather than shooting through it.
    for _,a in ipairs(Combat.actors) do
        if Combat.IsAlive(a) and a.RootPart and a.Character and a.Character.Parent then
            local delta=a.Position-a.RootPart.Position
            for _,p in ipairs((Combat.parts[a] or {}).list or {}) do
                if p.Parent then
                    local hit=Combat.RayBox(ray.Origin,ray.Direction,Combat.PartCFrame(a,p),p.Size)
                    if hit and hit<nearest then nearest=hit;closest=a end
                end
            end
        end
    end
    if not closest or not Combat.Allowed(closest,settings) then return nil end
    if settings.VisibleCheck and not Combat.Visible(closest,ray.Origin+ray.Direction*nearest,camera) then return nil end
    return closest
end
function Combat.KeyActive(picker,state)
    if not picker then return false end
    if picker.Mode=="Always" then return true end
    local key=picker.Key
    if type(key)=="string" then
        local mouseKeys={MB1=Enum.UserInputType.MouseButton1,MB2=Enum.UserInputType.MouseButton2,MB3=Enum.UserInputType.MouseButton3}
        key=mouseKeys[key] or key
        if type(key)=="string" and key~="NONE" then
            local name=key:match("([^%.]+)$")
            local ok,value=pcall(function() return Enum.KeyCode[name] end)
            if ok then key=value end
        end
    end
    local down=false
    if typeof(key)=="EnumItem" then
        if key.EnumType==Enum.UserInputType then down=AimUIS:IsMouseButtonPressed(key)
        elseif key.EnumType==Enum.KeyCode then down=AimUIS:IsKeyDown(key) end
    end
    if picker.Mode=="Toggle" then if down and not state.down then state.on=not state.on end;state.down=down;return state.on==true end
    state.down=down;return down
end
function Combat.TriggerStep(actor,now,fire)
    if actor~=Combat.triggerActor then Combat.triggerActor=actor;Combat.targetSince=now end
    if not actor then return false end
    if (now-Combat.targetSince)*1000<TriggerBotSettings.ReactionTime or (now-Combat.lastShot)*1000<TriggerBotSettings.ShootTime then return false end
    fire();Combat.lastShot=now;return true
end
function Combat.Fire()
    if mouse1click then mouse1click()
    elseif mouse1press and mouse1release then
        Combat.mouseHeld=true;mouse1press()
        task.delay(.02,function() if Combat.mouseHeld then Combat.mouseHeld=false;mouse1release() end end)
    end
end
local keyStates={silent={},trigger={}}
function Combat.Frame()
    if not Combat.active then return end
    AimCamera=workspace.CurrentCamera
    if not AimCamera then return end
    if Silent.Enabled and not Combat.installed and (not Combat.retryAt or os.clock()>=Combat.retryAt) then
        Combat.retryAt=os.clock()+2
        Combat.Install()
    end
    local menuOpen=Library.Window and Library.Window.Visible
    local blocked=menuOpen or AimUIS:GetFocusedTextBox()~=nil
    Combat.silentActive=Combat.KeyActive(SilentKeyPicker,keyStates.silent)
    local triggerActive=Combat.KeyActive(TriggerKeyPicker,keyStates.trigger)
    if not blocked and Silent.Enabled and Combat.silentActive then
        Combat.target=Combat.FindTarget(Silent,nil,nil,Combat.sticky)
        Combat.sticky=Combat.target and Combat.target.actor
    else Combat.target=nil;Combat.sticky=nil end
    if not blocked and TriggerBotSettings.Enabled and triggerActive then
        local actor=Combat.TriggerTarget(TriggerBotSettings,AimCamera,aim_getMouseLocation())
        Combat.TriggerStep(actor,os.clock(),Combat.Fire)
    else Combat.triggerActor=nil;Combat.targetSince=0 end
end
function Combat.Destroy()
    Combat.active=false;Silent.Enabled=false;TriggerBotSettings.Enabled=false;Combat.target=nil
    if Combat.Unhook then Combat.Unhook() end
    for _,c in ipairs(Combat.connections) do c:Disconnect() end
    for _,d in ipairs(Combat.drawings) do d:Remove() end
    if Combat.gradientGui then Combat.gradientGui:Destroy();Combat.gradientGui=nil end
    if Combat.mouseHeld then Combat.mouseHeld=false;if mouse1release then mouse1release() end end
end
getgenv().LeanCombat=Combat


-- Scope redirection to this game's local firearm discharge. The unchanged
-- discharge code uses the returned muzzle frame for both simulation and replication.
function Combat.RedirectMuzzle(cf,target)
    if typeof(cf)~="CFrame" or not target or typeof(target.position)~="Vector3" then return cf end
    if (target.position-cf.Position).Magnitude<.001 then return cf end
    return CFrame.lookAt(cf.Position,target.position)
end
-- Match BulletClassMultithread: constant muzzle speed and gravity 32.2.
function Combat.Intercept(origin,point,velocity,speed,compensateDrop)
    if type(speed)~="number" or speed<=0 then return point,0 end
    local time=(point-origin).Magnitude/speed
    local aim=point
    for _=1,6 do
        aim=point+velocity*time+Vector3.new(0,compensateDrop and 16.1*time*time or 0,0)
        time=(aim-origin).Magnitude/speed
    end
    return aim,time
end
function Combat.ShotFrame(weapon,cf,target)
    if typeof(cf)~="CFrame" or not target then return cf end
    local tune=weapon._firearm and weapon._firearm.Tune
    local bulletService=Combat.bulletService
    if (not Silent.AutoPrediction and not Silent.BulletDropCompensation)
        or not tune or not bulletService then return Combat.RedirectMuzzle(cf,target) end
    local ok,speed=pcall(bulletService.GetInfo,bulletService,tune.Caliber,tune.Barrel)
    if not ok or type(speed)~="number" or speed<=0 then return Combat.RedirectMuzzle(cf,target) end
    local sample=Combat.samples[target.actor]
    local velocity=Silent.AutoPrediction and sample and sample.velocity or Vector3.zero
    local point=Combat.PartPosition(target.actor,target.part)
    local aim=Combat.Intercept(cf.Position,point,velocity,speed,Silent.BulletDropCompensation)
    local frame=Combat.RedirectMuzzle(cf,{position=aim})
    -- Discharge adds the sight's zeroing angle after GetMuzzleCFrame.
    -- Remove it here so it does not add a second correction to the trajectory.
    local actor=weapon._actor
    local zero=actor and actor.ADS and actor.ViewModel and actor.ViewModel.Zero
    if type(zero)=="table" then zero=zero[4] end
    if Silent.BulletDropCompensation and type(zero)=="number" then
        local angle=math.asin(math.clamp(zero*32.2/(speed*speed),-1,1))*.5
        frame=frame*CFrame.Angles(-angle,0,0)
    end
    return frame
end
function Combat.Install()
    if Combat.installed then return true end
    local class
    for _,module in ipairs(getloadedmodules()) do
        if module.Name=="FirearmInventory" then
            local ok,result=pcall(require,module)
            if ok and type(result)=="table" then class=result end
        elseif module.Name=="BulletService" then
            local ok,result=pcall(require,module)
            if ok and type(result)=="table" and type(result.GetInfo)=="function" then Combat.bulletService=result end
        end
    end
    if not class or type(class.Discharge)~="function" or type(class.GetMuzzleCFrame)~="function" then
        Combat.hookState="FirearmInventory not loaded yet"
        return false
    end
    local originalDischarge,originalMuzzle=class.Discharge,class.GetMuzzleCFrame
    local rawDischarge,rawMuzzle=rawget(class,"Discharge"),rawget(class,"GetMuzzleCFrame")
    local contexts=setmetatable({}, {__mode="k"})
    local function discharge(weapon,...)
        local thread=coroutine.running()
        local oldContext=contexts[thread]
        local c=Combat.Service();local me=c and c.Replicator and c.Replicator.LocalActor
        local selected
        -- An actual firearm discharge is already a game-accepted shot. UI menu
        -- visibility must not cancel its aim correction; typing still blocks it.
        if Combat.active and Silent.Enabled and Combat.silentActive and weapon._actor==me
            and not AimUIS:GetFocusedTextBox()
            and math.random(1,100)<=Silent.HitChance then
            selected=Combat.FindTarget(Silent,nil,nil,Combat.sticky)
        end
        contexts[thread]=selected and {weapon=weapon,target=selected} or nil
        local result=table.pack(pcall(originalDischarge,weapon,...))
        contexts[thread]=oldContext
        if not result[1] then error(result[2],0) end
        return table.unpack(result,2,result.n)
    end
    local function muzzle(weapon,...)
        local result=table.pack(originalMuzzle(weapon,...))
        local ctx=contexts[coroutine.running()]
        if Combat.active and Silent.Enabled and ctx and ctx.weapon==weapon and Combat.Allowed(ctx.target.actor,Silent) then
            result[1]=Combat.ShotFrame(weapon,result[1],ctx.target)
        end
        return table.unpack(result,1,result.n)
    end
    class.Discharge=discharge
    class.GetMuzzleCFrame=muzzle
    Combat.installed=true;Combat.hookState="Local firearm adapter ready"
    Combat.hookClass=class;Combat.hookDischarge=discharge;Combat.hookMuzzle=muzzle
    Combat.Unhook=function()
        if class.Discharge==discharge then class.Discharge=rawDischarge end
        if class.GetMuzzleCFrame==muzzle then class.GetMuzzleCFrame=rawMuzzle end
        Combat.installed=false
    end
    return true
end
local function silent_applyHooks() Combat.Install() end


local GRAD_FOV_SEGMENTS = 48
local function makeGradientRing()
    local segments = {}
    if Drawing then
        for i = 1, GRAD_FOV_SEGMENTS do
            local ln = Drawing.new("Line")
            table.insert(Combat.drawings,ln)
            ln.Thickness = 2
            ln.Transparency = 1
            ln.Visible = false
            segments[i] = ln
        end
    end
    local ring = { segments = segments }

    function ring:hide()
        for _, ln in ipairs(self.segments) do ln.Visible = false end
    end

    -- A single UIGradient avoids seams between translucent Drawing polygons.
    local gui=Instance.new("ScreenGui")
    gui.Name="LeanFOVGradient";gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false
    gui.DisplayOrder=0;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    gui.Parent=(gethui and gethui()) or game:GetService("CoreGui")
    Combat.gradientGui=gui
    local fill=Instance.new("Frame")
    fill.Name="Fill";fill.AnchorPoint=Vector2.new(.5,.5)
    fill.BackgroundColor3=Color3.new(1,1,1);fill.BorderSizePixel=0
    fill.Visible=false;fill.Active=false;fill.Parent=gui
    local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(1,0);corner.Parent=fill
    local gradient=Instance.new("UIGradient");gradient.Parent=fill
    local hideOutline=ring.hide
    function ring:hide()
        hideOutline(self);fill.Visible=false
    end
    ring.phase=0
    function ring:draw(center,radius,colorA,colorB,filled,alpha,dt)
        if Silent.GradientSpin then
            self.phase=(self.phase+(dt or 0)*Silent.GradientSpinSpeed*math.pi*2)%(math.pi*2)
        else self.phase=0 end
        local n=#self.segments
        for i,ln in ipairs(self.segments) do
            local a0=(i-1)/n*math.pi*2
            local a1=i/n*math.pi*2
            ln.From=center+Vector2.new(math.cos(a0),math.sin(a0))*radius
            ln.To=center+Vector2.new(math.cos(a1),math.sin(a1))*radius
            ln.Color=colorA:Lerp(colorB,(math.sin((a0+a1)*.5-self.phase)+1)*.5)
            ln.Transparency=1;ln.Visible=true;ln.ZIndex=1
        end
        fill.Visible=filled and alpha>0
        fill.Position=UDim2.fromOffset(center.X,center.Y)
        fill.Size=UDim2.fromOffset(radius*2,radius*2)
        fill.BackgroundTransparency=1-math.clamp(alpha,0,1)
        gradient.Color=ColorSequence.new(colorA,colorB)
        gradient.Rotation=90+math.deg(self.phase)
    end

    return ring
end


local SilentFOVCircle, SilentFOVFill
if Drawing then
    SilentFOVFill = Drawing.new("Circle")
    table.insert(Combat.drawings,SilentFOVFill)
    SilentFOVFill.NumSides = 64
    SilentFOVFill.Filled = true
    SilentFOVFill.Color = Silent.FOVFillColor
    SilentFOVFill.Transparency = Silent.FOVFillTransparency
    SilentFOVFill.Visible = false

    SilentFOVCircle = Drawing.new("Circle")
    table.insert(Combat.drawings,SilentFOVCircle)
    SilentFOVCircle.Thickness = 1
    SilentFOVCircle.NumSides = 64
    SilentFOVCircle.Color = Silent.FOVColor
    SilentFOVCircle.Filled = false
    SilentFOVCircle.Transparency = 1
    SilentFOVCircle.Visible = false
end


local SilentGradRing = makeGradientRing()
Library:Connect(AimRunService.RenderStepped, function(dt)
    local show = Silent.Enabled and Silent.FOVEnabled and Silent.ShowFOV
    local mouse = aim_getMouseLocation()
    if SilentFOVFill then
        SilentFOVFill.Visible = show and Silent.FillFOV and not Silent.GradientFOV
        SilentFOVFill.Position = mouse
        SilentFOVFill.Radius = Silent.FOV
        SilentFOVFill.Color = Silent.FOVFillColor
        SilentFOVFill.Transparency = Silent.FOVFillTransparency
    end
    if show and Silent.GradientFOV then
        if SilentFOVCircle then SilentFOVCircle.Visible = false end
        SilentGradRing:draw(mouse, Silent.FOV, Silent.GradientColorA,
            Silent.GradientColorB, Silent.FillFOV, Silent.FOVFillTransparency, dt)
    else
        SilentGradRing:hide()
        if SilentFOVCircle then
            SilentFOVCircle.Visible = show
            SilentFOVCircle.Position = mouse
            SilentFOVCircle.Radius = Silent.FOV
            SilentFOVCircle.Color = Silent.FOVColor
        end
    end
end)


local SilentLeft = SilentAimPage:AddSection({ Title = "Silent Aim", Side = "Left" })

SilentLeft:AddToggle({
    Text = "Enabled",
    Flag = "silent_enabled",
    Default = false,
    Callback = function(v)
        Silent.Enabled = v
        if v then silent_applyHooks() end
    end
})

SilentLeft:AddSlider({
    Text = "FOV Radius",
    Flag = "silent_fov",
    Min = 10, Max = 500, Default = 120, Suffix = "px",
    Callback = function(v) Silent.FOV = v end
})

SilentLeft:AddSlider({
    Text = "Hit Chance",
    Flag = "silent_hitchance",
    Min = 0, Max = 100, Default = 100, Suffix = "%",
    Callback = function(v) Silent.HitChance = v end
})

SilentLeft:AddDropdown({Text="Targets",Flag="silent_targets",Multi=true,
    Options={"NPCs","Players","Zombies"},Default={"NPCs","Players"},
    Callback=function(v) Combat.SetTargets(Silent,v) end})
SilentKeyPicker=SilentLeft:AddKeyPicker({Text="Silent Aim Key",Flag="silent_key",Default=Enum.UserInputType.MouseButton2,Mode="Hold",Callback=function() end})
SilentLeft:AddDropdown({
    Text = "Hit Part",
    Flag = "silent_hitpart",
    Options = HitPartOptions,
    Default = "Head",
    Callback = function(v) Silent.HitPart = v end
})

SilentLeft:AddSlider({
    Text = "Max Distance",
    Flag = "silent_distance",
    Min = 50, Max = 5000, Default = 1000, Suffix = " studs",
    Callback = function(v) Silent.MaxDistance = v end
})

SilentLeft:AddToggle({
    Text = "Sticky Aim",
    Flag = "silent_sticky",
    Default = false,
    Callback = function(v) Silent.StickyAim = v end
})

local SilentFOVSec = SilentAimPage:AddSection({ Title = "FOV", Side = "Left" })

SilentFOVSec:AddToggle({
    Text = "FOV Enabled",
    Flag = "silent_fov_enabled",
    Default = true,
    Callback = function(v) Silent.FOVEnabled = v end
})

SilentFOVSec:AddToggle({
    Text = "Show FOV Circle",
    Flag = "silent_fov_show",
    Default = true,
    Callback = function(v) Silent.ShowFOV = v end
})

SilentFOVSec:AddColorPicker({
    Text = "FOV Color",
    Flag = "silent_fov_color",
    Default = Silent.FOVColor,
    Callback = function(color) Silent.FOVColor = color end
})

SilentFOVSec:AddToggle({
    Text = "Fill FOV",
    Flag = "silent_fov_fill",
    Default = false,
    Callback = function(v) Silent.FillFOV = v end
})

SilentFOVSec:AddColorPicker({
    Text = "Fill Color",
    Flag = "silent_fov_fill_color",
    Default = Silent.FOVFillColor,
    Transparency = Silent.FOVFillTransparency,
    Callback = function(color, alpha)
        Silent.FOVFillColor = color
        if alpha ~= nil then Silent.FOVFillTransparency = alpha end
    end
})

local GradientColorAControl,GradientColorBControl,GradientSpinControl,GradientSpeedControl
local function updateGradientControls()
    for _,control in pairs({GradientColorAControl,GradientColorBControl,GradientSpinControl}) do
        control.Items.Object.Instance.Visible=Silent.GradientFOV
    end
    if GradientSpeedControl then
        GradientSpeedControl.Items.Object.Instance.Visible=Silent.GradientFOV and Silent.GradientSpin
    end
    SilentFOVSec.UpdateSection()
end
SilentFOVSec:AddToggle({
    Text="Gradient",Flag="silent_fov_gradient",Default=false,
    Callback=function(v) Silent.GradientFOV=v;updateGradientControls() end
})
GradientColorAControl=SilentFOVSec:AddColorPicker({
    Text="Gradient Color A",Flag="silent_fov_gradient_a",Default=Silent.GradientColorA,
    Callback=function(color) Silent.GradientColorA=color end
})
GradientColorBControl=SilentFOVSec:AddColorPicker({
    Text="Gradient Color B",Flag="silent_fov_gradient_b",Default=Silent.GradientColorB,
    Callback=function(color) Silent.GradientColorB=color end
})
GradientSpinControl=SilentFOVSec:AddToggle({
    Text="Spin",Flag="silent_fov_spin",Default=false,
    Callback=function(v) Silent.GradientSpin=v;updateGradientControls() end
})
GradientSpeedControl=SilentFOVSec:AddSlider({
    Text="Spin Speed",Flag="silent_fov_spin_speed",Min=.1,Max=3,Rounding=.1,Default=1,Suffix=" rev/s",
    Callback=function(v) Silent.GradientSpinSpeed=v end
})
updateGradientControls()

local SilentPred = SilentAimPage:AddSection({ Title = "Prediction", Side = "Right" })

SilentPred:AddToggle({
    Text = "Auto Prediction",
    Flag = "silent_auto_prediction",
    Default = true,
    Callback = function(v) Silent.AutoPrediction = v end
})

SilentPred:AddToggle({
    Text = "Bullet Drop Compensation",
    Flag = "silent_bullet_drop_compensation",
    Default = true,
    Callback = function(v) Silent.BulletDropCompensation = v end
})

local SilentChecks = SilentAimPage:AddSection({ Title = "Checks", Side = "Right" })

SilentChecks:AddToggle({Text="Hitscan",Flag="silent_hitscan",Default=false,
    Callback=function(v) Silent.Hitscan=v;Combat.sticky=nil end})

SilentChecks:AddToggle({
    Text = "Team Check",
    Flag = "silent_teamcheck",
    Default = false,
    Callback = function(v) Silent.TeamCheck = v end
})

SilentChecks:AddToggle({
    Text = "Visible Check",
    Flag = "silent_visiblecheck",
    Default = true,
    Callback = function(v) Silent.VisibleCheck = v end
})





local TriggerLeft = TriggerPage:AddSection({
    Title = "Trigger Bot",
    Side = "Left"
})

TriggerLeft:AddToggle({
    Text = "Enabled",
    Flag = "trigger_enabled",
    Default = false,
    Callback = function(value)
        TriggerBotSettings.Enabled = value
    end
})

TriggerKeyPicker = TriggerLeft:AddKeyPicker({
    Text = "Trigger Key",
    Flag = "trigger_key",
    Default = Enum.UserInputType.MouseButton2,
    Mode = "Hold",
    Callback = function() end
})

local ReactionTimeSlider=TriggerLeft:AddSlider({
    Text = "Reaction Time",
    Flag = "trigger_reaction",
    Min = 0, Max = 500, Rounding = 1,
    Default = 50,
    Suffix = " ms",
    Callback = function(value)
        TriggerBotSettings.ReactionTime = value
    end
})

local ShootTimeSlider=TriggerLeft:AddSlider({
    Text = "Shoot Time",
    Flag = "trigger_shoot",
    Min = 0, Max = 1000, Rounding = 1,
    Default = 100,
    Suffix = " ms",
    Callback = function(value)
        TriggerBotSettings.ShootTime = value
    end
})

-- One wheel notch changes one millisecond, independent of the slider width.
for _,slider in ipairs({ReactionTimeSlider,ShootTimeSlider}) do
    local object=slider.Items.Object.Instance
    object.Active=true
    table.insert(Combat.connections,object.InputChanged:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseWheel and input.Position.Z~=0 then
            slider.Set(math.clamp(slider.Value+math.sign(input.Position.Z),slider.Min,slider.Max))
        end
    end))
end

local TriggerRight = TriggerPage:AddSection({
    Title = "Magnetic",
    Side = "Right"
})

TriggerRight:AddToggle({
    Text = "Magnetic Trigger",
    Flag = "trigger_magnetic",
    Default = false,
    Callback = function(value)
        TriggerBotSettings.Magnetic = value
    end
})


TriggerLeft:AddDropdown({Text="Targets",Flag="trigger_targets",Multi=true,
    Options={"NPCs","Players","Zombies"},Default={"NPCs","Players"},
    Callback=function(v) Combat.SetTargets(TriggerBotSettings,v) end})
TriggerRight:AddToggle({Text="Team Check",Flag="trigger_teamcheck",Default=false,
    Callback=function(v) TriggerBotSettings.TeamCheck=v end})
TriggerRight:AddToggle({Text="Visible Check",Flag="trigger_visiblecheck",Default=true,
    Callback=function(v) TriggerBotSettings.VisibleCheck=v end})
TriggerRight:AddSlider({Text="Max Distance",Flag="trigger_distance",Min=50,Max=5000,Default=1000,Suffix=" studs",
    Callback=function(v) TriggerBotSettings.MaxDistance=v end})

-- Movement adapter: verified CharacterController methods, scoped to LocalActor.
do
    local MovementPage,FlightPage=MainWindow:AddTab({Text="Movement",Pages={"Movement","Flight"}})
    local M={active=true,hooks={},Speed=false,SpeedValue=24,Smoothing=false,Stamina=false,
        Penalties=false,Survival=false,Fly=false,FlySpeed=40,Modifier=false,Multiplier=2,Noclip=false,
        speedState={},flyState={},modifierState={}}
    Combat.Movement=M
    local left=MovementPage:AddSection({Title="Movement",Side="Left"})
    local right=MovementPage:AddSection({Title="Restrictions",Side="Right"})
    local flight=FlightPage:AddSection({Title="Fly",Side="Left"})
    local modifier=FlightPage:AddSection({Title="Modifier",Side="Right"})
    local function toggle(section,text,key)
        return section:AddToggle({Text=text,Flag="movement_"..key,Default=false,
            Callback=function(v) M[key]=v end})
    end
    toggle(left,"Speed", "Speed")
    left:AddSlider({Text="Speed",Flag="movement_speed_value",Min=1,Max=150,Default=24,Rounding=1,Suffix=" studs/s",
        Callback=function(v) M.SpeedValue=v end})
    M.speedKey=left:AddKeyPicker({Text="Speed Key",Flag="movement_speed_key",Default=Enum.KeyCode.G,Mode="Toggle",Callback=function() end})
    toggle(left,"No Movement Smoothing","Smoothing")
    toggle(left,"Omni Sprint","OmniSprint")
    toggle(left,"Aim / Shoot While Sprinting","SprintCombat")
    toggle(right,"Infinite Stamina","Stamina")
    toggle(right,"No Speed Penalties","Penalties")
    toggle(flight,"Fly","Fly")
    flight:AddSlider({Text="Fly Speed",Flag="movement_fly_speed",Min=1,Max=150,Default=40,Rounding=1,Suffix=" studs/s",
        Callback=function(v) M.FlySpeed=v end})
    M.flyKey=flight:AddKeyPicker({Text="Fly Key",Flag="movement_fly_key",Default=Enum.KeyCode.F,Mode="Toggle",Callback=function() end})
    toggle(flight,"Fly Noclip","Noclip")
    toggle(modifier,"Fly Modifier","Modifier")
    modifier:AddSlider({Text="Speed Multiplier",Flag="movement_fly_multiplier",Min=1,Max=5,Default=2,Rounding=.1,Suffix="x",
        Callback=function(v) M.Multiplier=v end})
    M.modifierKey=modifier:AddKeyPicker({Text="Modifier Key",Flag="movement_modifier_key",Default=Enum.KeyCode.LeftShift,Mode="Hold",Callback=function() end})
    function M.IsLocal(ctrl)
        local service=Combat.Service()
        return M.active and service and service.Replicator and ctrl._localActor==service.Replicator.LocalActor
    end
    function M.CanMove(ctrl)
        local a=ctrl._localActor
        return a and not (a.Downed or a.Frozen or a.Forced or a.Rappelling or a.Ladder or ctrl.Goal or ctrl._forceCFrame or ctrl._startPhysics
            or (a.CurrentState and (a.CurrentState.Dragged or a.CurrentState.Emote)))
    end
    function M.Wrap(class,key,handler)
        local original=class[key]
        assert(type(original)=="function","Missing CharacterController."..key)
        local wrapper=function(ctrl,...)
            if M.IsLocal(ctrl) then return handler(original,ctrl,...) end
            return original(ctrl,...)
        end
        class[key]=wrapper
        table.insert(M.hooks,{class=class,key=key,original=original,wrapper=wrapper})
    end
    function M.Install(class)
        local standing
        -- shared.import belongs to the game's module environment, not the executor.
        local inspect=(debug and debug.getupvalues) or getupvalues
        if inspect then
            for _,fn in ipairs({class.new,class.Update}) do
                local ok,values=pcall(inspect,fn)
                if ok then
                    for _,value in pairs(values) do
                        if type(value)=="table" and type(value.CharacterHeightState)=="table" then
                            standing=value.CharacterHeightState.Standing
                            break
                        end
                    end
                end
                if standing~=nil then break end
            end
        end
        if standing==nil then warn("[Movements] Sprint options unavailable: controller enum could not be resolved") end
        for _,key in ipairs({"_accelerate","_decelerate","_exhaust","Update","_processNewPosition","_processMovementInput"}) do
            assert(type(class[key])=="function","Missing CharacterController."..key)
        end
        M.Wrap(class,"_processMovementInput",function(original,ctrl,input,dt)
            local actor=ctrl._localActor
            if standing~=nil and (M.OmniSprint or M.SprintCombat) and M.CanMove(ctrl) and ctrl.TrySprinting
                and ctrl.HeightState==standing and not ctrl.IsSliding and not ctrl.IsSwimming
                and not actor.CurrentState.Dragging and input.Magnitude>.01 then
                local directionOK=M.OmniSprint or input.Y<-.5
                local aimOK=M.SprintCombat or not actor.ADS
                if directionOK and aimOK then ctrl.IsSprinting=true end
            end
            return original(ctrl,input,dt)
        end)
        M.Wrap(class,"_accelerate",function(original,ctrl,dt,magnitude)
            local a=ctrl._localActor
            local saved={}
            local function change(object,key,value)
                table.insert(saved,{object=object,key=key,value=rawget(object,key)})
                object[key]=value
            end
            if M.Penalties then
                change(a,"SpeedPenalty",nil);change(a,"HitSlowness",nil)
                change(a,"CQB",nil);change(a,"Weight",0);change(ctrl,"_weightMulti",1)
            end
            if M.Survival or M.Penalties then
                local client=Combat.Service().LocalClient
                if client then
                    local full={getValue=function() return 1 end}
                    change(client,"Hunger",full);change(client,"Thirst",full)
                end
            end
            local result=table.pack(pcall(original,ctrl,M.Smoothing and 1000000 or dt,magnitude))
            for i=#saved,1,-1 do local v=saved[i];v.object[v.key]=v.value end
            if not result[1] then error(result[2],0) end
            if M.speedActive and M.CanMove(ctrl) then ctrl.MoveSpeed=M.SpeedValue*math.clamp(magnitude,0,1) end
            return table.unpack(result,2,result.n)
        end)
        M.Wrap(class,"_decelerate",function(original,ctrl,...)
            if M.Smoothing then ctrl.MoveSpeed=0;return end
            return original(ctrl,...)
        end)
        M.Wrap(class,"_exhaust",function(original,ctrl,...)
            if M.Stamina then ctrl._exhaustStart=tick()-2;ctrl._exhausted=tick()-1;return true end
            return original(ctrl,...)
        end)
        M.Wrap(class,"Update",function(original,ctrl,input,dt)
            if M.Stamina then ctrl._exhaustStart=tick()-2;ctrl._exhausted=tick()-1 end
            if M.Smoothing then ctrl._lastMovement=input end
            if not (M.flyActive and M.CanMove(ctrl)) then
                local result=table.pack(original(ctrl,input,dt))
                -- FirearmInventory checks Actor.Sprinting even inside its yielding fire loop.
                -- Keep physical sprint speed on the controller; expose a ready weapon pose.
                if M.SprintCombat and M.CanMove(ctrl) then
                    M.sprintActor=ctrl._localActor;M.sprintController=ctrl
                    ctrl._localActor.Sprinting=false
                else M.sprintActor=nil;M.sprintController=nil end
                return table.unpack(result,1,result.n)
            end
            local camera=workspace.CurrentCamera
            if not camera then return original(ctrl,input,dt) end
            local position=ctrl._position
            if ctrl._groundHitbox then position=ctrl._groundHitbox.CFrame:PointToWorldSpace(position) end
            local direction=Vector3.zero
            if not AimUIS:GetFocusedTextBox() then
                local function down(key) return AimUIS:IsKeyDown(key) and 1 or 0 end
                direction=camera.CFrame.LookVector*(down(Enum.KeyCode.W)-down(Enum.KeyCode.S))
                    +camera.CFrame.RightVector*(down(Enum.KeyCode.D)-down(Enum.KeyCode.A))
                    +Vector3.yAxis*(down(Enum.KeyCode.Space)-down(Enum.KeyCode.LeftControl))
            end
            if direction.Magnitude>1 then direction=direction.Unit end
            local speed=M.FlySpeed*(M.modifierActive and M.Multiplier or 1)
            local target=position+direction*speed*math.clamp(dt,0,.1)
            local grounded,normal=false,Vector3.yAxis
            if not M.Noclip then
                local oldPosition=ctrl._position
                ctrl._position=position
                local result=table.pack(pcall(ctrl._processNewPosition,ctrl,target))
                ctrl._position=oldPosition
                if not result[1] then error(result[2],0) end
                target,grounded,normal=result[2],result[3],result[4]
            end
            ctrl._position=target;ctrl._correctedPosition=target;ctrl._groundHitbox=nil
            ctrl.VelocityGravity=0;ctrl.MoveSpeed=0;ctrl.IsGrounded=grounded;ctrl.SlopeNormal=normal
            ctrl.IsSliding=false;ctrl.IsSprinting=false;ctrl._lastMovement=Vector2.zero
            local actor=ctrl._localActor
            actor.Platform=nil;actor.SimulatedPosition=target;actor.Grounded=grounded
            actor.Sliding=false;actor.Sprinting=false
        end)
    end
    function M.Destroy()
        M.active=false
        if M.sprintActor and M.sprintController then M.sprintActor.Sprinting=M.sprintController.IsSprinting end
        if M.connection then M.connection:Disconnect() end
        for i=#M.hooks,1,-1 do
            local h=M.hooks[i]
            if h.class[h.key]==h.wrapper then h.class[h.key]=h.original end
        end
        table.clear(M.hooks)
    end
    local oldDestroy=Combat.Destroy
    Combat.Destroy=function() M.Destroy();oldDestroy() end
    M.connection=AimRunService.Heartbeat:Connect(function()
        local focused=AimUIS:GetFocusedTextBox()~=nil
        if not focused then
            local speed=Combat.KeyActive(M.speedKey,M.speedState)
            local fly=Combat.KeyActive(M.flyKey,M.flyState)
            local boost=Combat.KeyActive(M.modifierKey,M.modifierState)
            M.speedActive=M.Speed and speed;M.flyActive=M.Fly and fly
            M.modifierActive=M.flyActive and M.Modifier and boost
        else M.speedActive=false;M.flyActive=M.Fly and M.flyActive;M.modifierActive=false end
        if not M.installed and tick()> (M.nextResolve or 0) then
            M.nextResolve=tick()+2
            for _,module in ipairs(getloadedmodules()) do
                if module.Name=="CharacterController" then
                    local ok,class=pcall(require,module)
                    if ok and type(class)=="table" then
                        local installed,err=pcall(M.Install,class)
                        if installed then M.installed=true
                        else M.Destroy();warn("[Movements] "..tostring(err)) end
                    end
                    break
                end
            end
        end
    end)
end

-- Gun controls: adapters are based on FirearmInventory, ViewmodelClass and Recoiler.
local GunPage,GunVisualsPage=MainWindow:AddTab({Text="Gun",Pages={"Weapon","Visuals"}})
local Gun={NoRecoil=false,InstantADS=false,NoSway=false,NoSpread=false,SpreadReduction=100,
    UnlockModes=false,AutoReload=false,ForceHeadshot=false,active=true,originals={},hooks={},nextResolve=0,
    Visuals=false,Transparency=0,Material="Original",visualParts={},nextVisualScan=0,nextReload=0,
    WeaponColor=Color3.fromRGB(150,80,255),Tracers=false,TracerStyle="Lightning",
    TracerColor=Color3.fromRGB(150,80,255),TracerDuration=.6,TracerWidth=.08}
Combat.Gun=Gun
function Gun.RestoreTunes()
    for tune,fields in pairs(Gun.originals) do
        for key,saved in pairs(fields) do
            if tune[key]==saved.applied then tune[key]=saved.value end
        end
    end
    Gun.originals={}
end
function Gun.ApplyField(tune,key,enabled,transform)
    local fields=Gun.originals[tune]
    local saved=fields and fields[key]
    if not enabled then
        if saved then
            if tune[key]==saved.applied then tune[key]=saved.value end
            fields[key]=nil
        end
        return
    end
    if not fields then fields={};Gun.originals[tune]=fields end
    if not saved then saved={value=tune[key]};fields[key]=saved
    elseif tune[key]~=saved.applied then saved.value=tune[key] end
    saved.applied=transform(saved.value)
    tune[key]=saved.applied
end
function Gun.RestoreModes(weapon)
    local tune=weapon and weapon._firearm and weapon._firearm.Tune
    local saved=tune and Gun.originals[tune] and Gun.originals[tune].Firemodes
    local meta=weapon and weapon._item and weapon._item.MetaData
    if saved and type(saved.value)=="table" and meta then
        local mode=tune.Firemodes[meta.Mode]
        meta.Mode=table.find(saved.value,mode) or 1
    end
    if tune then Gun.ApplyField(tune,"Firemodes",false) end
end
function Gun.UpdateTune()
    local c=Combat.Service()
    local actor=c and c.Replicator and c.Replicator.LocalActor
    local weapon=actor and actor._inventory and actor._inventory[actor._equipped]
    local tune=weapon and weapon._firearm and weapon._firearm.Tune
    if Gun.modeWeapon and (Gun.modeWeapon~=weapon or not Gun.UnlockModes) then
        Gun.RestoreModes(Gun.modeWeapon);Gun.modeWeapon=nil
    end
    for old in pairs(Gun.originals) do
        if old~=tune then
            Gun.ApplyField(old,"Firemodes",false)
            Gun.ApplyField(old,"Barrel_Spread",false)
            Gun.originals[old]=nil
        end
    end
    if type(tune)~="table" then return end
    Gun.ApplyField(tune,"Barrel_Spread",Gun.NoSpread,function(base)
        return (base or 1)*(1-Gun.SpreadReduction/100)
    end)
    if type(tune.Firemodes)=="table" then
        Gun.ApplyField(tune,"Firemodes",Gun.UnlockModes,function(base)
            if Gun.modeBase~=base then
                Gun.modeBase=base;Gun.modeList=table.clone(base)
                for _,mode in ipairs({0,1,2,3}) do
                    if not table.find(Gun.modeList,mode) then table.insert(Gun.modeList,mode) end
                end
            end
            return Gun.modeList
        end)
        if Gun.UnlockModes then Gun.modeWeapon=weapon end
    end
    local meta=weapon._item and weapon._item.MetaData
    if Gun.AutoReload and weapon.Equipped and not weapon._reloading and meta
        and (not weapon._mag or (weapon._mag.Capacity or 0)<=0)
        and (tune.NoChamber or not meta.Chamber) and os.clock()>=Gun.nextReload
        and type(weapon._reload)=="function" then
        Gun.nextReload=os.clock()+1
        task.defer(function()
            if Gun.active and Gun.AutoReload and weapon.Equipped and not weapon._reloading then
                weapon:_reload(true)
            end
        end)
    end
end
function Gun.RestoreVisuals()
    for part,saved in pairs(Gun.visualParts) do
        if part.Parent then
            for key,value in pairs(saved.original) do
                if part[key]==saved.applied[key] then part[key]=value end
            end
        end
    end
    Gun.visualParts={};Gun.visualModel=nil;Gun.nextVisualScan=0
end
function Gun.UpdateVisuals()
    local c=Combat.Service()
    local actor=c and c.Replicator and c.Replicator.LocalActor
    local weapon=actor and actor._inventory and actor._inventory[actor._equipped]
    local model=weapon and weapon._firearm and actor.ViewModel and actor.ViewModel.CurrentModel
    if not Gun.Visuals or model~=Gun.visualModel then Gun.RestoreVisuals() end
    if not Gun.Visuals or not model or not model.Parent then return end
    Gun.visualModel=model
    if os.clock()>=Gun.nextVisualScan then
        Gun.nextVisualScan=os.clock()+.2
        for _,part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") and part.Transparency<1 and not Gun.visualParts[part] then
                Gun.visualParts[part]={original={Material=part.Material,MaterialVariant=part.MaterialVariant,
                    Transparency=part.Transparency,Color=part.Color},applied={}}
            end
        end
    end
    for part,saved in pairs(Gun.visualParts) do
        if not part:IsDescendantOf(model) then
            if part.Parent then
                for key,value in pairs(saved.original) do
                    if part[key]==saved.applied[key] then part[key]=value end
                end
            end
            Gun.visualParts[part]=nil
        else
            local material=Gun.Material=="Original" and saved.original.Material or Enum.Material[Gun.Material]
            local values={Material=material,MaterialVariant=Gun.Material=="Original" and saved.original.MaterialVariant or "",
                Transparency=Gun.Transparency/100,Color=Gun.Material~="Original" and Gun.WeaponColor or saved.original.Color}
            for key,value in pairs(values) do
                saved.applied[key]=value
                if part[key]~=value then part[key]=value end
            end
        end
    end
end
function Gun.ClearTracers()
    if Gun.tracerFolder then Gun.tracerFolder:Destroy();Gun.tracerFolder=nil end
end
function Gun.TracerPoints(from,to,style,random)
    local length=(to-from).Magnitude
    if length<.01 then return {} end
    local cf=CFrame.lookAt(from,to)
    local turns=math.clamp(length/18,2,5)
    local smooth=style=="DNA"
    local count=style=="Line" and 1 or (smooth and math.ceil(turns*12) or math.clamp(math.ceil(length/3),12,48))
    local strands=style=="DNA" and 2 or 1
    local paths={}
    for strand=1,strands do
        local points={}
        for i=0,count do
            local t=i/count
            local offset=Vector3.zero
            if i>0 and i<count then
                if style=="Lightning" then
                    local radius=math.min(length*.025,.65)
                    offset=cf.RightVector*random:NextNumber(-radius,radius)+cf.UpVector*random:NextNumber(-radius,radius)
                elseif style=="DNA" then
                    -- Keep the helix open through the middle; taper only its ends.
                    local angle=t*math.pi*2*turns+(strand-1)*math.pi*2/strands
                    local envelope=math.sin(math.min(1,math.min(t,1-t)*8)*math.pi*.5)
                    local radius=math.min(length*.03,.45)*envelope
                    offset=(cf.RightVector*math.cos(angle)+cf.UpVector*math.sin(angle))*radius
                end
            end
            points[#points+1]=from:Lerp(to,t)+offset
        end
        paths[#paths+1]=points
    end
    return paths
end
function Gun.DrawTracer(from,to)
    if not Gun.active or not Gun.Tracers or typeof(from)~="Vector3" or typeof(to)~="Vector3" then return end
    local paths=Gun.TracerPoints(from,to,Gun.TracerStyle,Random.new())
    if #paths==0 or not workspace.CurrentCamera then return end
    if not Gun.tracerFolder then
        Gun.tracerFolder=Instance.new("Folder");Gun.tracerFolder.Name="LeanGunTracers"
    end
    Gun.tracerFolder.Parent=workspace.CurrentCamera
    local existing=Gun.tracerFolder:GetChildren()
    if #existing>=24 then existing[1]:Destroy() end
    local anchor=Instance.new("Part")
    anchor.Name="Tracer";anchor.Anchored=true;anchor.Transparency=1;anchor.Size=Vector3.one*.01
    anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false;anchor.CastShadow=false
    anchor.CFrame=CFrame.new(from);anchor.Parent=Gun.tracerFolder
    local function connect(a,b,width)
        local beam=Instance.new("Beam")
        beam.Attachment0=a;beam.Attachment1=b;beam.FaceCamera=true
        beam.Width0=width;beam.Width1=width;beam.Segments=1
        beam.Color=ColorSequence.new(Gun.TracerColor);beam.LightEmission=1;beam.LightInfluence=0
        beam.Transparency=NumberSequence.new(0);beam.Parent=anchor
        game:GetService("TweenService"):Create(beam,TweenInfo.new(Gun.TracerDuration),{Width0=0,Width1=0}):Play()
    end
    local attachments={}
    for index,points in ipairs(paths) do
        local list={};attachments[index]=list
        for i,point in ipairs(points) do
            local a=Instance.new("Attachment");a.Position=point-from;a.Parent=anchor;list[i]=a
            if i>1 then connect(list[i-1],a,Gun.TracerWidth) end
        end
    end
    if Gun.TracerStyle=="DNA" and #attachments==2 then
        for i=4,#attachments[1]-3,3 do connect(attachments[1][i],attachments[2][i],Gun.TracerWidth*.35) end
    end
    game:GetService("Debris"):AddItem(anchor,Gun.TracerDuration)
end
function Gun.Hook(class,key,make)
    local original=class[key]
    if type(original)~="function" then return false end
    local raw=rawget(class,key)
    local wrapper=make(original)
    class[key]=wrapper
    Gun.hooks[#Gun.hooks+1]={class=class,key=key,raw=raw,wrapper=wrapper}
    return true
end
function Gun.Resolve()
    if os.clock()<Gun.nextResolve then return end
    Gun.nextResolve=os.clock()+2
    local service=Combat.Service()
    local replicator=service and service.Replicator
    if replicator and replicator~=Gun.effectsReplicator and type(replicator._bulletEffects)=="function" then
        if Gun.Hook(replicator,"_bulletEffects",function(original)
            return function(self,from,to,part,normal,material,caliber,isLocal,...)
                local result=table.pack(original(self,from,to,part,normal,material,caliber,isLocal,...))
                if isLocal then
                    local ok,err=pcall(Gun.DrawTracer,from,to)
                    if not ok then Gun.tracerError=tostring(err) end
                end
                return table.unpack(result,1,result.n)
            end
        end) then Gun.effectsReplicator=replicator end
    end
    if replicator and replicator~=Gun.impactReplicator and type(replicator._bulletProcess)=="function" then
        if Gun.Hook(replicator,"_bulletProcess",function(original)
            return function(self,uid,replicate,position,part,normal,material,elapsed,...)
                if Gun.active and Gun.ForceHeadshot and replicate and part then
                    local actorUID,actor=self:GetFromBodyPart(part)
                    local kind=actor and Combat.Kind(actor)
                    local head=actor and actor.Parts and actor.Parts.Head
                    local friendly=kind=="Players" and actor.Owner.Team~=nil
                        and actor.Owner.Team==AimLocalPlayer.Team
                    if actorUID and kind and not friendly and head and head.Parent
                        and head:IsDescendantOf(actor.Character) then
                        part=head
                    end
                end
                return original(self,uid,replicate,position,part,normal,material,elapsed,...)
            end
        end) then Gun.impactReplicator=replicator end
    end
    for _,m in ipairs(getloadedmodules()) do
        if m.Name=="Recoiler" and not Gun.recoiler then
            local ok,class=pcall(require,m)
            if ok and type(class)=="table" then
                Gun.Hook(class,"GetViewmodelAdjustment",function(original)
                    return function(self,...)
                        if Gun.active and Gun.NoRecoil then return CFrame.identity end
                        return original(self,...)
                    end
                end)
                Gun.Hook(class,"GetCameraAdjustment",function(original)
                    return function(self,...)
                        if Gun.active and Gun.NoRecoil then return CFrame.identity,0 end
                        return original(self,...)
                    end
                end)
                Gun.recoiler=true
            end
        elseif m.Name=="ViewmodelClass" and not Gun.viewmodel then
            local ok,class=pcall(require,m)
            if ok and type(class)=="table" then
                Gun.viewmodel=Gun.Hook(class,"Update",function(original)
                    return function(vm,...)
                        local c=Combat.Service()
                        local localActor=c and c.Replicator and c.Replicator.LocalActor
                        if not Gun.active or vm.Actor~=localActor then return original(vm,...) end
                        if Gun.InstantADS then
                            vm.ADSLerp=(localActor.ADS and not vm.Reloading and not localActor.Sliding) and 1 or 0
                        end
                        local sway,kick=vm._swaySpring,vm.Kick
                        if Gun.NoSway and sway then
                            vm._swaySpring={Position={ToCFrame=function() return CFrame.identity end}}
                        end
                        if Gun.NoRecoil and kick then vm.Kick={Position=Vector3.zero} end
                        local result=table.pack(pcall(original,vm,...))
                        vm._swaySpring=sway;vm.Kick=kick
                        if not result[1] then error(result[2],0) end
                        return table.unpack(result,2,result.n)
                    end
                end)
            end
        end
    end
end
function Gun.Destroy()
    Gun.active=false
    Gun.RestoreModes(Gun.modeWeapon)
    Gun.RestoreTunes()
    Gun.RestoreVisuals()
    Gun.ClearTracers()
    for _,h in ipairs(Gun.hooks) do
        if h.class[h.key]==h.wrapper then h.class[h.key]=h.raw end
    end
    Gun.hooks={}
end
local destroyCombat=Combat.Destroy
Combat.Destroy=function() Gun.Destroy();destroyCombat() end
local GunHandling=GunPage:AddSection({Title="Handling",Side="Left"})
for _,entry in ipairs({{"No Recoil","NoRecoil"},{"Instant ADS","InstantADS"},{"No Sway","NoSway"}}) do
    local key=entry[2]
    GunHandling:AddToggle({Text=entry[1],Flag="gun_"..key,Default=false,
        Callback=function(v) Gun[key]=v end})
end
local GunBallistics=GunPage:AddSection({Title="Ballistics",Side="Right"})
GunBallistics:AddToggle({Text="No Spread",Flag="gun_no_spread",Default=false,
    Callback=function(v) Gun.NoSpread=v;Gun.UpdateTune() end})
GunBallistics:AddSlider({Text="Spread Reduction",Flag="gun_spread_reduction",
    Min=0,Max=100,Rounding=1,Default=100,Suffix="%",
    Callback=function(v) Gun.SpreadReduction=v;Gun.UpdateTune() end})
GunHandling:AddToggle({Text="All Firemodes",Flag="gun_unlock_modes",Default=false,
    Callback=function(v) Gun.UnlockModes=v;Gun.UpdateTune() end})
GunHandling:AddToggle({Text="Auto Reload",Flag="gun_auto_reload",Default=false,
    Callback=function(v) Gun.AutoReload=v;Gun.UpdateTune() end})
GunBallistics:AddToggle({Text="Force Headshot",Flag="gun_force_headshot",Default=false,
    Callback=function(v) Gun.ForceHeadshot=v end})
local GunVisualSection=GunVisualsPage:AddSection({Title="Weapon Appearance",Side="Left"})
GunVisualSection:AddToggle({Text="Enabled",Flag="gun_visuals",Default=false,
    Callback=function(v) Gun.Visuals=v;Gun.UpdateVisuals() end})
GunVisualSection:AddDropdown({Text="Material",Flag="gun_material",Default="Original",
    Options={"Original","ForceField","Neon","SmoothPlastic","Glass","Metal","Ice"},
    Callback=function(v) Gun.Material=v;Gun.UpdateVisuals() end})
GunVisualSection:AddSlider({Text="Transparency",Flag="gun_transparency",Min=0,Max=100,Rounding=1,
    Default=0,Suffix="%",Callback=function(v) Gun.Transparency=v;Gun.UpdateVisuals() end})
GunVisualSection:AddColorPicker({Text="Weapon Color",Flag="gun_weapon_color",Default=Gun.WeaponColor,
    Callback=function(v) Gun.WeaponColor=v;Gun.UpdateVisuals() end})
local GunTracerSection=GunVisualsPage:AddSection({Title="Bullet Tracers",Side="Right"})
GunTracerSection:AddToggle({Text="Enabled",Flag="gun_tracers",Default=false,
    Callback=function(v) Gun.Tracers=v;if not v then Gun.ClearTracers() end end})
GunTracerSection:AddDropdown({Text="Effect",Flag="gun_tracer_style",Default="Lightning",
    Options={"Line","Lightning","DNA"},Callback=function(v)
        Gun.TracerStyle=(v=="Line" or v=="Lightning" or v=="DNA") and v or "Lightning"
    end})
GunTracerSection:AddColorPicker({Text="Tracer Color",Flag="gun_tracer_color",Default=Gun.TracerColor,
    Callback=function(v)
        Gun.TracerColor=v
        if Gun.tracerFolder then
            for _,beam in ipairs(Gun.tracerFolder:GetDescendants()) do
                if beam:IsA("Beam") then beam.Color=ColorSequence.new(v) end
            end
        end
    end})
GunTracerSection:AddSlider({Text="Duration",Flag="gun_tracer_duration",Min=.1,Max=3,Rounding=.1,
    Default=.6,Suffix=" s",Callback=function(v) Gun.TracerDuration=v end})
GunTracerSection:AddSlider({Text="Width",Flag="gun_tracer_width",Min=.02,Max=.3,Rounding=.01,
    Default=.08,Callback=function(v) Gun.TracerWidth=v end})
table.insert(Combat.connections,AimRunService.RenderStepped:Connect(function()
    if Gun.active then Gun.Resolve();Gun.UpdateTune();Gun.UpdateVisuals() end
end))

table.insert(Combat.connections,AimRunService.RenderStepped:Connect(Combat.Frame))
Combat.Install()
print("LEAN_COMBAT_READY",Combat.hookState)
-- Separate NPC/player renderers. Targets come exclusively from the game Actor registry.
local Sense = (function()
    local E = {
        _hasLoaded = false, objects = {}, errors = {}, scanAt = 0,
        sharedSettings = {textSize=13, textFont=2, limitDistance=false, maxDistance=1000,
            teamBasedColor=false, neutralColor=Color3.fromRGB(100,220,150)},
        teamSettings = {}, chams = {}, advanced = {},
    }
    local white, black = Color3.new(1,1,1), Color3.new(0,0,0)
    local t = {
        enabled=true, box=false, box3d=false, boxColor={white,1}, box3dColor={white,1},
        boxOutline=true, boxOutlineColor={black,1}, boxOutlineThickness=1,
        boxFill=false, boxFillColor={Color3.fromRGB(150,80,255),.2},
        healthBar=false, healthyColor=Color3.new(0,1,0), dyingColor=Color3.new(1,0,0),
        healthBarOutline=true, healthText=false, healthTextColor={white,1}, healthTextOutline=true,
        name=false, nameColor={white,1}, nameOutline=true,
        weapon=false, weaponColor={white,1}, weaponOutline=true,
        distance=false, distanceColor={white,1}, distanceOutline=true,
        tracer=false, tracerOrigin="Bottom", tracerColor={white,1}, tracerOutline=true,
        offScreenArrow=false, offScreenArrowSize=15, offScreenArrowRadius=150,
        offScreenArrowColor={white,1},
    }
    E.teamSettings.npc = t
    E.teamSettings.players={}
    for k,v in pairs(t) do E.teamSettings.players[k]=type(v)=="table" and table.clone(v) or v end
    E.teamSettings.players.enabled=false
    E.teamSettings.players.teamCheck=false
    E.teamSettings.players.boxOutlineThickness=1
    E.chams.npc = {enabled=false, visibleColor=Color3.fromRGB(0,255,100),visibleIntensity=.85,
        occludedColor=white,occludedIntensity=.25}
    E.advanced.npc = {nameType="Name",skeleton=false,skeletonColor=white}
    E.chams.players=table.clone(E.chams.npc)
    E.advanced.players=table.clone(E.advanced.npc)
    for _,kind in ipairs({"zombies","corpses"}) do
        E.teamSettings[kind]={}
        for k,v in pairs(t) do E.teamSettings[kind][k]=type(v)=="table" and table.clone(v) or v end
        E.teamSettings[kind].enabled=false
        E.teamSettings[kind].name=true
        E.teamSettings[kind].distance=true
        E.chams[kind]=table.clone(E.chams.npc)
        E.advanced[kind]=table.clone(E.advanced.npc)
    end
    local service, resolveAt, connection, anchor
    local signs = {Vector3.new(-1,-1,-1),Vector3.new(-1,1,-1),Vector3.new(-1,1,1),Vector3.new(-1,-1,1),
        Vector3.new(1,-1,-1),Vector3.new(1,1,-1),Vector3.new(1,1,1),Vector3.new(1,-1,1)}
    local edges = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}
    local ray = RaycastParams.new()
    ray.FilterType = Enum.RaycastFilterType.Exclude
    ray.IgnoreWater = true
    function E.Service()
        if service then return service end
        if resolveAt and os.clock() < resolveAt then return nil end
        resolveAt = os.clock()+2
        for _, module in ipairs(getloadedmodules()) do
            if module.Name == "ClientService" then
                local ok, value = pcall(require,module)
                if ok and type(value)=="table" and value.Replicator then service=value; break end
            end
        end
        return service
    end
    function E.IsNPC(actor)
        local c = E.Service()
        local registry = c and c.Replicator and c.Replicator.Actors
        return type(actor)=="table" and registry and actor.UID and registry[actor.UID]==actor
            and actor.Owner==nil and actor.IsLocalPlayer~=true
            and typeof(actor.Character)=="Instance" and actor.Character:IsA("Model")
    end
    function E.IsPlayer(actor)
        local c=E.Service();local registry=c and c.Replicator and c.Replicator.Actors
        return type(actor)=="table" and registry and actor.UID and registry[actor.UID]==actor
            and typeof(actor.Owner)=="Instance" and actor.Owner:IsA("Player")
            and actor.Owner~=AimLocalPlayer and actor.IsLocalPlayer~=true
            and typeof(actor.Character)=="Instance" and actor.Character:IsA("Model")
    end
    function E.Kind(actor)
        if E.IsNPC(actor) or E.IsPlayer(actor) then
            if not Combat.IsAlive(actor) then return "corpses" end
            if actor.Zombie then return "zombies" end
        end
        if E.IsNPC(actor) then return "npc" end
        if E.IsPlayer(actor) then return "players" end
    end
    local function newDrawing(o,key,class,props)
        local d = (E.DrawingFactory or Drawing.new)(class)
        d.Visible=false
        d.Transparency=1
        for k,v in pairs(props or {}) do d[k]=v end
        o.drawings[key]=d
        return d
    end
    local function drawing(o,key,class,props)
        return o.drawings[key] or newDrawing(o,key,class,props)
    end
    local function hide(o)
        for _,d in pairs(o.drawings) do d.Visible=false end
        for _,d in pairs(o.adornments) do d.Visible=false end
    end
    local function destroy(o)
        for _,d in pairs(o.drawings) do d:Remove() end
        for _,d in pairs(o.adornments) do d:Destroy() end
    end
    local function rig(o)
        o.parts={}; o.links={}
        local seen={}
        for _,part in pairs(o.actor.Parts or {}) do
            if typeof(part)=="Instance" and part:IsA("BasePart") and part:IsDescendantOf(o.model) then
                o.parts[#o.parts+1]=part; seen[part]=true
            end
        end
        if #o.parts==0 then
            for _,part in ipairs(o.model:GetChildren()) do
                if part:IsA("BasePart") and part~=o.actor.RootPart then o.parts[#o.parts+1]=part;seen[part]=true end
            end
        end
        for _,joint in ipairs(o.model:GetDescendants()) do
            if joint:IsA("Motor6D") and seen[joint.Part0] and seen[joint.Part1] then
                o.links[#o.links+1]={joint.Part0,joint.Part1}
            elseif joint:IsA("BallSocketConstraint") or joint:IsA("HingeConstraint") then
                local a,b=joint.Attachment0,joint.Attachment1
                if a and b and seen[a.Parent] and seen[b.Parent] then o.links[#o.links+1]={a.Parent,b.Parent} end
            elseif joint:IsA("Bone") and joint.Parent:IsA("Bone") then
                o.links[#o.links+1]={joint.Parent,joint}
            end
        end
    end
    function E.Sync(force)
        if not force and os.clock()<E.scanAt then return end
        E.scanAt=os.clock()+.4
        for actor,o in pairs(E.objects) do
            if not E.Kind(actor) or actor.Character~=o.model or not o.model.Parent then
                destroy(o);E.objects[actor]=nil
            end
        end
        local c=E.Service()
        for _,actor in pairs(c and c.Replicator and c.Replicator.Actors or {}) do
            if E.Kind(actor) and actor.Character.Parent then
                local o=E.objects[actor]
                if not o then
                    o={actor=actor,model=actor.Character,drawings={},adornments={},nextRay=0}
                    E.objects[actor]=o;rig(o)
                else rig(o) end
            end
        end
    end
    local function color(value)
        if typeof(value)=="Color3" then return value,1 end
        if type(value)=="table" then return value[1],math.clamp(value[2] or 1,0,1) end
        return white,1
    end
    function E.TeamColor(actor)
        if E.IsPlayer(actor) and actor.Owner.Team then return actor.Owner.Team.TeamColor.Color end
        for _,value in pairs({actor.TeamColor,actor.FactionColor,actor.Team,actor.Faction,actor.Company}) do
            if typeof(value)=="Color3" then return value end
            if typeof(value)=="BrickColor" then return value.Color end
            if typeof(value)=="Instance" and value:IsA("Team") then return value.TeamColor.Color end
            if type(value)=="table" then
                if typeof(value.Color)=="Color3" then return value.Color end
                if typeof(value.TeamColor)=="BrickColor" then return value.TeamColor.Color end
            end
        end
        return E.sharedSettings.neutralColor
    end
    local function style(d,value,override)
        local c,a=color(value);d.Color=override or c;d.Transparency=a;d.Visible=a>0
    end
    local function clipLine(a,b)
        local v=workspace.CurrentCamera.ViewportSize
        local delta=b-a
        local lo,hi=0,1
        for _,test in ipairs({{-delta.X,a.X},{delta.X,v.X-a.X},{-delta.Y,a.Y},{delta.Y,v.Y-a.Y}}) do
            local p,q=test[1],test[2]
            if math.abs(p)<1e-8 then if q<0 then return nil end
            else
                local r=q/p
                if p<0 then lo=math.max(lo,r) else hi=math.min(hi,r) end
                if lo>hi then return nil end
            end
        end
        return a+delta*lo,a+delta*hi
    end
    local function line(o,key,a,b,value,thickness,override)
        a,b=clipLine(a,b)
        if not a then return nil end
        local d=drawing(o,key,"Line")
        d.From=a;d.To=b;d.Thickness=thickness or 1;style(d,value,override)
        return d
    end
    local function square(o,key,pos,size,value,filled,thickness,override)
        local view=workspace.CurrentCamera.ViewportSize
        local corner=(pos+size):Min(view)
        pos=pos:Max(Vector2.zero)
        size=corner-pos
        if size.X<=0 or size.Y<=0 then return nil end
        local d=drawing(o,key,"Square")
        d.Position=pos;d.Size=size;d.Filled=filled;d.Thickness=thickness or 1;style(d,value,override)
        return d
    end
    local function textAt(o,key,value,pos,col,outline,override)
        local view=workspace.CurrentCamera.ViewportSize
        if pos.X<0 or pos.Y<0 or pos.X>view.X or pos.Y>view.Y then return end
        local d=drawing(o,key,"Text")
        d.Text=tostring(value);d.Position=pos;d.Size=E.sharedSettings.textSize
        d.Font=E.sharedSettings.textFont;d.Center=true;d.Outline=outline;d.OutlineColor=black
        style(d,col,override)
    end
    local function partPosition(p)
        return p:IsA("Bone") and p.WorldPosition or p.Position
    end
    local function bodyBounds(o,delta,position)
        local lo,hi
        for _,p in ipairs(o.parts) do
            if p.Parent then
                local cf=p.CFrame;local h=p.Size*.5
                local r,u,l=cf.RightVector,cf.UpVector,cf.LookVector
                local extent=Vector3.new(math.abs(r.X)*h.X+math.abs(u.X)*h.Y+math.abs(l.X)*h.Z,
                    math.abs(r.Y)*h.X+math.abs(u.Y)*h.Y+math.abs(l.Y)*h.Z,
                    math.abs(r.Z)*h.X+math.abs(u.Z)*h.Y+math.abs(l.Z)*h.Z)
                local center=p.Position+delta
                lo=lo and lo:Min(center-extent) or center-extent
                hi=hi and hi:Max(center+extent) or center+extent
            end
        end
        if not lo then return position,Vector3.new(2,5,2) end
        return (lo+hi)*.5,hi-lo
    end
    function E.Weapon(actor)
        local item=actor._inventory and actor._inventory[actor._equipped]
        if not item then return "Unarmed" end
        local model=item._heroModel or item._lodModel
        if typeof(model)=="Instance" then return model.Name:gsub("^AI_","") end
        local name=item._item and item._item.Name
        return name and name:gsub("^FirearmPrimary",""):gsub("^AI_","") or "Unknown"
    end
    local function chams(o,camera,delta,position,teamColor)
        local cfg=E.chams[E.Kind(o.actor)]
        if not cfg then return end
        if not cfg.enabled then return end
        if os.clock()>=o.nextRay then
            o.nextRay=os.clock()+.12
            local c=E.Service();local me=c and c.Replicator and c.Replicator.LocalActor
            local ignore={o.model,workspace.CurrentCamera}
            if me and me.Character then ignore[#ignore+1]=me.Character end
            ray.FilterDescendantsInstances=ignore
            o.partClear={}
            for _,p in ipairs(o.parts) do
                if p:IsDescendantOf(o.model) then
                    local cf=Combat.PartCFrame(o.actor,p)
                    for _,offset in ipairs({0,.35,-.35}) do
                        local point=cf:PointToWorldSpace(Vector3.new(0,p.Size.Y*offset,0))
                        local hit=workspace:Raycast(camera.CFrame.Position,point-camera.CFrame.Position,ray)
                        if not hit then o.partClear[p]=true;break end
                    end
                end
            end
        end
        if not anchor then
            anchor=Instance.new("Part");anchor.Name="LeanNPCOverlayAnchor"
            anchor.Size=Vector3.new(.01,.01,.01);anchor.CFrame=CFrame.identity
            anchor.Transparency=1;anchor.Anchored=true;anchor.CanCollide=false
            anchor.CanTouch=false;anchor.CanQuery=false;anchor.CastShadow=false
        end
        anchor.Parent=workspace.CurrentCamera
        for i,p in ipairs(o.parts) do
            if p:IsDescendantOf(o.model) and p~=o.actor.RootPart then
                local clear=o.partClear and o.partClear[p]
                local col=clear and cfg.visibleColor or cfg.occludedColor
                local alpha=clear and cfg.visibleIntensity or cfg.occludedIntensity
                local ad=o.adornments[i]
                if not ad then
                    ad=Instance.new("BoxHandleAdornment");ad.Name="LeanNPCChams"
                    ad.Adornee=anchor;ad.AlwaysOnTop=true;ad.ZIndex=3;ad.Parent=anchor
                    o.adornments[i]=ad
                end
                ad.Size=p.Size;ad.CFrame=Combat.PartCFrame(o.actor,p);ad.Color3=teamColor or col
                ad.Transparency=1-math.clamp(alpha,0,1);ad.Visible=alpha>0
            end
        end
    end
    function E.RenderActor(o,camera,origin)
        hide(o)
        local a=o.actor
        local kind=E.Kind(a)
        if not kind then return end
        local t=E.teamSettings[kind]
        if kind=="players" and t.teamCheck and AimLocalPlayer.Team~=nil and a.Owner.Team==AimLocalPlayer.Team then return end
        -- Fail closed every frame, including owner changes and replacement models.
        if not t.enabled or not E.Kind(a) or a.Character~=o.model or not o.model.Parent
            or (kind~="corpses" and not Combat.IsAlive(a)) then return end
        local root=a.RootPart
        local position=a.Position or (root and root.Position)
        if kind=="corpses" then
            if not o.model:IsDescendantOf(workspace) then return end
            root=nil
            position=o.model:GetPivot().Position
        end
        if typeof(position)~="Vector3" then return end
        local dist=(position-origin).Magnitude
        local shared=E.sharedSettings
        if shared.limitDistance and dist>shared.maxDistance then return end
        local adv=E.advanced[kind]
        local override=shared.teamBasedColor and E.TeamColor(a) or nil
        local delta=root and position-root.Position or Vector3.zero
        local view=camera.ViewportSize
        local sp,onScreen=camera:WorldToViewportPoint(position)
        if not onScreen and t.offScreenArrow then
            local rel=camera.CFrame:PointToObjectSpace(position)
            local direction=Vector2.new(rel.X,rel.Z)
            if direction.Magnitude<.0001 then direction=Vector2.new(0,1) else direction=direction.Unit end
            local center=view*.5
            local radius=math.min(t.offScreenArrowRadius,math.max(0,math.min(view.X,view.Y)*.5-t.offScreenArrowSize-4))
            local tip=center+direction*radius
            local back=tip-direction*t.offScreenArrowSize
            local side=Vector2.new(-direction.Y,direction.X)*t.offScreenArrowSize*.5
            local d=drawing(o,"arrow","Triangle")
            d.PointA=tip;d.PointB=back+side;d.PointC=back-side;d.Filled=true;style(d,t.offScreenArrowColor,override)
        end
        if sp.Z<=.05 then return end
        local needsBox=t.box or t.box3d or t.boxFill or t.name or t.weapon or t.distance or t.healthBar or t.healthText or t.tracer
        local min,max,corners
        if needsBox then
            local center,size=bodyBounds(o,delta,position)
            corners={}
            for i,sign in ipairs(signs) do
                local p=camera:WorldToViewportPoint(center+size*.5*sign)
                corners[i]=p
                if p.Z>.05 then
                    local v=Vector2.new(p.X,p.Y)
                    min=min and min:Min(v) or v;max=max and max:Max(v) or v
                end
            end
        end
        local boxVisible=min and max and max.X>=0 and max.Y>=0 and min.X<=view.X and min.Y<=view.Y
        if onScreen or boxVisible then chams(o,camera,delta,position,override) end
        if boxVisible then
            local size=max-min;local cx=(min.X+max.X)*.5
            if t.boxFill then square(o,"fill",min,size,t.boxFillColor,true,1,override) end
            if t.box then
                if t.boxOutline then square(o,"boxOutline",min,size,t.boxOutlineColor,false,1+2*t.boxOutlineThickness) end
                square(o,"box",min,size,t.boxColor,false,1,override)
            end
            if t.box3d then
                for i,edge in ipairs(edges) do
                    local p,q=corners[edge[1]],corners[edge[2]]
                    if p.Z>.05 and q.Z>.05 then
                        local v,w=Vector2.new(p.X,p.Y),Vector2.new(q.X,q.Y)
                        if t.boxOutline then line(o,"edgeOutline"..i,v,w,t.boxOutlineColor,1+2*t.boxOutlineThickness) end
                        line(o,"edge"..i,v,w,t.box3dColor,1,override)
                    end
                end
            end
            local hp,maxhp=type(a.Health)=="number" and a.Health or 0,a.MaxHealth or 100
            local ratio=math.clamp(hp/math.max(1,maxhp),0,1)
            if t.healthBar then
                local bottom=Vector2.new(min.X-5,max.Y)
                if t.healthBarOutline then line(o,"hpOutline",bottom+Vector2.new(0,1),Vector2.new(min.X-5,min.Y-1),black,4) end
                line(o,"hp",bottom,Vector2.new(min.X-5,max.Y-size.Y*ratio),t.dyingColor:Lerp(t.healthyColor,ratio),2)
            end
            if t.healthText then textAt(o,"hpText",math.ceil(hp),Vector2.new(min.X-20,max.Y-size.Y*ratio-shared.textSize*.5),t.healthTextColor,t.healthTextOutline) end
            if t.name then
                local label=kind=="players" and a.Owner.Name or o.model.Name
                if kind=="players" and adv.nameType=="Display Name" then label=a.Owner.DisplayName
                elseif adv.nameType=="Display Name" then
                    label=a.DisplayName or (a.OwnerName~="???" and a.OwnerName) or (a.Zombie and "Zombie" or "NPC")
                    label=tostring(label).." ["..tostring(a.UID):sub(1,6).."]"
                end
                if kind=="zombies" then label="Zombie"
                elseif kind=="corpses" then label="Corpse: "..(a.Zombie and "Zombie" or (E.IsPlayer(a) and a.Owner.Name or "NPC")) end
                textAt(o,"name",label,Vector2.new(cx,min.Y-shared.textSize-3),t.nameColor,t.nameOutline,override)
            end
            local textY=max.Y+2
            if kind=="players" and t.weapon then textAt(o,"weapon",E.Weapon(a),Vector2.new(cx,textY),t.weaponColor,t.weaponOutline,override);textY+=shared.textSize+2 end
            if t.distance then textAt(o,"distance",string.format("%.0f studs",dist),Vector2.new(cx,textY),t.distanceColor,t.distanceOutline,override) end
            if t.tracer then
                local y=t.tracerOrigin=="Top" and 0 or (t.tracerOrigin=="Middle" and view.Y*.5 or view.Y)
                local from,to=Vector2.new(view.X*.5,y),Vector2.new(cx,max.Y)
                if t.tracerOutline then line(o,"tracerOutline",from,to,black,3) end
                line(o,"tracer",from,to,t.tracerColor,1,override)
            end
        end
        if adv.skeleton then
            for i,pair in ipairs(o.links) do
                if pair[1].Parent and pair[2].Parent then
                    local p,po=camera:WorldToViewportPoint(partPosition(pair[1])+delta)
                    local q,qo=camera:WorldToViewportPoint(partPosition(pair[2])+delta)
                    if p.Z>.05 and q.Z>.05 and (po or qo) then
                        line(o,"bone"..i,Vector2.new(p.X,p.Y),Vector2.new(q.X,q.Y),adv.skeletonColor,1,override)
                    end
                end
            end
        end
    end
    function E.Render(cameraOverride)
        if E.Paused then return end
        E.Sync()
        local camera=cameraOverride or workspace.CurrentCamera
        if not camera then return end
        local c=E.Service();local me=c and c.Replicator and c.Replicator.LocalActor
        local origin=me and me.Position or camera.CFrame.Position
        for actor,o in pairs(E.objects) do
            local ok,err=pcall(E.RenderActor,o,camera,origin)
            if not ok then
                hide(o)
                if not E.errors[tostring(err)] then E.errors[tostring(err)]=true;warn("[NPC ESP]",err) end
            end
        end
    end
    function E.Load()
        if E._hasLoaded then return end
        E._hasLoaded=true
        E.Sync(true)
        connection=AimRunService.RenderStepped:Connect(function() E.Render() end)
    end
    function E.Unload()
        if connection then connection:Disconnect();connection=nil end
        for a,o in pairs(E.objects) do destroy(o);E.objects[a]=nil end
        if anchor then anchor:Destroy();anchor=nil end
        E._hasLoaded=false
    end
    return E
end)()
local ChamsEngine, AdvancedESP = Sense.chams, Sense.advanced
local function espSetColor(tbl,key)
    return function(c,a)
        if type(tbl[key])=="table" then tbl[key][1]=c;if a~=nil then tbl[key][2]=a end
        else tbl[key]=c end
    end
end
local function espDefault(tbl,key)
    if type(tbl[key])=="table" then return tbl[key][1],tbl[key][2] end
    return tbl[key],1
end


local NpcGeneral = NpcPage:AddSection({Title="General",Side="Left"})
NpcGeneral:AddToggle({Text="ESP Enabled",Flag="npc_enabled",Default=true,
    Callback=function(v) Sense.teamSettings.npc.enabled=v end})
local function buildTeamPage(page, team)
    local t     = Sense.teamSettings[team]
    local chams = ChamsEngine[team]
    local adv   = AdvancedESP[team]
    local prefix = team .. "_"

    -- Box state (single toggle + 2D/3D dropdown, mutually exclusive)
    local boxState = {enabled = false, kind = "2D"}
    local function applyBox()
        t.box   = boxState.enabled and boxState.kind == "2D"
        t.box3d = boxState.enabled and boxState.kind == "3D"
    end

    -- ═══ LEFT: Boxes ═══════════════════════════════════════════
    local Boxes = page:AddSection({Title = "Boxes", Side = "Left"})

    Boxes:AddToggle({
        Text = "Box",
        Flag = prefix .. "box",
        Default = false,
        Callback = function(v) boxState.enabled = v; applyBox() end
    })

    Boxes:AddDropdown({
        Text = "Box Type",
        Flag = prefix .. "box_type",
        Options = {"2D", "3D"},
        Default = "2D",
        Callback = function(v) boxState.kind = v; applyBox() end
    })

    Boxes:AddColorPicker({
        Text = "Box Color",
        Flag = prefix .. "boxColor",
        Default = (espDefault(t, "boxColor")),
        Transparency = select(2, espDefault(t, "boxColor")),
        Callback = function(color, alpha)
            -- one picker drives both 2D and 3D box colors
            espSetColor(t, "boxColor")(color, alpha)
            espSetColor(t, "box3dColor")(color, alpha)
        end
    })

    Boxes:AddToggle({
        Text = "Box Outline",
        Flag = prefix .. "boxOutline",
        Default = t.boxOutline,
        Callback = function(v) t.boxOutline = v end
    })

    Boxes:AddColorPicker({
        Text = "Outline Color",
        Flag = prefix .. "boxOutlineColor",
        Default = (espDefault(t, "boxOutlineColor")),
        Transparency = select(2, espDefault(t, "boxOutlineColor")),
        Callback = espSetColor(t, "boxOutlineColor")
    })

    Boxes:AddToggle({
        Text = "Box Fill",
        Flag = prefix .. "boxFill",
        Default = t.boxFill,
        Callback = function(v) t.boxFill = v end
    })

    Boxes:AddColorPicker({
        Text = "Fill Color",
        Flag = prefix .. "boxFillColor",
        Default = (espDefault(t, "boxFillColor")),
        Transparency = select(2, espDefault(t, "boxFillColor")),
        Callback = espSetColor(t, "boxFillColor")
    })

    -- ═══ LEFT: Health ══════════════════════════════════════════
    if team=="npc" or team=="players" then
    local Health = page:AddSection({Title = "Health", Side = "Left"})

    Health:AddToggle({
        Text = "Health Bar",
        Flag = prefix .. "healthBar",
        Default = t.healthBar,
        Callback = function(v) t.healthBar = v end
    })
    Health:AddColorPicker({
        Text = "Healthy Color",
        Flag = prefix .. "healthyColor",
        Default = (espDefault(t, "healthyColor")),
        Callback = espSetColor(t, "healthyColor")
    })
    Health:AddColorPicker({
        Text = "Dying Color",
        Flag = prefix .. "dyingColor",
        Default = (espDefault(t, "dyingColor")),
        Callback = espSetColor(t, "dyingColor")
    })
    Health:AddToggle({
        Text = "Health Bar Outline",
        Flag = prefix .. "healthBarOutline",
        Default = t.healthBarOutline,
        Callback = function(v) t.healthBarOutline = v end
    })

    Health:AddToggle({
        Text = "Health Text",
        Flag = prefix .. "healthText",
        Default = t.healthText,
        Callback = function(v) t.healthText = v end
    })
    Health:AddColorPicker({
        Text = "Text Color",
        Flag = prefix .. "healthTextColor",
        Default = (espDefault(t, "healthTextColor")),
        Transparency = select(2, espDefault(t, "healthTextColor")),
        Callback = espSetColor(t, "healthTextColor")
    })
    Health:AddToggle({
        Text = "Health Text Outline",
        Flag = prefix .. "healthTextOutline",
        Default = t.healthTextOutline,
        Callback = function(v) t.healthTextOutline = v end
    })

    end
    -- ═══ LEFT: Skeleton ════════════════════════════════════════
    local Skeleton = page:AddSection({Title = "Skeleton", Side = "Left"})

    Skeleton:AddToggle({
        Text = "Skeleton",
        Flag = prefix .. "skeleton",
        Default = false,
        Callback = function(v) adv.skeleton = v end
    })

    Skeleton:AddColorPicker({
        Text = "Skeleton Color",
        Flag = prefix .. "skeleton_color",
        Default = adv.skeletonColor,
        Callback = function(color) adv.skeletonColor = color end
    })

    -- ═══ RIGHT: Text ═══════════════════════════════════════════
    local TextSec = page:AddSection({Title = "Text", Side = "Right"})

    TextSec:AddToggle({
        Text = "Name",
        Flag = prefix .. "name",
        Default = t.name,
        Callback = function(v) t.name = v end
    })
    TextSec:AddDropdown({
        Text = "Name Type",
        Flag = prefix .. "name_type",
        Options = {"Name", "Display Name"},
        Default = "Name",
        Callback = function(v) adv.nameType = v end
    })
    TextSec:AddColorPicker({
        Text = "Name Color",
        Flag = prefix .. "nameColor",
        Default = (espDefault(t, "nameColor")),
        Transparency = select(2, espDefault(t, "nameColor")),
        Callback = espSetColor(t, "nameColor")
    })
    TextSec:AddToggle({
        Text = "Name Outline",
        Flag = prefix .. "nameOutline",
        Default = t.nameOutline,
        Callback = function(v) t.nameOutline = v end
    })

    if team=="players" then
    TextSec:AddToggle({
        Text = "Weapon",
        Flag = prefix .. "weapon",
        Default = t.weapon,
        Callback = function(v) t.weapon = v end
    })
    TextSec:AddColorPicker({
        Text = "Weapon Color",
        Flag = prefix .. "weaponColor",
        Default = (espDefault(t, "weaponColor")),
        Transparency = select(2, espDefault(t, "weaponColor")),
        Callback = espSetColor(t, "weaponColor")
    })
    TextSec:AddToggle({
        Text = "Weapon Outline",
        Flag = prefix .. "weaponOutline",
        Default = t.weaponOutline,
        Callback = function(v) t.weaponOutline = v end
    })

    end
    TextSec:AddToggle({
        Text = "Distance",
        Flag = prefix .. "distance",
        Default = t.distance,
        Callback = function(v) t.distance = v end
    })
    TextSec:AddColorPicker({
        Text = "Distance Color",
        Flag = prefix .. "distanceColor",
        Default = (espDefault(t, "distanceColor")),
        Transparency = select(2, espDefault(t, "distanceColor")),
        Callback = espSetColor(t, "distanceColor")
    })
    TextSec:AddToggle({
        Text = "Distance Outline",
        Flag = prefix .. "distanceOutline",
        Default = t.distanceOutline,
        Callback = function(v) t.distanceOutline = v end
    })

    -- ═══ RIGHT: Tracer & Arrow ═════════════════════════════════
    local Tracers = page:AddSection({Title = "Tracer & Arrow", Side = "Right"})

    Tracers:AddToggle({
        Text = "Tracer",
        Flag = prefix .. "tracer",
        Default = t.tracer,
        Callback = function(v) t.tracer = v end
    })
    Tracers:AddDropdown({
        Text = "Tracer Origin",
        Flag = prefix .. "tracer_origin",
        Options = {"Top", "Middle", "Bottom"},
        Default = t.tracerOrigin,
        Callback = function(v) t.tracerOrigin = v end
    })
    Tracers:AddColorPicker({
        Text = "Tracer Color",
        Flag = prefix .. "tracerColor",
        Default = (espDefault(t, "tracerColor")),
        Transparency = select(2, espDefault(t, "tracerColor")),
        Callback = espSetColor(t, "tracerColor")
    })
    Tracers:AddToggle({
        Text = "Tracer Outline",
        Flag = prefix .. "tracerOutline",
        Default = t.tracerOutline,
        Callback = function(v) t.tracerOutline = v end
    })

    Tracers:AddToggle({
        Text = "Off Screen Arrow",
        Flag = prefix .. "offScreenArrow",
        Default = t.offScreenArrow,
        Callback = function(v) t.offScreenArrow = v end
    })
    Tracers:AddSlider({
        Text = "Arrow Size",
        Flag = prefix .. "arrow_size",
        Min = 5, Max = 40,
        Default = t.offScreenArrowSize,
        Suffix = "px",
        Callback = function(v) t.offScreenArrowSize = v end
    })
    Tracers:AddSlider({
        Text = "Arrow Radius",
        Flag = prefix .. "arrow_radius",
        Min = 50, Max = 400,
        Default = t.offScreenArrowRadius,
        Suffix = "px",
        Callback = function(v) t.offScreenArrowRadius = v end
    })
    Tracers:AddColorPicker({
        Text = "Arrow Color",
        Flag = prefix .. "offScreenArrowColor",
        Default = (espDefault(t, "offScreenArrowColor")),
        Transparency = select(2, espDefault(t, "offScreenArrowColor")),
        Callback = espSetColor(t, "offScreenArrowColor")
    })

    -- ═══ RIGHT: Chams ══════════════════════════════
    local ChamsSec = page:AddSection({Title = "Chams", Side = "Right"})

    ChamsSec:AddToggle({
        Text = "Chams",
        Flag = prefix .. "cs2_chams",
        Default = false,
        Callback = function(v) chams.enabled = v end
    })

    ChamsSec:AddColorPicker({
        Text = "Visible",
        Flag = prefix .. "cs2_visible",
        Default = chams.visibleColor,
        Transparency = chams.visibleIntensity,
        Callback = function(color, alpha)
            chams.visibleColor = color
            if alpha ~= nil then chams.visibleIntensity = alpha end
        end
    })

    ChamsSec:AddColorPicker({
        Text = "Occluded",
        Flag = prefix .. "cs2_occluded",
        Default = chams.occludedColor,
        Transparency = chams.occludedIntensity,
        Callback = function(color, alpha)
            chams.occludedColor = color
            if alpha ~= nil then chams.occludedIntensity = alpha end
        end
    })
end

buildTeamPage(NpcPage,"npc")
local PlayerGeneral=PlayersPage:AddSection({Title="General",Side="Left"})
PlayerGeneral:AddToggle({Text="ESP Enabled",Flag="players_enabled",Default=false,
    Callback=function(v) Sense.teamSettings.players.enabled=v end})
PlayerGeneral:AddToggle({Text="Team Check",Flag="players_team_check",Default=false,
    Callback=function(v) Sense.teamSettings.players.teamCheck=v end})
buildTeamPage(PlayersPage,"players")
for _,entry in ipairs({{ZombiePage,"zombies"},{CorpsePage,"corpses"}}) do
    local page,kind=entry[1],entry[2]
    local general=page:AddSection({Title="General",Side="Left"})
    general:AddToggle({Text="ESP Enabled",Flag=kind.."_enabled",Default=false,
        Callback=function(v) Sense.teamSettings[kind].enabled=v end})

    buildTeamPage(page,kind)
end
-- Settings page ───────────────────────────────────────────────
local SharedLeft = SharedPage:AddSection({Title = "Settings", Side = "Left"})

SharedLeft:AddSlider({
    Text = "Text Size",
    Flag = "esp_text_size",
    Min = 8, Max = 24,
    Default = Sense.sharedSettings.textSize,
    Callback = function(v) Sense.sharedSettings.textSize = v end
})

-- Roblox Drawing font indices
local ESP_FONT_MAP = { ["UI"] = 0, ["System"] = 1, ["Plex"] = 2, ["Monospace"] = 3 }
SharedLeft:AddDropdown({
    Text = "Font",
    Flag = "esp_text_font",
    Options = {"UI", "System", "Plex", "Monospace"},
    Default = "Plex",
    Callback = function(v) Sense.sharedSettings.textFont = ESP_FONT_MAP[v] or 2 end
})

SharedLeft:AddToggle({
    Text = "Limit Distance",
    Flag = "esp_limit_distance",
    Default = Sense.sharedSettings.limitDistance,
    Callback = function(v) Sense.sharedSettings.limitDistance = v end
})

SharedLeft:AddSlider({
    Text = "Max Distance",
    Flag = "esp_max_distance",
    Min = 50, Max = 2000,
    Default = Sense.sharedSettings.maxDistance,
    Suffix = " studs",
    Callback = function(v) Sense.sharedSettings.maxDistance = v end
})

SharedLeft:AddToggle({Text="Team Based Color",Flag="esp_team_based_color",Default=false,
    Callback=function(v) Sense.sharedSettings.teamBasedColor=v end})
SharedLeft:AddColorPicker({Text="NPCs Without Team",Flag="esp_neutral_color",
    Default=Sense.sharedSettings.neutralColor,
    Callback=function(c) Sense.sharedSettings.neutralColor=c end})
SharedLeft:AddSlider({Text="Box Outline Thickness",Flag="npc_box_outline_thickness",Min=1,Max=5,Default=1,Suffix="px",
    Callback=function(v) Sense.teamSettings.npc.boxOutlineThickness=v;Sense.teamSettings.players.boxOutlineThickness=v end})
SharedLeft:AddLabel({Text="Team colors use replicated data; neutral color is the fallback."})
getgenv().LeanNPCESP = Sense
local originalUnload = Library.Unload
Library.Unload = function(self)
    Combat.Destroy()
    Sense.Unload()
    return originalUnload(self)
end

-- ═══════════════════════════════════════════════════════════════
-- Visuals tab → World Modulation (World / Lighting / Graphics)
-- ═══════════════════════════════════════════════════════════════
local WMLighting = game:GetService("Lighting")
local VisualsPage = MainWindow:AddTab({ Text = "World Visuals", Pages = {"World Modulation"} })

-- Show/hide an element. UIListLayout skips invisible children, and the section
-- auto-resizes off AbsoluteContentSize, so revealing works cleanly.
local function wm_elemInstance(elem)
    local it = elem and elem.Items
    if not it then return nil end
    local obj = it.Object or it.Dropdown or it.Colorpicker
    return obj and obj.Instance or nil
end
local function wm_setVisible(elem, v)
    local inst = wm_elemInstance(elem)
    if inst then inst.Visible = v end
end

-- Snapshot the game's original lighting so each toggle can restore on disable.
local WMBackup = {
    Ambient = WMLighting.Ambient, OutdoorAmbient = WMLighting.OutdoorAmbient,
    ColorShift_Top = WMLighting.ColorShift_Top, ColorShift_Bottom = WMLighting.ColorShift_Bottom,
    ClockTime = WMLighting.ClockTime,
    FogStart = WMLighting.FogStart, FogEnd = WMLighting.FogEnd, FogColor = WMLighting.FogColor,
    Brightness = WMLighting.Brightness, ExposureCompensation = WMLighting.ExposureCompensation,
    EnvironmentDiffuseScale = WMLighting.EnvironmentDiffuseScale,
    EnvironmentSpecularScale = WMLighting.EnvironmentSpecularScale,
    GlobalShadows = WMLighting.GlobalShadows, ShadowSoftness = WMLighting.ShadowSoftness,
}

local WM = {
    ambient    = { enabled = false, a = WMLighting.Ambient, b = WMLighting.OutdoorAmbient },
    colorShift = { enabled = false, top = WMLighting.ColorShift_Top, bottom = WMLighting.ColorShift_Bottom },
    time       = { enabled = false, value = WMLighting.ClockTime },
    fog        = { enabled = false, s = WMLighting.FogStart, e = WMLighting.FogEnd, color = WMLighting.FogColor },
    light      = { enabled = false, brightness = WMLighting.Brightness, exposure = WMLighting.ExposureCompensation,
                   diffuse = WMLighting.EnvironmentDiffuseScale, specular = WMLighting.EnvironmentSpecularScale },
    shadows    = { enabled = false, softness = WMLighting.ShadowSoftness, tech = "ShadowMap" },
}

-- Reapply enabled groups every frame so the game can't overwrite them.
Library:Connect(AimRunService.RenderStepped, function()
    if WM.ambient.enabled then
        WMLighting.Ambient = WM.ambient.a
        WMLighting.OutdoorAmbient = WM.ambient.b
    end
    if WM.colorShift.enabled then
        WMLighting.ColorShift_Top = WM.colorShift.top
        WMLighting.ColorShift_Bottom = WM.colorShift.bottom
    end
    if WM.time.enabled then
        WMLighting.ClockTime = WM.time.value
    end
    if WM.fog.enabled then
        WMLighting.FogStart = WM.fog.s
        WMLighting.FogEnd = WM.fog.e
        WMLighting.FogColor = WM.fog.color
    end
    if WM.light.enabled then
        WMLighting.Brightness = WM.light.brightness
        WMLighting.ExposureCompensation = WM.light.exposure
        WMLighting.EnvironmentDiffuseScale = WM.light.diffuse
        WMLighting.EnvironmentSpecularScale = WM.light.specular
    end
    if WM.shadows.enabled then
        WMLighting.GlobalShadows = true
        WMLighting.ShadowSoftness = WM.shadows.softness
    end
end)

-- ── World ─────────────────────────────────────────────────────
local WMWorld = VisualsPage:AddSection({ Title = "World", Side = "Left" })

WMWorld:AddToggle({
    Text = "Custom Ambient",
    Flag = "wm_ambient",
    Default = false,
    Callback = function(v)
        WM.ambient.enabled = v
        if not v then
            WMLighting.Ambient = WMBackup.Ambient
            WMLighting.OutdoorAmbient = WMBackup.OutdoorAmbient
        end
    end
})
WMWorld:AddColorPicker({
    Text = "Ambient",
    Flag = "wm_ambient_a",
    Default = WM.ambient.a,
    Callback = function(c) WM.ambient.a = c end
})
WMWorld:AddColorPicker({
    Text = "Outdoor Ambient",
    Flag = "wm_ambient_b",
    Default = WM.ambient.b,
    Callback = function(c) WM.ambient.b = c end
})

WMWorld:AddToggle({
    Text = "Custom Color Shift",
    Flag = "wm_colorshift",
    Default = false,
    Callback = function(v)
        WM.colorShift.enabled = v
        if not v then
            WMLighting.ColorShift_Top = WMBackup.ColorShift_Top
            WMLighting.ColorShift_Bottom = WMBackup.ColorShift_Bottom
        end
    end
})
WMWorld:AddColorPicker({
    Text = "Color Shift Top",
    Flag = "wm_colorshift_top",
    Default = WM.colorShift.top,
    Callback = function(c) WM.colorShift.top = c end
})
WMWorld:AddColorPicker({
    Text = "Color Shift Bottom",
    Flag = "wm_colorshift_bottom",
    Default = WM.colorShift.bottom,
    Callback = function(c) WM.colorShift.bottom = c end
})

local wmTimeSlider
WMWorld:AddToggle({
    Text = "Custom World Time",
    Flag = "wm_time",
    Default = false,
    Callback = function(v)
        WM.time.enabled = v
        wm_setVisible(wmTimeSlider, v)
        if not v then WMLighting.ClockTime = WMBackup.ClockTime end
    end
})
wmTimeSlider = WMWorld:AddSlider({
    Text = "World Time",
    Flag = "wm_time_value",
    Min = 0, Max = 24, Rounding = 1, Default = 14,
    Callback = function(v) WM.time.value = v end
})
wm_setVisible(wmTimeSlider, false)

local wmFogStart, wmFogEnd, wmFogColor
WMWorld:AddToggle({
    Text = "Custom Fog",
    Flag = "wm_fog",
    Default = false,
    Callback = function(v)
        WM.fog.enabled = v
        wm_setVisible(wmFogStart, v)
        wm_setVisible(wmFogEnd, v)
        wm_setVisible(wmFogColor, v)
        if not v then
            WMLighting.FogStart = WMBackup.FogStart
            WMLighting.FogEnd = WMBackup.FogEnd
            WMLighting.FogColor = WMBackup.FogColor
        end
    end
})
wmFogStart = WMWorld:AddSlider({
    Text = "Fog Start",
    Flag = "wm_fog_start",
    Min = 0, Max = 5000, Rounding = 0, Default = 0,
    Callback = function(v) WM.fog.s = v end
})
wmFogEnd = WMWorld:AddSlider({
    Text = "Fog End",
    Flag = "wm_fog_end",
    Min = 0, Max = 10000, Rounding = 0, Default = 1000,
    Callback = function(v) WM.fog.e = v end
})
wmFogColor = WMWorld:AddColorPicker({
    Text = "Fog Color",
    Flag = "wm_fog_color",
    Default = WM.fog.color,
    Callback = function(c) WM.fog.color = c end
})
wm_setVisible(wmFogStart, false)
wm_setVisible(wmFogEnd, false)
wm_setVisible(wmFogColor, false)

-- ── Lighting ──────────────────────────────────────────────────
local WMLight = VisualsPage:AddSection({ Title = "Lighting", Side = "Right" })

local wmBrightness, wmExposure, wmDiffuse, wmSpecular
WMLight:AddToggle({
    Text = "Custom Lighting",
    Flag = "wm_light",
    Default = false,
    Callback = function(v)
        WM.light.enabled = v
        wm_setVisible(wmBrightness, v)
        wm_setVisible(wmExposure, v)
        wm_setVisible(wmDiffuse, v)
        wm_setVisible(wmSpecular, v)
        if not v then
            WMLighting.Brightness = WMBackup.Brightness
            WMLighting.ExposureCompensation = WMBackup.ExposureCompensation
            WMLighting.EnvironmentDiffuseScale = WMBackup.EnvironmentDiffuseScale
            WMLighting.EnvironmentSpecularScale = WMBackup.EnvironmentSpecularScale
        end
    end
})
wmBrightness = WMLight:AddSlider({
    Text = "World Brightness",
    Flag = "wm_brightness",
    Min = 0, Max = 10, Rounding = 2, Default = WM.light.brightness,
    Callback = function(v) WM.light.brightness = v end
})
wmExposure = WMLight:AddSlider({
    Text = "Exposure Compensation",
    Flag = "wm_exposure",
    Min = -5, Max = 5, Rounding = 2, Default = WM.light.exposure,
    Callback = function(v) WM.light.exposure = v end
})
wmDiffuse = WMLight:AddSlider({
    Text = "Environment Diffuse",
    Flag = "wm_diffuse",
    Min = 0, Max = 1, Rounding = 2, Default = WM.light.diffuse,
    Callback = function(v) WM.light.diffuse = v end
})
wmSpecular = WMLight:AddSlider({
    Text = "Environment Specular",
    Flag = "wm_specular",
    Min = 0, Max = 1, Rounding = 2, Default = WM.light.specular,
    Callback = function(v) WM.light.specular = v end
})
wm_setVisible(wmBrightness, false)
wm_setVisible(wmExposure, false)
wm_setVisible(wmDiffuse, false)
wm_setVisible(wmSpecular, false)

-- ── Graphics ──────────────────────────────────────────────────
local WMGraphics = VisualsPage:AddSection({ Title = "Graphics", Side = "Right" })

local wmShadowSoftness, wmTechDropdown
WMGraphics:AddToggle({
    Text = "Global Shadows",
    Flag = "wm_shadows",
    Default = false,
    Callback = function(v)
        WM.shadows.enabled = v
        wm_setVisible(wmShadowSoftness, v)
        wm_setVisible(wmTechDropdown, v)
        if v then
            pcall(function() WMLighting.Technology = Enum.Technology[WM.shadows.tech] end)
        else
            WMLighting.GlobalShadows = WMBackup.GlobalShadows
            WMLighting.ShadowSoftness = WMBackup.ShadowSoftness
        end
    end
})
wmShadowSoftness = WMGraphics:AddSlider({
    Text = "Shadow Softness",
    Flag = "wm_shadow_softness",
    Min = 0, Max = 1, Rounding = 2, Default = WM.shadows.softness,
    Callback = function(v) WM.shadows.softness = v end
})
wmTechDropdown = WMGraphics:AddDropdown({
    Text = "Graphics Technology",
    Flag = "wm_tech",
    Options = {"ShadowMap", "Unified", "Future", "Voxel", "Compatibility"},
    Default = "ShadowMap",
    Callback = function(v)
        WM.shadows.tech = v
        if WM.shadows.enabled then
            pcall(function() WMLighting.Technology = Enum.Technology[v] end)
        end
    end
})
wm_setVisible(wmShadowSoftness, false)
wm_setVisible(wmTechDropdown, false)

-- ── Settings tab (Configs + Fonts + Theming) ──────────────────
-- Captura a tab Settings mesmo em builds antigos da lib (que não retornam
-- a tab do InitConfigs): intercepta o AddTab feito pelo InitConfigs.
local SettingsTab
do
    local captured
    local origAddTab = MainWindow.AddTab
    MainWindow.AddTab = function(self, ...)
        local results = { origAddTab(self, ...) }
        if not captured then captured = results[1] end
        return table.unpack(results)
    end
    local returned = Library:InitConfigs(MainWindow)
    MainWindow.AddTab = origAddTab
    SettingsTab = returned or captured
end

-- Última linha de defesa: tab própria.
if not SettingsTab then
    SettingsTab = MainWindow:AddTab({ Text = "UI", Pages = {"Effects"} })
end

-- ── Title/Subtitle effect engine ────────────────────────────
-- Funciona com QUALQUER versão da lib:
--   • lib nova   → usa os setters nativos (SetTitleWaveStyle etc.)
--   • lib antiga → desliga o wave interno e anima os gradients localmente
local WaveStyles = { "wave", "rainbow", "pulse", "gradient" }
local NativeFx = (type(MainWindow.WaveStyles) == "table")

local Fx = {
    Title = { A = Color3.fromRGB(245, 245, 245), B = Color3.fromRGB(140, 140, 140), Speed = 1, Style = "wave" },
    Sub   = { A = Color3.fromRGB(245, 245, 245), B = Color3.fromRGB(140, 140, 140), Speed = 1, Style = "wave" },
    Rebuild = function() end,
}

if not NativeFx then
    -- Para a animação interna da lib antiga (senão as duas brigam pelo Offset)
    pcall(function() MainWindow:SetTitleWaveEnabled(false) end)
    pcall(function() MainWindow:SetWaveEnabled(false) end)

    local function getGradient(labelItem, name)
        local inst = labelItem and labelItem.Instance
        if not inst then return nil end
        local g = inst:FindFirstChild(name)
        if not g then
            g = Instance.new("UIGradient")
            g.Name = name
            g.Parent = inst
        end
        return g
    end

    local TitleGrad = getGradient(MainWindow.Items and MainWindow.Items.TitleLabel, "TitleWaveGradient")
    local SubGrad   = getGradient(MainWindow.Items and MainWindow.Items.SubTitleLabel, "SubWaveGradient")

    local RainbowSequence do
        local kp = {}
        for i = 0, 6 do
            kp[#kp + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.75, 1))
        end
        RainbowSequence = ColorSequence.new(kp)
    end

    local function fxBuild(gradient, cfg)
        if not gradient then return end
        gradient.Rotation = 0
        gradient.Offset = Vector2.new(0, 0)
        if cfg.Style == "rainbow" then
            gradient.Color = RainbowSequence
        elseif cfg.Style == "gradient" then
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, cfg.A),
                ColorSequenceKeypoint.new(1, cfg.B),
            })
        elseif cfg.Style ~= "pulse" then -- "wave"
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, cfg.A),
                ColorSequenceKeypoint.new(0.50, cfg.B),
                ColorSequenceKeypoint.new(1.00, cfg.A),
            })
        end
    end

    Fx.Rebuild = function()
        fxBuild(TitleGrad, Fx.Title)
        fxBuild(SubGrad, Fx.Sub)
    end
    Fx.Rebuild()

    local animated = {
        { grad = TitleGrad, cfg = Fx.Title },
        { grad = SubGrad,   cfg = Fx.Sub },
    }
    Library:Connect(AimRunService.RenderStepped, function()
        local t = tick()
        for _, e in ipairs(animated) do
            local g, c = e.grad, e.cfg
            if g then
                if c.Style == "wave" or c.Style == "rainbow" then
                    g.Offset = Vector2.new((t * c.Speed % 2) - 1, 0)
                elseif c.Style == "pulse" then
                    local a = (math.sin(t * c.Speed * math.pi) + 1) / 2
                    g.Color = ColorSequence.new(c.A:Lerp(c.B, a))
                end
            end
        end
    end)
end

-- Setters unificados (nativo ou engine local)
local function fxSetStyle(which, v)
    if NativeFx then
        if which == "Title" then MainWindow:SetTitleWaveStyle(v) else MainWindow:SetWaveStyle(v) end
    else
        Fx[which].Style = v
        Fx.Rebuild()
    end
end

local function fxSetSpeed(which, v)
    if NativeFx then
        if which == "Title" then MainWindow:SetTitleWaveSpeed(v) else MainWindow:SetWaveSpeed(v) end
    else
        Fx[which].Speed = v
    end
end

local function fxSetColors(which, a, b)
    if NativeFx then
        if which == "Title" then MainWindow:SetTitleWaveColors(a, b) else MainWindow:SetWaveColors(a, b) end
    else
        if a then Fx[which].A = a end
        if b then Fx[which].B = b end
        Fx.Rebuild()
    end
end

-- ── Title/Subtitle effect settings (na tab Settings) ──────────
local TitleFxSec = SettingsTab:AddSection({
    Title = "Title Effect",
    Side = "Left"
})

TitleFxSec:AddDropdown({
    Text = "Style",
    Flag = "titleFx_style",
    Options = WaveStyles,
    Default = "wave",
    Callback = function(v) fxSetStyle("Title", v) end
})

TitleFxSec:AddSlider({
    Text = "Speed",
    Flag = "titleFx_speed",
    Min = 0.05, Max = 3, Rounding = 2,
    Default = 1,
    Callback = function(v) fxSetSpeed("Title", v) end
})

TitleFxSec:AddColorPicker({
    Text = "Color A",
    Flag = "titleFx_colorA",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color) fxSetColors("Title", color, nil) end
})

TitleFxSec:AddColorPicker({
    Text = "Color B",
    Flag = "titleFx_colorB",
    Default = Color3.fromRGB(209, 209, 209),
    Callback = function(color) fxSetColors("Title", nil, color) end
})

local SubFxSec = SettingsTab:AddSection({
    Title = "Subtitle Effect",
    Side = "Right"
})

SubFxSec:AddDropdown({
    Text = "Style",
    Flag = "subFx_style",
    Options = WaveStyles,
    Default = "wave",
    Callback = function(v) fxSetStyle("Sub", v) end
})

SubFxSec:AddSlider({
    Text = "Speed",
    Flag = "subFx_speed",
    Min = 0.05, Max = 3, Rounding = 2,
    Default = 1,
    Callback = function(v) fxSetSpeed("Sub", v) end
})

SubFxSec:AddColorPicker({
    Text = "Color A",
    Flag = "subFx_colorA",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color) fxSetColors("Sub", color, nil) end
})

SubFxSec:AddColorPicker({
    Text = "Color B",
    Flag = "subFx_colorB",
    Default = Color3.fromRGB(209, 209, 209),
    Callback = function(color) fxSetColors("Sub", nil, color) end
})

Library:Notify({
    Title = "Script Loaded!",
    Lifetime = 3
})

-- Force the menu open.
-- The "Menu bind" keypicker fires SetVisible(false) on init, starting a fade-out
-- and locking Tweening. We wait for that to settle, clear the lock, then open.
task.delay(1, function()
    pcall(function()
        MainWindow.Tweening = false
        if MainWindow.SetVisible then
            MainWindow.SetVisible(true)
        end
    end)
end)

-- Boot ESP last so any UI setup errors don't prevent the window from rendering
task.defer(function()
    if Sense._hasLoaded then return end
    local ok, err = pcall(Sense.Load)
    if not ok then warn("[NPC ESP] Load failed:", err) else print("LEAN_NPC_UI_READY") end
end)