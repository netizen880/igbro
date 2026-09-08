local RunService = game.GetService(game, "RunService")
local Players = game.GetService(game, "Players")
local WorkspaceService = game.GetService(game, "Workspace")
local CollectionService = game.GetService(game, "CollectionService")
local ReplicatedStorageService = game.GetService(game, "ReplicatedStorage")
local UserInputService = game.GetService(game, "UserInputService")
local GuiService = game.GetService(game, "GuiService")
local TweenService = game.GetService(game, "TweenService")
local VirtualInputManager = game.GetService(game, "VirtualInputManager")
local HttpService = game.GetService(game, "HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = WorkspaceService.CurrentCamera
local MouseObject = LocalPlayer.GetMouse(LocalPlayer)

FovCircle = Drawing.new("Circle")
FovCircle.Radius = 300
FovCircle.Thickness = 2
FovCircle.Filled = false
FovCircle.Color = Color3.fromRGB(255, 255, 255)
FovCircle.Transparency = 1
FovCircle.Visible = true
FovCircle.NumSides = 64

TargetLine = Drawing.new("Line")
TargetLine.Thickness = 1
TargetLine.Transparency = 1
TargetLine.Color = Color3.fromRGB(255, 255, 255)
TargetLine.Visible = false

TargetCubeEdgeColor3 = Color3.fromRGB(255, 220, 0)
TargetCubeLineThicknessNumber = 2
TargetCubeLines = {}
TargetCubeEdgePairsTable = {
	{ 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 1 },
	{ 5, 6 }, { 6, 7 }, { 7, 8 }, { 8, 5 },
	{ 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 },
}

for LineIndex = 1, #TargetCubeEdgePairsTable do
	local Line = Drawing.new("Line")
	Line.Thickness = TargetCubeLineThicknessNumber
	Line.Transparency = 1
	Line.Color = TargetCubeEdgeColor3
	Line.Visible = false
	TargetCubeLines[LineIndex] = Line
end

CurrentTargetPartInstance = nil
CurrentTargetCharacterModel = nil
CurrentTargetPlayerObject = nil
CurrentTargetPointVector3 = nil
CurrentTargetAimPointVector3 = nil
CurrentTargetLocalPointVector3 = nil
CurrentTargetCubeCFrame = nil
CurrentTargetCubeSize = nil
CurrentVisibilityOriginVector3 = nil
CurrentWeaponBallisticsProfileTable = nil
LastFallbackIndicatorPartInstance = nil
LastFallbackIndicatorCharacterModel = nil
LastFallbackIndicatorPlayerObject = nil
CurrentFrameSequenceNumber = 0
CurrentFrameLocalCharacterModel = nil
CurrentFrameLocalCharacterReadyBoolean = false

AimbotSmoothingNumber = 0.2
AimbotRequireRmbBoolean = true
NormalHookHitChanceNumber = 100
StickyAimEnabledBoolean = false

MinSmoothingNumber = 0.01
MaxSmoothingNumber = 1.0

MinFovRadiusNumber = 50
MaxFovRadiusNumber = 600
MinNormalHookHitChanceNumber = 0
MaxNormalHookHitChanceNumber = 100

MaxDistanceNumber = 5000

HeadshotPriorityBoolean = false

AutoFireEnabledBoolean = true
AutoFireCooldownNumber = 0.1
LastAutoFireTimeNumber = 0

VisibleCheckEnabledBoolean = true
VisibleCheckSubdivisionsNumber = 4
TargetSegmentationEnabledBoolean = false
SkyAimHitDistanceNumber = 4096
SkyAimSolutionCacheDurationNumber = 0.05
SkyAimCandidateLockDurationNumber = 0.3
SkyAimPreferredPitchDegreesNumber = 45
SkyAimSamplePitchDegreesTable = { 88, 76, 64, 52, 45, 40, 28, 16, 0 }
SkyAimSampleYawOffsetDegreesTable = { 0, 15, -15, 30, -30, 45, -45, 60, -60, 90, -90, 180 }
SkyAimVisibilitySamplePitchDegreesTable = { 88, 70, 52, 45, 34, 18, 0 }
SkyAimVisibilitySampleYawOffsetDegreesTable = { 0, 30, -30, 60, -60, 90, -90, 180 }

ShowFovCircleBoolean = true
ShowTargetLineBoolean = true
EspEnabledBoolean = true
EspSkeletonEnabledBoolean = true
EspHighlightEnabledBoolean = true

UseHookMethodBoolean = true
UseCameraMethodBoolean = true

RetargetMinImprovementNumber = 0
TargetSearchIntervalNumber = 0.1
LastTargetSearchTimeNumber = 0
VisibilityRaycastParams = RaycastParams.new()
VisibilityRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
LastRaycastCharacterModel = nil
CustomCharacterCacheDurationNumber = 0.2
TargetablePartsCacheDurationNumber = 0.25
SearchableCharacterEntriesCacheDurationNumber = 0.25
PlayerListMenuRefreshIntervalNumber = 1.25
CachedCharactersFolderInstance = nil
CachedCharacterFolderChildCountNumber = -1
CachedCharacterFolderScanTimeNumber = 0
CachedDirectCharacterModelsTable = {}
CachedCustomCharacterByPlayerTable = {}
ResolveCharacterModelCacheDurationNumber = 0.15
ResolveCharacterModelCacheTable = setmetatable({}, { __mode = "k" })
TargetablePartsCacheTable = {}
CachedSearchableCharacterEntriesTable = {}
CachedSearchableCharacterEntriesKeyString = nil
CachedSearchableCharacterEntriesTimeNumber = 0
FrameTargetDataCacheTable = {
	normal = {},
	ignoreFov = {},
}
FrameVisiblePointCacheTable = {}
FrameCharacterAliveCacheTable = {}
FrameCharacterVelocityCacheTable = {}
ObservedCharacterVelocitySampleByModelTable = setmetatable({}, { __mode = "k" })
JailbirdVisibilityRuntimeTable = {
	passThroughByPart = setmetatable({}, { __mode = "k" }),
	mapCacheInstance = nil,
}


local GameIntegrationProfilesByPlaceIdTable = {
	[13955927965] = {
		id = "bloodzone",
		usesCustomCharacters = true,
		usesCustomScopeCheck = true,
		usesProjectilePrediction = true,
		autoFireCooldown = 0,
		playerListRefreshInterval = 0.12,
		playerListEntryStateCacheDuration = 0.05,
		menuHeight = 696,
	},
	[14939963714] = {
		id = "jailbird",
	},
}
CurrentGameIntegrationProfileTable = GameIntegrationProfilesByPlaceIdTable[game.PlaceId]
CurrentGameIntegrationIdString = CurrentGameIntegrationProfileTable and CurrentGameIntegrationProfileTable.id or nil
IsBloodZonePlaceBoolean = (CurrentGameIntegrationIdString == "bloodzone")
IsJailbirdPlaceBoolean = (CurrentGameIntegrationIdString == "jailbird")
IsCustomCharacterGameBoolean = CurrentGameIntegrationProfileTable ~= nil
	and CurrentGameIntegrationProfileTable.usesCustomCharacters == true
UseCustomScopeCheckBoolean = CurrentGameIntegrationProfileTable ~= nil
	and CurrentGameIntegrationProfileTable.usesCustomScopeCheck == true
UseProjectilePredictionBoolean = CurrentGameIntegrationProfileTable ~= nil
	and CurrentGameIntegrationProfileTable.usesProjectilePrediction == true
CurrentGameIntegrationMenuHeightNumber = CurrentGameIntegrationProfileTable
	and CurrentGameIntegrationProfileTable.menuHeight or 618
CurrentGameIntegrationPlayerListRefreshIntervalNumber = CurrentGameIntegrationProfileTable
	and CurrentGameIntegrationProfileTable.playerListRefreshInterval or 0.55
CurrentGameIntegrationPlayerListEntryCacheDurationNumber = CurrentGameIntegrationProfileTable
	and CurrentGameIntegrationProfileTable.playerListEntryStateCacheDuration or 0.2
if CurrentGameIntegrationProfileTable
	and type(CurrentGameIntegrationProfileTable.autoFireCooldown) == "number" then
	AutoFireCooldownNumber = CurrentGameIntegrationProfileTable.autoFireCooldown
end



LockKeyModesTable = { "RMB", "E", "Always" }
LockKeyModeIndexNumber = 1
SillyModeEnabledBoolean = false
SillyModeRuntimeActiveBoolean = false
SillySkyAimEnabledBoolean = true
SillySkyVisibilityCheckEnabledBoolean = true
ShieldModeEnabledBoolean = false
NormalHookHitChanceDecisionWindowNumber = 0.02
LastNormalHookHitChanceDecisionTimeNumber = 0
LastNormalHookHitChanceDecisionBoolean = true
local PlayerListRuntimeTable: { [string]: any } = {
	whitelistByPlayer = {},
	priorityByPlayer = {},
	entryButtonsByPlayer = {},
	entryStateCache = setmetatable({}, { __mode = "k" }),
	refreshInterval = CurrentGameIntegrationPlayerListRefreshIntervalNumber,
	lastRefreshTime = 0,
	collapsed = false,
	collapsedHeight = 36,
}
EspRuntimeTable = {
	drawingsByCharacter = setmetatable({}, { __mode = "k" }),
	entryCacheTable = {},
	entryCacheKey = nil,
	entryCacheTime = 0,
	entryCacheDuration = 0.18,
	rigCacheDuration = 0.35,
	highlightHost = nil,
	defaultColor = Color3.fromRGB(120, 245, 150),
	priorityColor = Color3.fromRGB(255, 175, 90),
	whitelistColor = Color3.fromRGB(95, 215, 255),
	targetColor = Color3.fromRGB(255, 220, 90),
	infoColor = Color3.fromRGB(240, 240, 240),
	skeletonThickness = 1.2,
	highlightFillTransparency = 0.84,
	highlightOutlineTransparency = 0.08,
	highlightTargetFillTransparency = 0.72,
	highlightTargetOutlineTransparency = 0.02,
	maxSkeletonLineCount = 14,
	offscreenCullMargin = 140,
	nearDistance = 110,
	mediumDistance = 240,
	rigProfiles = {
		R15 = {
			pointDefinitions = {
				{ key = "head", names = { "Head" }, offset = Vector3.new(0, 0.15, 0) },
				{ key = "neck", names = { "UpperTorso", "Torso", "Center", "HitboxPart" }, offset = Vector3.new(0, 0.5, 0) },
				{ key = "pelvis", names = { "LowerTorso", "HumanoidRootPart", "Torso", "Center" }, offset = Vector3.new(0, -0.15, 0) },
				{ key = "leftShoulder", names = { "LeftUpperArm", "Left Arm" }, offset = Vector3.new(0, 0.45, 0) },
				{ key = "leftElbow", names = { "LeftLowerArm", "LeftUpperArm", "Left Arm" }, offset = Vector3.new(0, 0.45, 0) },
				{ key = "leftHand", names = { "LeftHand", "LeftLowerArm", "Left Arm" }, offset = Vector3.new(0, -0.35, 0) },
				{ key = "rightShoulder", names = { "RightUpperArm", "Right Arm" }, offset = Vector3.new(0, 0.45, 0) },
				{ key = "rightElbow", names = { "RightLowerArm", "RightUpperArm", "Right Arm" }, offset = Vector3.new(0, 0.45, 0) },
				{ key = "rightHand", names = { "RightHand", "RightLowerArm", "Right Arm" }, offset = Vector3.new(0, -0.35, 0) },
				{ key = "leftHip", names = { "LeftUpperLeg", "Left Leg" }, offset = Vector3.new(0, 0.45, 0) },
				{ key = "leftKnee", names = { "LeftLowerLeg", "LeftUpperLeg", "Left Leg" }, offset = Vector3.new(0, 0.45, 0) },
				{ key = "leftFoot", names = { "LeftFoot", "LeftLowerLeg", "Left Leg" }, offset = Vector3.new(0, -0.35, 0) },
				{ key = "rightHip", names = { "RightUpperLeg", "Right Leg" }, offset = Vector3.new(0, 0.45, 0) },
				{ key = "rightKnee", names = { "RightLowerLeg", "RightUpperLeg", "Right Leg" }, offset = Vector3.new(0, 0.45, 0) },
				{ key = "rightFoot", names = { "RightFoot", "RightLowerLeg", "Right Leg" }, offset = Vector3.new(0, -0.35, 0) },
			},
			connections = {
				{ "head", "neck" },
				{ "neck", "pelvis" },
				{ "neck", "leftShoulder" },
				{ "leftShoulder", "leftElbow" },
				{ "leftElbow", "leftHand" },
				{ "neck", "rightShoulder" },
				{ "rightShoulder", "rightElbow" },
				{ "rightElbow", "rightHand" },
				{ "pelvis", "leftHip" },
				{ "leftHip", "leftKnee" },
				{ "leftKnee", "leftFoot" },
				{ "pelvis", "rightHip" },
				{ "rightHip", "rightKnee" },
				{ "rightKnee", "rightFoot" },
			},
		},
		R6 = {
			pointDefinitions = {
				{ key = "head", names = { "Head" }, offset = Vector3.new(0, 0.15, 0) },
				{ key = "neck", names = { "Torso", "UpperTorso", "Center", "HitboxPart" }, offset = Vector3.new(0, 0.5, 0) },
				{ key = "pelvis", names = { "Torso", "HumanoidRootPart", "Center" }, offset = Vector3.new(0, -0.45, 0) },
				{ key = "leftShoulder", names = { "Left Arm", "LeftUpperArm" }, offset = Vector3.new(0, 0.45, 0) },
				{ key = "leftHand", names = { "Left Arm", "LeftUpperArm" }, offset = Vector3.new(0, -0.45, 0) },
				{ key = "rightShoulder", names = { "Right Arm", "RightUpperArm" }, offset = Vector3.new(0, 0.45, 0) },
				{ key = "rightHand", names = { "Right Arm", "RightUpperArm" }, offset = Vector3.new(0, -0.45, 0) },
				{ key = "leftHip", names = { "Left Leg", "LeftUpperLeg" }, offset = Vector3.new(0, 0.45, 0) },
				{ key = "leftFoot", names = { "Left Leg", "LeftUpperLeg" }, offset = Vector3.new(0, -0.45, 0) },
				{ key = "rightHip", names = { "Right Leg", "RightUpperLeg" }, offset = Vector3.new(0, 0.45, 0) },
				{ key = "rightFoot", names = { "Right Leg", "RightUpperLeg" }, offset = Vector3.new(0, -0.45, 0) },
			},
			connections = {
				{ "head", "neck" },
				{ "neck", "pelvis" },
				{ "neck", "leftShoulder" },
				{ "leftShoulder", "leftHand" },
				{ "neck", "rightShoulder" },
				{ "rightShoulder", "rightHand" },
				{ "pelvis", "leftHip" },
				{ "leftHip", "leftFoot" },
				{ "pelvis", "rightHip" },
				{ "rightHip", "rightFoot" },
			},
		},
		Fallback = {
			pointDefinitions = {
				{ key = "head", names = { "Head" }, offset = Vector3.new(0, 0.15, 0) },
				{ key = "neck", names = { "UpperTorso", "Torso", "Center", "HitboxPart", "HumanoidRootPart" }, offset = Vector3.new(0, 0.45, 0) },
				{ key = "pelvis", names = { "HumanoidRootPart", "LowerTorso", "Torso", "Center" }, offset = Vector3.new(0, -0.25, 0) },
				{ key = "leftShoulder", names = { "LeftUpperArm", "Left Arm" }, offset = Vector3.new(0, 0.45, 0) },
				{ key = "leftHand", names = { "LeftUpperArm", "Left Arm" }, offset = Vector3.new(0, -0.45, 0) },
				{ key = "rightShoulder", names = { "RightUpperArm", "Right Arm" }, offset = Vector3.new(0, 0.45, 0) },
				{ key = "rightHand", names = { "RightUpperArm", "Right Arm" }, offset = Vector3.new(0, -0.45, 0) },
				{ key = "leftHip", names = { "LeftUpperLeg", "Left Leg" }, offset = Vector3.new(0, 0.45, 0) },
				{ key = "leftFoot", names = { "LeftUpperLeg", "Left Leg" }, offset = Vector3.new(0, -0.45, 0) },
				{ key = "rightHip", names = { "RightUpperLeg", "Right Leg" }, offset = Vector3.new(0, 0.45, 0) },
				{ key = "rightFoot", names = { "RightUpperLeg", "Right Leg" }, offset = Vector3.new(0, -0.45, 0) },
			},
			connections = {
				{ "head", "neck" },
				{ "neck", "pelvis" },
				{ "neck", "leftShoulder" },
				{ "leftShoulder", "leftHand" },
				{ "neck", "rightShoulder" },
				{ "rightShoulder", "rightHand" },
				{ "pelvis", "leftHip" },
				{ "leftHip", "leftFoot" },
				{ "pelvis", "rightHip" },
				{ "rightHip", "rightFoot" },
			},
		},
	},
}
PlayerListEntryStateCacheDurationNumber = CurrentGameIntegrationPlayerListEntryCacheDurationNumber
DebugModeEnabledBoolean = false
DebugPrintIntervalNumber = 0.35
DebugLastPrintByKeyTable = {}
TraceModeEnabledBoolean = false
TracePrintIntervalNumber = 0.08
TraceLastPrintByKeyTable = {}
DebugRejectCountsTable = {}
local ShieldModeRuntimeTable: { [string]: any } = {
	nextShotTime = 0,
	pendingReequipTime = 0,
	secondaryReadyTime = 0,
	reloadHoldUntilTime = 0,
	reloadObserved = false,
	reloadDeferredForThreat = false,
	reloadSuppressionActive = false,
	savedAutoReloadSetting = nil,
	savedCancelReloadingSetting = nil,
	reloadResumeUntilTime = 0,
	lastThreatScanTime = 0,
	cachedThreatData = nil,
	cachedAimingThreatData = nil,
	cachedThreatScanCharacter = nil,
	cachedThreatScanFrameId = 0,
	threatScanInterval = 0.08,
	lastEquipAttemptTime = 0,
	equipThrottle = 0.03,
	localData = nil,
	weaponData = nil,
	localCharacterModule = nil,
	localGunModule = nil,
	weaponClientModule = nil,
	clientProjectilesModule = nil,
	cursorModule = nil,
	directionIndicatorModule = nil,
	localCharacterHooksApplied = false,
	localGunHooksApplied = false,
	cursorHooksApplied = false,
	forcedBodyRotationCFrame = nil,
	activeLocalGun = nil,
	activeFiringLocalGun = nil,
	skyAimSolutionCache = nil,
	shotSkyAimDataCache = nil,
	currentLocalGunFrameId = 0,
	currentLocalGunCharacter = nil,
	currentLocalGunTool = nil,
	currentLocalGunResolved = false,
	currentLocalGunMuzzleOriginFrameId = 0,
	currentLocalGunMuzzleOriginValue = nil,
	currentLocalGunRaycastParamsFrameId = 0,
	currentLocalGunRaycastParamsValue = nil,
	currentLocalGunCheckParamsFrameId = 0,
	currentLocalGunCheckParamsValue = nil,
	currentWeaponBallisticsProfileFrameId = 0,
	currentWeaponBallisticsProfileCharacter = nil,
	currentWeaponBallisticsProfileLocalGun = nil,
	currentWeaponBallisticsProfileValue = nil,
	heldItemStateCacheDuration = 0.2,
	GetBloodZoneHeldItemState = nil,
}
ShieldModeRuntimeTable.heldItemStateCache = setmetatable({}, { __mode = "k" })
local GetSearchableCharacterEntries
local RaycastBetweenIgnoringGlass
local IsCharacterForceFieldProtected
local GetPreferredTargetPart
local HasEquippedGun
local IsRaycastResultTargetHit
local RunUnredirectedWorkspaceRaycast


local SupportedBloodZoneWeaponTypesTable = {
	Gun = true,
	Launcher = true,
}
local ExplosiveProjectileNameSetTable = {
	Firework = true,
	GrenadeShot = true,
	LauncherGrenade = true,
	EggGrenade = true,
	Propaine = true,
	PropaneLauncher = true,
}
local LauncherBallisticsProfileByNameTable = {
	["Grenade Launcher"] = {
		projectileName = "LauncherGrenade",
		launchMode = "force_curve",
		forceDistanceClamp = 100,
		forceDistanceScale = 0.01,
		forceDistanceBias = 1.001,
		useWorkspaceGravity = true,
		simulationStep = 0.05,
		lifetime = 1.5,
		rayHit = false,
		delayedExplosion = true,
		splashAcceptanceScale = 0.6,
		splashRadius = 10.5,
	},
	["Eggsplosive Launcher"] = {
		projectileName = "EggGrenade",
		launchMode = "force_curve",
		forceDistanceClamp = 100,
		forceDistanceScale = 0.01,
		forceDistanceBias = 1.001,
		useWorkspaceGravity = true,
		simulationStep = 0.05,
		lifetime = 1.5,
		rayHit = false,
		delayedExplosion = true,
		splashAcceptanceScale = 0.6,
		splashRadius = 10.5,
	},
	["Propane Launcher"] = {
		projectileName = "PropaneLauncher",
		speed = 140,
		gravity = 36,
		lifetime = 5,
		rayHit = false,
		splashRadius = 12,
	},
}

function IsSupportedBloodZoneWeaponType(WeaponTypeString)
	return type(WeaponTypeString) == "string"
		and SupportedBloodZoneWeaponTypesTable[WeaponTypeString] == true
end

local SavePersistentStateNow = function()
	return false
end

local SchedulePersistentStateSave = function()
end

local PersistentSettingsRuntimeTable = {
	version = 1,
	folderPath = "true-aim",
	filePath = "true-aim/settings.json",
	fallbackFilePath = "true-aim-settings.json",
	activeFilePath = nil,
	gameKey = CurrentGameIntegrationIdString or ("place_" .. tostring(game.PlaceId or 0)),
	loadedState = nil,
	pendingUiState = nil,
	saveSequence = 0,
}

function ClampPersistedNumericSetting(ValueNumber, DefaultNumber, MinimumNumber, MaximumNumber)
	local ResolvedNumber = tonumber(ValueNumber)
	if type(ResolvedNumber) ~= "number" then
		ResolvedNumber = tonumber(DefaultNumber) or 0
	end
	if type(MinimumNumber) == "number" or type(MaximumNumber) == "number" then
		local MinimumClampNumber = type(MinimumNumber) == "number" and MinimumNumber or ResolvedNumber
		local MaximumClampNumber = type(MaximumNumber) == "number" and MaximumNumber or ResolvedNumber
		ResolvedNumber = math.clamp(ResolvedNumber, MinimumClampNumber, MaximumClampNumber)
	end
	return ResolvedNumber
end

function SerializePersistedPosition(PositionUdim2)
	if typeof(PositionUdim2) ~= "UDim2" then
		return nil
	end

	return {
		x = math.floor((tonumber(PositionUdim2.X.Offset) or 0) + 0.5),
		y = math.floor((tonumber(PositionUdim2.Y.Offset) or 0) + 0.5),
	}
end

function DeserializePersistedPosition(PositionTable)
	if type(PositionTable) ~= "table" then
		return nil
	end

	local XOffsetNumber = tonumber(PositionTable.x)
	local YOffsetNumber = tonumber(PositionTable.y)
	if type(XOffsetNumber) ~= "number" or type(YOffsetNumber) ~= "number" then
		return nil
	end

	return UDim2.new(
		0,
		math.floor(XOffsetNumber + 0.5),
		0,
		math.floor(YOffsetNumber + 0.5)
	)
end

function ResolvePersistentSettingsFilePathForWrite()
	local ActiveFilePathString = PersistentSettingsRuntimeTable.activeFilePath
	if type(ActiveFilePathString) == "string" and ActiveFilePathString ~= "" then
		return ActiveFilePathString
	end

	if type(makefolder) == "function" and type(isfolder) == "function" then
		local FolderReadyBoolean = false
		local FolderCheckSuccessBoolean, FolderCheckValue = pcall(isfolder, PersistentSettingsRuntimeTable.folderPath)
		FolderReadyBoolean = FolderCheckSuccessBoolean and FolderCheckValue == true
		if not FolderReadyBoolean then
			pcall(makefolder, PersistentSettingsRuntimeTable.folderPath)
		end
		FolderCheckSuccessBoolean, FolderCheckValue = pcall(isfolder, PersistentSettingsRuntimeTable.folderPath)
		FolderReadyBoolean = FolderCheckSuccessBoolean and FolderCheckValue == true
		if FolderReadyBoolean then
			PersistentSettingsRuntimeTable.activeFilePath = PersistentSettingsRuntimeTable.filePath
			return PersistentSettingsRuntimeTable.filePath
		end
	end

	PersistentSettingsRuntimeTable.activeFilePath = PersistentSettingsRuntimeTable.fallbackFilePath
	return PersistentSettingsRuntimeTable.fallbackFilePath
end

function LoadPersistentSettingsState()
	if type(readfile) ~= "function" or type(isfile) ~= "function" then
		return nil
	end

	for _, CandidateFilePathString in ipairs({
		PersistentSettingsRuntimeTable.filePath,
		PersistentSettingsRuntimeTable.fallbackFilePath,
	}) do
		local FileExistsSuccessBoolean, FileExistsBoolean = pcall(isfile, CandidateFilePathString)
		if not FileExistsSuccessBoolean or FileExistsBoolean ~= true then
			continue
		end

		local ReadSuccessBoolean, FileContentsString = pcall(readfile, CandidateFilePathString)
		if not ReadSuccessBoolean or type(FileContentsString) ~= "string" or FileContentsString == "" then
			continue
		end

		local DecodeSuccessBoolean, DecodedStateTable = pcall(HttpService.JSONDecode, HttpService, FileContentsString)
		if DecodeSuccessBoolean and type(DecodedStateTable) == "table" then
			PersistentSettingsRuntimeTable.activeFilePath = CandidateFilePathString
			return DecodedStateTable
		end
	end

	return nil
end

function ApplyLoadedPersistentScalarState(StateTable)
	if type(StateTable) ~= "table" then
		return
	end

	AimbotSmoothingNumber = ClampPersistedNumericSetting(
		StateTable.smoothing,
		AimbotSmoothingNumber,
		MinSmoothingNumber,
		MaxSmoothingNumber
	)
	FovCircle.Radius = ClampPersistedNumericSetting(
		StateTable.fovRadius,
		FovCircle.Radius,
		MinFovRadiusNumber,
		MaxFovRadiusNumber
	)
	NormalHookHitChanceNumber = ClampPersistedNumericSetting(
		StateTable.hookHitChance,
		NormalHookHitChanceNumber,
		MinNormalHookHitChanceNumber,
		MaxNormalHookHitChanceNumber
	)
	LockKeyModeIndexNumber = math.floor(ClampPersistedNumericSetting(
		StateTable.lockKeyModeIndex,
		LockKeyModeIndexNumber,
		1,
		#LockKeyModesTable
	))

	if type(StateTable.headshotPriority) == "boolean" then
		HeadshotPriorityBoolean = StateTable.headshotPriority
	end
	if type(StateTable.autoFireEnabled) == "boolean" then
		AutoFireEnabledBoolean = StateTable.autoFireEnabled
	end
	if type(StateTable.visibleCheckEnabled) == "boolean" then
		VisibleCheckEnabledBoolean = StateTable.visibleCheckEnabled
	end
	if type(StateTable.targetSegmentationEnabled) == "boolean" then
		TargetSegmentationEnabledBoolean = StateTable.targetSegmentationEnabled
	end
	if type(StateTable.showFovCircle) == "boolean" then
		ShowFovCircleBoolean = StateTable.showFovCircle
	end
	if type(StateTable.showTargetLine) == "boolean" then
		ShowTargetLineBoolean = StateTable.showTargetLine
	end
	if type(StateTable.useHookMethod) == "boolean" then
		UseHookMethodBoolean = StateTable.useHookMethod
	end
	if type(StateTable.useCameraMethod) == "boolean" then
		UseCameraMethodBoolean = StateTable.useCameraMethod
	end
	if not UseHookMethodBoolean and not UseCameraMethodBoolean then
		UseHookMethodBoolean = true
		UseCameraMethodBoolean = true
	end
	if type(StateTable.stickyAimEnabled) == "boolean" then
		StickyAimEnabledBoolean = StateTable.stickyAimEnabled
	end
	if type(StateTable.espEnabled) == "boolean" then
		EspEnabledBoolean = StateTable.espEnabled
	end
	if type(StateTable.espSkeletonEnabled) == "boolean" then
		EspSkeletonEnabledBoolean = StateTable.espSkeletonEnabled
	end
	if type(StateTable.espHighlightEnabled) == "boolean" then
		EspHighlightEnabledBoolean = StateTable.espHighlightEnabled
	end

	local UiStateTable = type(StateTable.ui) == "table" and StateTable.ui or nil
	if UiStateTable then
		if type(UiStateTable.playerListCollapsed) == "boolean" then
			PlayerListRuntimeTable.collapsed = UiStateTable.playerListCollapsed
		end
		PersistentSettingsRuntimeTable.pendingUiState = UiStateTable
	end
end

function ApplyLoadedPersistentGameState(StateTable)
	if type(StateTable) ~= "table" then
		return
	end

	if IsBloodZonePlaceBoolean then
		if type(StateTable.sillyModeEnabled) == "boolean" then
			SillyModeEnabledBoolean = StateTable.sillyModeEnabled
		end
		if type(StateTable.sillySkyAimEnabled) == "boolean" then
			SillySkyAimEnabledBoolean = StateTable.sillySkyAimEnabled
		end
		if type(StateTable.sillySkyVisibilityCheckEnabled) == "boolean" then
			SillySkyVisibilityCheckEnabledBoolean = StateTable.sillySkyVisibilityCheckEnabled
		end
		if type(StateTable.shieldModeEnabled) == "boolean" then
			ShieldModeEnabledBoolean = StateTable.shieldModeEnabled
		end
	end
end

local LoadedPersistentSettingsStateTable = LoadPersistentSettingsState()
PersistentSettingsRuntimeTable.loadedState = type(LoadedPersistentSettingsStateTable) == "table"
	and LoadedPersistentSettingsStateTable
	or nil
if type(LoadedPersistentSettingsStateTable) == "table" then
	local GlobalStateTable = type(LoadedPersistentSettingsStateTable.global) == "table"
		and LoadedPersistentSettingsStateTable.global
		or LoadedPersistentSettingsStateTable
	ApplyLoadedPersistentScalarState(GlobalStateTable)

	local GameStatesTable = type(LoadedPersistentSettingsStateTable.games) == "table"
		and LoadedPersistentSettingsStateTable.games
		or nil
	ApplyLoadedPersistentGameState(GameStatesTable and GameStatesTable[PersistentSettingsRuntimeTable.gameKey] or nil)
end



MenuGui = Instance.new("ScreenGui")
MenuGui.Name = "AimbotSettingsGui"
MenuGui.ResetOnSpawn = false
MenuGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
MenuGui.DisplayOrder = 9999
MenuGui.Parent = gethui()

UiResponsiveRuntimeTable = {
	menuWidth = 230,
	menuHeight = CurrentGameIntegrationMenuHeightNumber,
	playerListWidth = 220,
	narrowPlayerListHeight = 240,
	gap = 10,
	margin = 14,
	narrowBreakpoint = 680,
	minimumScale = 0.58,
	scale = 1,
	narrow = false,
}

MenuFrame = Instance.new("Frame")
MenuFrame.Name = "MainFrame"
MenuFrame.Size = UDim2.new(0, UiResponsiveRuntimeTable.menuWidth, 0, UiResponsiveRuntimeTable.menuHeight)
MenuFrame.Position = UDim2.new(0, 20, 0, 200)
MenuFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
MenuFrame.BackgroundTransparency = 0.04
MenuFrame.BorderSizePixel = 0
MenuFrame.ClipsDescendants = false
MenuFrame.Active = true
MenuFrame.ZIndex = 100
MenuFrame.Parent = MenuGui

MenuScaleObject = Instance.new("UIScale")
MenuScaleObject.Name = "ResponsiveScale"
MenuScaleObject.Scale = 1
MenuScaleObject.Parent = MenuFrame

MenuBackgroundGradient = Instance.new("UIGradient")
MenuBackgroundGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 31, 44)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 14, 20)),
})
MenuBackgroundGradient.Rotation = 90
MenuBackgroundGradient.Parent = MenuFrame

TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -10, 0, 24)
TitleLabel.Position = UDim2.new(0, 5, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Aimbot Settings"
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 18
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 101
TitleLabel.Parent = MenuFrame

PlayerListRuntimeTable.frame = Instance.new("Frame")
PlayerListRuntimeTable.frame.Name = "PlayerListFrame"
PlayerListRuntimeTable.frame.Size = UDim2.new(0, UiResponsiveRuntimeTable.playerListWidth, 0, UiResponsiveRuntimeTable.menuHeight)
PlayerListRuntimeTable.frame.Position = UDim2.new(
	MenuFrame.Position.X.Scale,
	MenuFrame.Position.X.Offset + MenuFrame.Size.X.Offset + 10,
	MenuFrame.Position.Y.Scale,
	MenuFrame.Position.Y.Offset
)
PlayerListRuntimeTable.frame.BackgroundColor3 = Color3.fromRGB(14, 19, 27)
PlayerListRuntimeTable.frame.BackgroundTransparency = 0.04
PlayerListRuntimeTable.frame.BorderSizePixel = 0
PlayerListRuntimeTable.frame.ClipsDescendants = true
PlayerListRuntimeTable.frame.Active = true
PlayerListRuntimeTable.frame.ZIndex = 100
PlayerListRuntimeTable.frame.Parent = MenuGui

PlayerListScaleObject = Instance.new("UIScale")
PlayerListScaleObject.Name = "ResponsiveScale"
PlayerListScaleObject.Scale = 1
PlayerListScaleObject.Parent = PlayerListRuntimeTable.frame

PlayerListBackgroundGradient = Instance.new("UIGradient")
PlayerListBackgroundGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(21, 29, 41)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 13, 19)),
})
PlayerListBackgroundGradient.Rotation = 90
PlayerListBackgroundGradient.Parent = PlayerListRuntimeTable.frame

PlayerListRuntimeTable.titleLabel = Instance.new("TextLabel")
PlayerListRuntimeTable.titleLabel.Name = "PlayerListTitleLabel"
PlayerListRuntimeTable.titleLabel.Size = UDim2.new(1, -42, 0, 24)
PlayerListRuntimeTable.titleLabel.Position = UDim2.new(0, 6, 0, 4)
PlayerListRuntimeTable.titleLabel.BackgroundTransparency = 1
PlayerListRuntimeTable.titleLabel.Text = "Players"
PlayerListRuntimeTable.titleLabel.Font = Enum.Font.SourceSansBold
PlayerListRuntimeTable.titleLabel.TextSize = 18
PlayerListRuntimeTable.titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerListRuntimeTable.titleLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerListRuntimeTable.titleLabel.ZIndex = 101
PlayerListRuntimeTable.titleLabel.Parent = PlayerListRuntimeTable.frame

PlayerListRuntimeTable.toggleButton = Instance.new("TextButton")
PlayerListRuntimeTable.toggleButton.Name = "PlayerListCollapseToggleButton"
PlayerListRuntimeTable.toggleButton.Size = UDim2.new(0, 24, 0, 22)
PlayerListRuntimeTable.toggleButton.Position = UDim2.new(1, -30, 0, 5)
PlayerListRuntimeTable.toggleButton.BackgroundColor3 = Color3.fromRGB(45, 75, 105)
PlayerListRuntimeTable.toggleButton.BorderSizePixel = 0
PlayerListRuntimeTable.toggleButton.Text = "-"
PlayerListRuntimeTable.toggleButton.Font = Enum.Font.SourceSansBold
PlayerListRuntimeTable.toggleButton.TextSize = 18
PlayerListRuntimeTable.toggleButton.TextColor3 = Color3.fromRGB(235, 245, 255)
PlayerListRuntimeTable.toggleButton.ZIndex = 102
PlayerListRuntimeTable.toggleButton.Parent = PlayerListRuntimeTable.frame

PlayerListRuntimeTable.statusLabel = Instance.new("TextLabel")
PlayerListRuntimeTable.statusLabel.Name = "PlayerListStatusLabel"
PlayerListRuntimeTable.statusLabel.Size = UDim2.new(1, -12, 0, 42)
PlayerListRuntimeTable.statusLabel.Position = UDim2.new(0, 6, 0, 28)
PlayerListRuntimeTable.statusLabel.BackgroundTransparency = 1
PlayerListRuntimeTable.statusLabel.Text = IsBloodZonePlaceBoolean
	and "LMB: priority | RMB: whitelist\nTags: TGT P W SAFE DOWN SHLD GUN"
	or "LMB: priority | RMB: whitelist\nP: priority | W: whitelist"
PlayerListRuntimeTable.statusLabel.Font = Enum.Font.SourceSans
PlayerListRuntimeTable.statusLabel.TextSize = 14
PlayerListRuntimeTable.statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
PlayerListRuntimeTable.statusLabel.TextWrapped = true
PlayerListRuntimeTable.statusLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerListRuntimeTable.statusLabel.TextYAlignment = Enum.TextYAlignment.Top
PlayerListRuntimeTable.statusLabel.ZIndex = 101
PlayerListRuntimeTable.statusLabel.Parent = PlayerListRuntimeTable.frame

PlayerListRuntimeTable.scrollFrame = Instance.new("ScrollingFrame")
PlayerListRuntimeTable.scrollFrame.Name = "PlayerListScrollFrame"
PlayerListRuntimeTable.scrollFrame.Size = UDim2.new(1, -12, 1, -78)
PlayerListRuntimeTable.scrollFrame.Position = UDim2.new(0, 6, 0, 72)
PlayerListRuntimeTable.scrollFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
PlayerListRuntimeTable.scrollFrame.BorderSizePixel = 0
PlayerListRuntimeTable.scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerListRuntimeTable.scrollFrame.ScrollBarThickness = 6
PlayerListRuntimeTable.scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
PlayerListRuntimeTable.scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
PlayerListRuntimeTable.scrollFrame.ZIndex = 101
PlayerListRuntimeTable.scrollFrame.Parent = PlayerListRuntimeTable.frame

PlayerListRuntimeTable.layout = Instance.new("UIListLayout")
PlayerListRuntimeTable.layout.Name = "PlayerListLayout"
PlayerListRuntimeTable.layout.Padding = UDim.new(0, 2)
PlayerListRuntimeTable.layout.SortOrder = Enum.SortOrder.LayoutOrder
PlayerListRuntimeTable.layout.Parent = PlayerListRuntimeTable.scrollFrame

DebugFrame = Instance.new("Frame")
DebugFrame.Name = "DebugFrame"
DebugFrame.Size = UDim2.new(0, 300, 0, 72)
DebugFrame.Position = UDim2.new(0, 260, 0, 200)
DebugFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
DebugFrame.BorderSizePixel = 0
DebugFrame.ClipsDescendants = true
DebugFrame.Visible = DebugModeEnabledBoolean
DebugFrame.ZIndex = 100
DebugFrame.Parent = MenuGui

DebugScaleObject = Instance.new("UIScale")
DebugScaleObject.Name = "ResponsiveScale"
DebugScaleObject.Scale = 1
DebugScaleObject.Parent = DebugFrame

DebugStatusLabel = Instance.new("TextLabel")
DebugStatusLabel.Name = "DebugStatusLabel"
DebugStatusLabel.Size = UDim2.new(1, -12, 1, -12)
DebugStatusLabel.Position = UDim2.new(0, 6, 0, 6)
DebugStatusLabel.BackgroundTransparency = 1
DebugStatusLabel.Text = "Debug: booting"
DebugStatusLabel.Font = Enum.Font.Code
DebugStatusLabel.TextSize = 14
DebugStatusLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
DebugStatusLabel.TextWrapped = true
DebugStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
DebugStatusLabel.TextYAlignment = Enum.TextYAlignment.Top
DebugStatusLabel.ZIndex = 101
DebugStatusLabel.Parent = DebugFrame

function ApplyAimbotUiDecoration(GuiObject, CornerRadiusNumber, StrokeColor3)
	if not GuiObject then
		return
	end
	if GuiObject.IsA(GuiObject, "TextButton") then
		GuiObject.AutoButtonColor = false
	end

	local CornerObject = GuiObject.FindFirstChild(GuiObject, "AimbotCorner")
	if not CornerObject then
		CornerObject = Instance.new("UICorner")
		CornerObject.Name = "AimbotCorner"
		CornerObject.Parent = GuiObject
	end
	CornerObject.CornerRadius = UDim.new(0, CornerRadiusNumber or 6)

	local StrokeObject = GuiObject.FindFirstChild(GuiObject, "AimbotStroke")
	if not StrokeObject then
		StrokeObject = Instance.new("UIStroke")
		StrokeObject.Name = "AimbotStroke"
		StrokeObject.Parent = GuiObject
	end
	StrokeObject.Color = StrokeColor3 or Color3.fromRGB(65, 85, 110)
	StrokeObject.Thickness = 1
	StrokeObject.Transparency = 0.35
end

function CreateAimbotSectionSurface(SurfaceNameString, YOffsetNumber, HeightNumber)
	local SurfaceFrame = Instance.new("Frame")
	SurfaceFrame.Name = SurfaceNameString
	SurfaceFrame.Size = UDim2.new(1, -16, 0, HeightNumber)
	SurfaceFrame.Position = UDim2.new(0, 8, 0, YOffsetNumber)
	SurfaceFrame.BackgroundColor3 = Color3.fromRGB(18, 25, 35)
	SurfaceFrame.BackgroundTransparency = 0.2
	SurfaceFrame.BorderSizePixel = 0
	SurfaceFrame.ClipsDescendants = true
	SurfaceFrame.ZIndex = 100
	SurfaceFrame.Parent = MenuFrame
	ApplyAimbotUiDecoration(SurfaceFrame, 6, Color3.fromRGB(45, 75, 105))

	local SurfaceStrokeObject = SurfaceFrame.FindFirstChild(SurfaceFrame, "AimbotStroke")
	if SurfaceStrokeObject then
		SurfaceStrokeObject.Transparency = 0.72
	end
	return SurfaceFrame
end

ApplyAimbotUiDecoration(MenuFrame, 8, Color3.fromRGB(55, 105, 155))
ApplyAimbotUiDecoration(PlayerListRuntimeTable.frame, 8, Color3.fromRGB(55, 105, 155))
ApplyAimbotUiDecoration(PlayerListRuntimeTable.toggleButton, 5, Color3.fromRGB(75, 110, 145))
ApplyAimbotUiDecoration(DebugFrame, 8, Color3.fromRGB(140, 110, 55))

function SafeDebugName(Value)
	if Value == nil then
		return "nil"
	end
	if typeof(Value) == "Instance" then
		return Value.Name
	end
	return tostring(Value)
end

function GetTargetIdentity(PlayerObject, CharacterModel, PartInstance)
	local PlayerNameString = "nil"
	if PlayerObject then
		PlayerNameString = PlayerObject.Name
	elseif CharacterModel then
		PlayerNameString = SafeDebugName(CharacterModel)
	end
	return PlayerNameString .. "/" .. SafeDebugName(PartInstance)
end

function UpdateDebugStatus(TextString)
	if DebugModeEnabledBoolean and DebugStatusLabel then
		DebugStatusLabel.Text = "Debug: " .. TextString
	end
end

function IsMouseOverAimbotUi(MouseLocationVector2)
	if not MouseLocationVector2 or not MenuGui or not MenuGui.Parent then
		return false
	end

	local InsetTopLeftVector2 = GuiService.GetGuiInset and GuiService.GetGuiInset(GuiService) or Vector2.new()
	local GuiMouseLocationVector2 = MouseLocationVector2 - InsetTopLeftVector2

	local function IsPointInsideGuiObject(GuiObject)
		if not GuiObject or not GuiObject.Visible then
			return false
		end

		local AbsolutePositionVector2 = GuiObject.AbsolutePosition
		local AbsoluteSizeVector2 = GuiObject.AbsoluteSize
		if AbsoluteSizeVector2.X <= 0 or AbsoluteSizeVector2.Y <= 0 then
			return false
		end

		return GuiMouseLocationVector2.X >= AbsolutePositionVector2.X
			and GuiMouseLocationVector2.X <= (AbsolutePositionVector2.X + AbsoluteSizeVector2.X)
			and GuiMouseLocationVector2.Y >= AbsolutePositionVector2.Y
			and GuiMouseLocationVector2.Y <= (AbsolutePositionVector2.Y + AbsoluteSizeVector2.Y)
	end

	for _, GuiObject in ipairs({
		MenuFrame,
		PlayerListRuntimeTable.frame,
		DebugFrame,
	}) do
		if IsPointInsideGuiObject(GuiObject) then
			return true
		end
	end

	return false
end

local UiInteractionRuntimeTable = {
	inputSuppressedUntilTime = 0,
	dragEnabled = true,
	draggingFrame = nil,
	dragStartInputPosition = nil,
	startFramePosition = nil,
	smoothSliderDragging = false,
	fovSliderDragging = false,
	hitChanceSliderDragging = false,
}

function SuppressAimbotUiInput(DurationNumber)
	local SuppressDurationNumber = math.max(DurationNumber or 0.12, 0)
	UiInteractionRuntimeTable.inputSuppressedUntilTime = math.max(UiInteractionRuntimeTable.inputSuppressedUntilTime, tick() + SuppressDurationNumber)
end

function IsAimbotUiInputSuppressed()
	return tick() < UiInteractionRuntimeTable.inputSuppressedUntilTime
end

function SendAimbotMouseClick(MouseLocationVector2)
	if not MouseLocationVector2 then
		return
	end

	SuppressAimbotUiInput(0.15)
	VirtualInputManager.SendMouseButtonEvent(VirtualInputManager, MouseLocationVector2.X, MouseLocationVector2.Y, 0, true, nil, 0)
	VirtualInputManager.SendMouseButtonEvent(VirtualInputManager, MouseLocationVector2.X, MouseLocationVector2.Y, 0, false, nil, 0)
end

function DebugLog(KeyString, TextString, ForceBoolean)
	if not DebugModeEnabledBoolean then
		return
	end

	local NowNumber = tick()
	if not ForceBoolean then
		local LastPrintNumber = DebugLastPrintByKeyTable[KeyString]
		if LastPrintNumber and (NowNumber - LastPrintNumber) < DebugPrintIntervalNumber then
			return
		end
	end

	DebugLastPrintByKeyTable[KeyString] = NowNumber
	warn("[aimbot-debug][" .. KeyString .. "] " .. TextString)
end

function TraceLog(KeyString, TextString, ForceBoolean)
	if not TraceModeEnabledBoolean then
		return
	end

	local NowNumber = tick()
	if not ForceBoolean then
		local LastPrintNumber = TraceLastPrintByKeyTable[KeyString]
		if LastPrintNumber and (NowNumber - LastPrintNumber) < TracePrintIntervalNumber then
			return
		end
	end

	TraceLastPrintByKeyTable[KeyString] = NowNumber
	warn("[aimbot-trace][" .. KeyString .. "] " .. TextString)
end

function FormatDebugVector3(Value)
	if typeof(Value) ~= "Vector3" then
		return tostring(Value)
	end

	return string.format("(%.2f, %.2f, %.2f)", Value.X, Value.Y, Value.Z)
end

function DescribeDebugInstance(Value)
	if typeof(Value) ~= "Instance" then
		return tostring(Value)
	end

	local PathPartsTable = {}
	local CurrentInstance = Value
	local DepthNumber = 0
	while CurrentInstance and DepthNumber < 6 do
		table.insert(PathPartsTable, 1, CurrentInstance.Name)
		CurrentInstance = CurrentInstance.Parent
		DepthNumber = DepthNumber + 1
	end

	return Value.ClassName .. "<" .. table.concat(PathPartsTable, "/") .. ">"
end

function SafeGetLocalGunBase(LocalGunTable)
	if type(LocalGunTable) ~= "table" or type(LocalGunTable.GetBase) ~= "function" then
		return nil, "no-getbase"
	end

	local SuccessBoolean, ResultValue = pcall(LocalGunTable.GetBase, LocalGunTable)
	if not SuccessBoolean then
		return nil, tostring(ResultValue)
	end

	return ResultValue, nil
end

UpdateDebugStatus("waiting for target search")

function ResetRejectCounts()
	DebugRejectCountsTable = {}
end

function RecordRejectReason(ReasonKey)
	DebugRejectCountsTable[ReasonKey] = (DebugRejectCountsTable[ReasonKey] or 0) + 1
end

function GetRejectCountsSummary()
	local SummaryParts = {}
	for _, ReasonKey in ipairs({
		"dead",
		"distance",
		"offscreen",
		"fov",
		"visible",
		"point_offscreen",
		"point_fov",
	}) do
		local CountNumber = DebugRejectCountsTable[ReasonKey]
		if CountNumber and CountNumber > 0 then
			table.insert(SummaryParts, ReasonKey .. "=" .. tostring(CountNumber))
		end
	end

	if #SummaryParts == 0 then
		return "none"
	end

	return table.concat(SummaryParts, " ")
end

function IsSillyModeEnabled()
	return IsBloodZonePlaceBoolean and SillyModeEnabledBoolean
end

function IsSillyModeBehaviorActive()
	return IsBloodZonePlaceBoolean and SillyModeRuntimeActiveBoolean
end

function IsEffectiveShieldModeEnabled()
	return IsSillyModeBehaviorActive() and ShieldModeEnabledBoolean
end

function GetProjectileProfileSpeedNumber(ProfileTable)
	if type(ProfileTable) ~= "table" then
		return nil
	end

	return tonumber(ProfileTable.speed)
end

function ShouldUseForceCurveProjectileProfile(ProfileTable)
	return type(ProfileTable) == "table" and ProfileTable.launchMode == "force_curve"
end

function GetProjectileProfileGravityNumber(ProfileTable)
	if type(ProfileTable) ~= "table" then
		return 0
	end

	if ProfileTable.useWorkspaceGravity == true then
		return tonumber(WorkspaceService and WorkspaceService.Gravity) or 196.2
	end

	return tonumber(ProfileTable.gravity) or 0
end

function GetProjectileProfileGravityMagnitudeNumber(ProfileTable)
	return math.abs(GetProjectileProfileGravityNumber(ProfileTable))
end

function GetProjectileSplashRadiusNumber(ProfileTable)
	if type(ProfileTable) ~= "table" then
		return nil
	end

	local ExplicitRadiusNumber = tonumber(ProfileTable.splashRadius)
	if type(ExplicitRadiusNumber) == "number" and ExplicitRadiusNumber > 0 then
		return ExplicitRadiusNumber
	end

	local WeaponSettingsTable = ProfileTable.settings
	local DamageNumber = tonumber(WeaponSettingsTable and WeaponSettingsTable.Damage)
	if type(DamageNumber) == "number" and DamageNumber > 0 then
		local EstimatedRadiusNumber = math.clamp(DamageNumber * 0.16, 6, 14)
		if ProfileTable.isLauncher then
			EstimatedRadiusNumber = math.max(EstimatedRadiusNumber, 10)
		end
		return EstimatedRadiusNumber
	end

	return nil
end

function IsExplosiveProjectileProfile(ProfileTable)
	if type(ProfileTable) ~= "table" or ProfileTable.isProjectile ~= true then
		return false
	end

	if ProfileTable.explodes == true or ProfileTable.isLauncher == true then
		return true
	end

	local ProjectileNameString = ProfileTable.projectileName
	if type(ProjectileNameString) == "string"
		and ExplosiveProjectileNameSetTable[ProjectileNameString] == true then
		return true
	end

	local LaunchAssetInstance = ProfileTable.launchAsset
	local LaunchAssetNameString = LaunchAssetInstance and LaunchAssetInstance.Name or nil
	return type(LaunchAssetNameString) == "string"
		and ExplosiveProjectileNameSetTable[LaunchAssetNameString] == true
end

function ShouldUseProjectileArcVisibilityProfile(ProfileTable)
	return ShieldModeRuntimeTable.CanPredictProjectileWeaponProfile(ProfileTable)
		and IsExplosiveProjectileProfile(ProfileTable)
end

function ShouldPreferHighArcProjectileProfile(ProfileTable)
	if ShouldUseForceCurveProjectileProfile(ProfileTable) then
		return false
	end

	return ShouldUseProjectileArcVisibilityProfile(ProfileTable)
		and GetProjectileProfileGravityMagnitudeNumber(ProfileTable) > 0.001
end

function IsWideProjectileCastProfile(ProfileTable)
	return type(ProfileTable) == "table"
		and type(ProfileTable.castType) == "number"
		and ProfileTable.castType ~= 0
end

function IsPrecisionProjectileHeadAimProfile(ProfileTable)
	if type(ProfileTable) ~= "table" or ProfileTable.isProjectile ~= true then
		return false
	end

	if ProfileTable.rayHit ~= true or IsWideProjectileCastProfile(ProfileTable) then
		return false
	end

	local SpeedNumber = GetProjectileProfileSpeedNumber(ProfileTable) or 0
	local GravityMagnitudeNumber = GetProjectileProfileGravityMagnitudeNumber(ProfileTable)
	return SpeedNumber >= 450 and GravityMagnitudeNumber <= 60
end

function ShouldPreferProjectileBodyAimForProfile(ProfileTable)
	if type(ProfileTable) ~= "table" or ProfileTable.isProjectile ~= true then
		return false
	end

	local SpeedNumber = GetProjectileProfileSpeedNumber(ProfileTable) or math.huge
	local GravityMagnitudeNumber = GetProjectileProfileGravityMagnitudeNumber(ProfileTable)
	if IsPrecisionProjectileHeadAimProfile(ProfileTable) then
		return false
	end
	if ProfileTable.rayHit == false then
		return true
	end
	if IsWideProjectileCastProfile(ProfileTable) then
		return true
	end
	if GravityMagnitudeNumber >= 25 and SpeedNumber <= 550 then
		return true
	end
	if GravityMagnitudeNumber >= 15 and SpeedNumber <= 260 then
		return true
	end

	return false
end

function ShouldPreferProjectileFeetImpactForProfile(ProfileTable)
	if not ShouldPreferProjectileBodyAimForProfile(ProfileTable) then
		return false
	end

	return ProfileTable.rayHit == false or IsWideProjectileCastProfile(ProfileTable)
end

function IsEffectiveHeadshotPriorityEnabled()
	if ShouldPreferProjectileBodyAimForProfile(CurrentWeaponBallisticsProfileTable) then
		return false
	end

	return IsSillyModeBehaviorActive() or HeadshotPriorityBoolean
end

function IsEffectiveAutoFireEnabled()
	return IsSillyModeBehaviorActive() or AutoFireEnabledBoolean
end

function IsEffectiveVisibleCheckEnabled()
	return IsSillyModeBehaviorActive() or VisibleCheckEnabledBoolean
end

function IsEffectiveTargetSegmentationEnabled()
	if IsSillyModeBehaviorActive() then
		return false
	end
	return TargetSegmentationEnabledBoolean
end

function IsEffectiveHookMethodEnabled()
	return IsSillyModeBehaviorActive() or UseHookMethodBoolean
end

function IsEffectiveCameraMethodEnabled()
	if IsSillyModeBehaviorActive() then
		return false
	end
	return UseCameraMethodBoolean
end

function IsLegitModeBehaviorActive()
	return not IsSillyModeBehaviorActive()
end

function IsStickyAimActive()
	return IsLegitModeBehaviorActive() and StickyAimEnabledBoolean
end

function ResetNormalHookHitChanceDecision()
	LastNormalHookHitChanceDecisionTimeNumber = 0
	LastNormalHookHitChanceDecisionBoolean = true
end

function ShouldApplyNormalHookHitChance()
	if not IsLegitModeBehaviorActive() or not UseHookMethodBoolean then
		return true
	end

	local HitChanceNumber = math.clamp(tonumber(NormalHookHitChanceNumber) or 100, 0, 100)
	if HitChanceNumber >= 100 then
		return true
	end
	if HitChanceNumber <= 0 then
		return false
	end

	local NowNumber = tick()
	if (NowNumber - LastNormalHookHitChanceDecisionTimeNumber) <= NormalHookHitChanceDecisionWindowNumber then
		return LastNormalHookHitChanceDecisionBoolean
	end

	LastNormalHookHitChanceDecisionTimeNumber = NowNumber
	LastNormalHookHitChanceDecisionBoolean = math.random(0, 1000000) <= (HitChanceNumber * 10000)
	return LastNormalHookHitChanceDecisionBoolean
end

function ShouldIgnoreFovChecks(IgnoreFovBoolean)
	return IgnoreFovBoolean or IsSillyModeBehaviorActive()
end

function ShouldIgnoreOffscreenChecks()
	return IsSillyModeBehaviorActive()
end

function GetTargetSortDistance(TargetData)
	if not TargetData then
		return math.huge
	end
	return TargetData.sortDistance or TargetData.screenDistance or math.huge
end

function GetCharacterHumanoid(CharacterModel)
	if not CharacterModel then
		return nil
	end

	local Humanoid = CharacterModel.FindFirstChild(CharacterModel, "Humanoid")
	if Humanoid and Humanoid.ClassName == "Humanoid" then
		return Humanoid
	end

	local HumanoidByClass = CharacterModel.FindFirstChildWhichIsA and CharacterModel.FindFirstChildWhichIsA(CharacterModel, "Humanoid") or nil
	if HumanoidByClass and HumanoidByClass.Parent == CharacterModel then
		return HumanoidByClass
	end

	return nil
end

function IsHumanoidCharacterModel(CharacterModel)
	return GetCharacterHumanoid(CharacterModel) ~= nil
end

function GetCharactersFolder()
	local CharactersFolder = WorkspaceService.Characters
	if not CharactersFolder then
		CharactersFolder = WorkspaceService.FindFirstChild(WorkspaceService, "Characters")
	end
	if CharactersFolder and (CharactersFolder.ClassName == "Model" or CharactersFolder.ClassName == "Folder") then
		return CharactersFolder
	end
	return nil
end

function GetCharacterRootPart(CharacterModel)
	if not CharacterModel then
		return nil
	end

	local RootPartInstance = CharacterModel.FindFirstChild(CharacterModel, "HumanoidRootPart")
	if RootPartInstance and RootPartInstance.IsA(RootPartInstance, "BasePart") then
		return RootPartInstance
	end

	return nil
end

function GetCharacterHeadPart(CharacterModel)
	if not CharacterModel then
		return nil
	end

	local HeadPartInstance = CharacterModel.FindFirstChild(CharacterModel, "Head")
	if HeadPartInstance and HeadPartInstance.IsA(HeadPartInstance, "BasePart") then
		return HeadPartInstance
	end

	return nil
end

PreferredTorsoPartNamesInOrderTable = {
	"UpperTorso",
	"Torso",
	"LowerTorso",
	"Center",
	"HitboxPart",
}

function GetCharacterTorsoLikePart(CharacterModel)
	if not CharacterModel then
		return nil
	end

	for _, PreferredPartNameString in ipairs(PreferredTorsoPartNamesInOrderTable) do
		local PartInstance = CharacterModel.FindFirstChild(CharacterModel, PreferredPartNameString)
		if PartInstance and PartInstance.IsA(PartInstance, "BasePart") then
			return PartInstance
		end
	end

	return nil
end

function SafeGetBasePartAssemblyLinearVelocity(PartInstance)
	if not PartInstance
		or not PartInstance.Parent
		or not PartInstance.IsA
		or not PartInstance.IsA(PartInstance, "BasePart") then
		return nil
	end

	local SuccessBoolean, VelocityVector3 = pcall(function()
		return PartInstance.AssemblyLinearVelocity
	end)
	if SuccessBoolean and typeof(VelocityVector3) == "Vector3" then
		return VelocityVector3
	end

	return nil
end

function GetCharacterVelocitySamplePart(CharacterModel, PreferredPartInstance)
	local RootPartInstance = GetCharacterRootPart(CharacterModel)
	if RootPartInstance and RootPartInstance.Parent then
		return RootPartInstance
	end

	if PreferredPartInstance
		and PreferredPartInstance.Parent
		and PreferredPartInstance.IsA
		and PreferredPartInstance.IsA(PreferredPartInstance, "BasePart") then
		return PreferredPartInstance
	end

	return GetCharacterTorsoLikePart(CharacterModel)
		or GetCharacterHeadPart(CharacterModel)
		or nil
end

function EstimateCharacterObservedVelocityVector3(CharacterModel, PreferredPartInstance)
	if not CharacterModel or not CharacterModel.Parent then
		return nil
	end

	local SamplePartInstance = GetCharacterVelocitySamplePart(CharacterModel, PreferredPartInstance)
	if not SamplePartInstance then
		return nil
	end

	local CurrentPositionVector3 = SamplePartInstance.Position
	local CurrentTimeNumber = tick()
	local PreviousSampleTable = ObservedCharacterVelocitySampleByModelTable[CharacterModel]
	local PreviousVelocityVector3 = PreviousSampleTable and PreviousSampleTable.velocity or nil
	local ObservedVelocityVector3 = nil

	if PreviousSampleTable
		and typeof(PreviousSampleTable.position) == "Vector3"
		and type(PreviousSampleTable.time) == "number" then
		local DeltaTimeNumber = CurrentTimeNumber - PreviousSampleTable.time
		local PositionDeltaVector3 = CurrentPositionVector3 - PreviousSampleTable.position
		if DeltaTimeNumber >= (1 / 240)
			and DeltaTimeNumber <= 0.35
			and PositionDeltaVector3.Magnitude <= 64 then
			ObservedVelocityVector3 = PositionDeltaVector3 / DeltaTimeNumber
			if typeof(PreviousVelocityVector3) == "Vector3" then
				local BlendAlphaNumber = math.clamp(DeltaTimeNumber * 8, 0.18, 0.55)
				ObservedVelocityVector3 = PreviousVelocityVector3:Lerp(ObservedVelocityVector3, BlendAlphaNumber)
			end
		end
	end

	local StoredVelocityVector3 = ObservedVelocityVector3
		or (typeof(PreviousVelocityVector3) == "Vector3" and PreviousVelocityVector3 or nil)
	if typeof(StoredVelocityVector3) == "Vector3" and StoredVelocityVector3.Magnitude > 120 then
		StoredVelocityVector3 = StoredVelocityVector3.Unit * 120
	end

	ObservedCharacterVelocitySampleByModelTable[CharacterModel] = {
		position = CurrentPositionVector3,
		time = CurrentTimeNumber,
		velocity = StoredVelocityVector3,
	}

	return StoredVelocityVector3
end

function GetCharacterVelocityVector3(CharacterModel, PreferredPartInstance)
	if not CharacterModel then
		return Vector3.zero
	end

	local CachedVelocityVector3 = FrameCharacterVelocityCacheTable[CharacterModel]
	if typeof(CachedVelocityVector3) == "Vector3" then
		return CachedVelocityVector3
	end

	local AssemblyVelocityVector3 = SafeGetBasePartAssemblyLinearVelocity(GetCharacterRootPart(CharacterModel))
	if typeof(AssemblyVelocityVector3) ~= "Vector3" then
		AssemblyVelocityVector3 = SafeGetBasePartAssemblyLinearVelocity(PreferredPartInstance)
	end

	local ObservedVelocityVector3 = EstimateCharacterObservedVelocityVector3(CharacterModel, PreferredPartInstance)
	local VelocityVector3 = nil
	if typeof(AssemblyVelocityVector3) == "Vector3" and typeof(ObservedVelocityVector3) == "Vector3" then
		local HorizontalAssemblyVelocityVector3 = Vector3.new(AssemblyVelocityVector3.X, 0, AssemblyVelocityVector3.Z)
		local HorizontalObservedVelocityVector3 = Vector3.new(ObservedVelocityVector3.X, 0, ObservedVelocityVector3.Z)
		local HorizontalVelocityVector3
		if HorizontalObservedVelocityVector3.Magnitude <= 0.1 then
			HorizontalVelocityVector3 = HorizontalAssemblyVelocityVector3
		elseif HorizontalAssemblyVelocityVector3.Magnitude <= 0.1 then
			HorizontalVelocityVector3 = HorizontalObservedVelocityVector3
		else
			HorizontalVelocityVector3 = HorizontalAssemblyVelocityVector3:Lerp(HorizontalObservedVelocityVector3, 0.75)
		end

		local VerticalVelocityNumber = math.abs(AssemblyVelocityVector3.Y) >= 2
			and AssemblyVelocityVector3.Y
			or ObservedVelocityVector3.Y
		VelocityVector3 = Vector3.new(
			HorizontalVelocityVector3.X,
			VerticalVelocityNumber,
			HorizontalVelocityVector3.Z
		)
	elseif typeof(ObservedVelocityVector3) == "Vector3" then
		VelocityVector3 = ObservedVelocityVector3
	elseif typeof(AssemblyVelocityVector3) == "Vector3" then
		VelocityVector3 = AssemblyVelocityVector3
	end

	if typeof(VelocityVector3) ~= "Vector3" then
		VelocityVector3 = Vector3.zero
	end

	FrameCharacterVelocityCacheTable[CharacterModel] = VelocityVector3
	return VelocityVector3
end

function GetCharacterIdentityString(CharacterModel)
	if not CharacterModel then
		return nil
	end

	local CharacterNameString = CharacterModel.Name
	if CharacterNameString and CharacterNameString ~= "" then
		return CharacterNameString
	end

	local Humanoid = GetCharacterHumanoid(CharacterModel)
	local HumanoidDisplayNameString = Humanoid and Humanoid.DisplayName or nil
	if HumanoidDisplayNameString and HumanoidDisplayNameString ~= "" then
		return HumanoidDisplayNameString
	end

	return nil
end

function GetCharacterModelDebugName(CharacterModel)
	local CharacterIdentityString = GetCharacterIdentityString(CharacterModel)
	if CharacterIdentityString then
		return CharacterIdentityString
	end

	return SafeDebugName(CharacterModel)
end

function RefreshCustomCharacterCaches()
	local CharactersFolder = GetCharactersFolder()
	if not CharactersFolder then
		CachedCharactersFolderInstance = nil
		CachedCharacterFolderChildCountNumber = -1
		CachedCharacterFolderScanTimeNumber = tick()
		CachedDirectCharacterModelsTable = {}
		CachedCustomCharacterByPlayerTable = {}
		return
	end

	local DirectCharacterModelsTable = {}
	local CustomCharacterByPlayerTable = {}
	for _, ChildInstance in ipairs(CharactersFolder.GetChildren(CharactersFolder)) do
		if ChildInstance.ClassName == "Model"
			and GetCharacterHumanoid(ChildInstance)
			and GetCharacterRootPart(ChildInstance) then
			table.insert(DirectCharacterModelsTable, ChildInstance)
			local MatchingPlayerObject = Players.GetPlayerFromCharacter(Players, ChildInstance)
			if MatchingPlayerObject then
				CustomCharacterByPlayerTable[MatchingPlayerObject] = ChildInstance
			end
		end
	end

	CachedCharactersFolderInstance = CharactersFolder
	CachedCharacterFolderChildCountNumber = #CharactersFolder.GetChildren(CharactersFolder)
	CachedCharacterFolderScanTimeNumber = tick()
	CachedDirectCharacterModelsTable = DirectCharacterModelsTable
	CachedCustomCharacterByPlayerTable = CustomCharacterByPlayerTable
end

function EnsureCustomCharacterCaches()
	if not IsCustomCharacterGameBoolean then
		return
	end

	local CharactersFolder = GetCharactersFolder()
	local NowNumber = tick()
	if not CharactersFolder then
		if CachedCharactersFolderInstance ~= nil then
			RefreshCustomCharacterCaches()
		end
		return
	end

	local ChildCountNumber = #CharactersFolder.GetChildren(CharactersFolder)
	if CachedCharactersFolderInstance ~= CharactersFolder
		or CachedCharacterFolderChildCountNumber ~= ChildCountNumber
		or (NowNumber - CachedCharacterFolderScanTimeNumber) >= CustomCharacterCacheDurationNumber then
		RefreshCustomCharacterCaches()
	end
end

function GetDirectCharacterModelsFromCharactersFolder()
	EnsureCustomCharacterCaches()
	return CachedDirectCharacterModelsTable
end

function GetCharacterModelsFromCharactersFolder()
	return GetDirectCharacterModelsFromCharactersFolder()
end

function FindCustomCharacterForPlayer(PlayerObject)
	if not PlayerObject then
		return nil
	end

	EnsureCustomCharacterCaches()
	local CachedCharacterModel = CachedCustomCharacterByPlayerTable[PlayerObject]
	if CachedCharacterModel and CachedCharacterModel.Parent then
		return CachedCharacterModel
	end

	if not IsCustomCharacterGameBoolean then
		return nil
	end

	local PlayerNameLowerString = string.lower(PlayerObject.Name or "")
	local DisplayNameLowerString = string.lower(PlayerObject.DisplayName or "")
	for _, CharacterModel in ipairs(CachedDirectCharacterModelsTable) do
		local CharacterNameLowerString = string.lower(CharacterModel.Name or "")
		if CharacterNameLowerString == PlayerNameLowerString
			or (DisplayNameLowerString ~= "" and CharacterNameLowerString == DisplayNameLowerString) then
			CachedCustomCharacterByPlayerTable[PlayerObject] = CharacterModel
			return CharacterModel
		end

		local CharacterIdentityLowerString = string.lower(GetCharacterIdentityString(CharacterModel) or "")
		if CharacterIdentityLowerString == PlayerNameLowerString
			or (DisplayNameLowerString ~= "" and CharacterIdentityLowerString == DisplayNameLowerString) then
			CachedCustomCharacterByPlayerTable[PlayerObject] = CharacterModel
			return CharacterModel
		end

		local AboveGuiInstance = CharacterModel.FindFirstChild and CharacterModel.FindFirstChild(CharacterModel, "ABOVE", true) or nil
		local UsernameLabelInstance = AboveGuiInstance and AboveGuiInstance.FindFirstChild and AboveGuiInstance.FindFirstChild(AboveGuiInstance, "Username", true) or nil
		local UsernameTextLowerString = string.lower(UsernameLabelInstance and UsernameLabelInstance.Text or "")
		if UsernameTextLowerString == PlayerNameLowerString
			or (DisplayNameLowerString ~= "" and UsernameTextLowerString == DisplayNameLowerString) then
			CachedCustomCharacterByPlayerTable[PlayerObject] = CharacterModel
			return CharacterModel
		end
	end

	return nil
end

function ResolveCharacterModelForPlayer(PlayerObject)
	if not PlayerObject then
		return nil
	end

	local NowNumber = tick()
	local CachedEntryTable = ResolveCharacterModelCacheTable[PlayerObject]
	if CachedEntryTable and (NowNumber - (CachedEntryTable.time or 0)) < ResolveCharacterModelCacheDurationNumber then
		local CachedCharacterModel = CachedEntryTable.character
		if not CachedCharacterModel or CachedCharacterModel.Parent then
			return CachedCharacterModel
		end
	end

	local ResolvedCharacterModel = nil
	if IsCustomCharacterGameBoolean then
		local CustomCharacterModel = FindCustomCharacterForPlayer(PlayerObject)
		if CustomCharacterModel then
			ResolvedCharacterModel = CustomCharacterModel
		end
	end

	if not ResolvedCharacterModel then
		local PlayerCharacter = PlayerObject.Character
		if IsHumanoidCharacterModel(PlayerCharacter) then
			ResolvedCharacterModel = PlayerCharacter
		end
	end

	if not ResolvedCharacterModel then
		local CustomCharacterModel = FindCustomCharacterForPlayer(PlayerObject)
		if CustomCharacterModel then
			ResolvedCharacterModel = CustomCharacterModel
		end
	end

	ResolveCharacterModelCacheTable[PlayerObject] = {
		time = NowNumber,
		character = ResolvedCharacterModel,
	}
	return ResolvedCharacterModel
end

function InvalidateSearchableCharacterEntriesCache()
	CachedSearchableCharacterEntriesTable = {}
	CachedSearchableCharacterEntriesKeyString = nil
	CachedSearchableCharacterEntriesTimeNumber = 0
	EspRuntimeTable.entryCacheTable = {}
	EspRuntimeTable.entryCacheKey = nil
	EspRuntimeTable.entryCacheTime = 0
end

function PlayerListRuntimeTable.IsPlayerWhitelisted(PlayerObject)
	return PlayerObject ~= nil and PlayerListRuntimeTable.whitelistByPlayer[PlayerObject] == true
end

function PlayerListRuntimeTable.IsPriorityPlayer(PlayerObject)
	return PlayerObject ~= nil and PlayerListRuntimeTable.priorityByPlayer[PlayerObject] == true
end

function PlayerListRuntimeTable.IsCurrentTargetPlayer(PlayerObject)
	if not PlayerObject or not CurrentTargetPartInstance then
		return false
	end

	if CurrentTargetPlayerObject ~= nil and CurrentTargetPlayerObject == PlayerObject then
		return true
	end

	local CharacterModel = ResolveCharacterModelForPlayer(PlayerObject)
	return CharacterModel ~= nil and CurrentTargetCharacterModel == CharacterModel
end

function PlayerListRuntimeTable.ClearTrackedTargetForPlayer(PlayerObject)
	if not PlayerObject then
		return
	end

	if CurrentTargetPlayerObject == PlayerObject then
		CurrentTargetPartInstance = nil
		CurrentTargetCharacterModel = nil
		CurrentTargetPlayerObject = nil
		CurrentTargetPointVector3 = nil
		CurrentTargetAimPointVector3 = nil
		CurrentTargetLocalPointVector3 = nil
		CurrentTargetCubeCFrame = nil
		CurrentTargetCubeSize = nil
	end

	if LastFallbackIndicatorPlayerObject == PlayerObject then
		LastFallbackIndicatorPartInstance = nil
		LastFallbackIndicatorCharacterModel = nil
		LastFallbackIndicatorPlayerObject = nil
	end
end

function PlayerListRuntimeTable.CleanupTargetPreferences()
	for PlayerObject, _ in pairs(PlayerListRuntimeTable.whitelistByPlayer) do
		if typeof(PlayerObject) ~= "Instance" or PlayerObject.Parent ~= Players then
			PlayerListRuntimeTable.whitelistByPlayer[PlayerObject] = nil
		end
	end

	for PlayerObject, _ in pairs(PlayerListRuntimeTable.priorityByPlayer) do
		if typeof(PlayerObject) ~= "Instance" or PlayerObject.Parent ~= Players then
			PlayerListRuntimeTable.priorityByPlayer[PlayerObject] = nil
		end
	end
end

function PlayerListRuntimeTable.GetDisplayName(PlayerObject)
	if not PlayerObject then
		return "Unknown"
	end

	local DisplayNameString = PlayerObject.DisplayName
	if type(DisplayNameString) == "string" and DisplayNameString ~= "" and DisplayNameString ~= PlayerObject.Name then
		return DisplayNameString .. " (@" .. PlayerObject.Name .. ")"
	end

	return PlayerObject.Name
end

function PlayerListRuntimeTable.GetEntryState(PlayerObject, CharacterModel, IsCurrentTargetBoolean)
	local NowNumber = tick()
	local StateTags = {}
	local BackgroundColor3 = Color3.fromRGB(42, 42, 42)
	local TextColor3 = Color3.fromRGB(255, 255, 255)
	local PriorityBoolean = PlayerListRuntimeTable.IsPriorityPlayer(PlayerObject)
	local WhitelistedBoolean = PlayerListRuntimeTable.IsPlayerWhitelisted(PlayerObject)
	local CachedEntryTable = PlayerListRuntimeTable.entryStateCache and PlayerListRuntimeTable.entryStateCache[PlayerObject] or nil
	if CachedEntryTable
		and CachedEntryTable.character == CharacterModel
		and CachedEntryTable.isCurrentTarget == IsCurrentTargetBoolean
		and CachedEntryTable.isPriority == PriorityBoolean
		and CachedEntryTable.isWhitelist == WhitelistedBoolean
		and (NowNumber - (CachedEntryTable.time or 0)) < PlayerListEntryStateCacheDurationNumber then
		return CachedEntryTable.state
	end
	if IsBloodZonePlaceBoolean then
		CharacterModel = CharacterModel or ResolveCharacterModelForPlayer(PlayerObject)
	else
		CharacterModel = nil
	end
	if IsCurrentTargetBoolean == nil then
		IsCurrentTargetBoolean = PlayerListRuntimeTable.IsCurrentTargetPlayer(PlayerObject)
	end
	local Humanoid = nil
	local RootPartInstance = nil
	local SafeBoolean = false
	local CarriedBoolean = false
	local EscapedBoolean = false
	local DownedBoolean = false
	local DeadBodyBoolean = false
	local DeadBoolean = false
	local HasShieldBoolean = false
	local ArmedBoolean = false

	if IsBloodZonePlaceBoolean then
		Humanoid = CharacterModel and GetCharacterHumanoid(CharacterModel) or nil
		RootPartInstance = CharacterModel and GetCharacterRootPart(CharacterModel) or nil
		SafeBoolean = CharacterModel and IsCharacterForceFieldProtected ~= nil and IsCharacterForceFieldProtected(CharacterModel, Humanoid) or false
		CarriedBoolean = CharacterModel and CharacterModel.GetAttribute(CharacterModel, "Carried") == true or false
		EscapedBoolean = CharacterModel and CharacterModel.GetAttribute(CharacterModel, "Escaped") == true or false
		DownedBoolean = CharacterModel and (CharacterModel.GetAttribute(CharacterModel, "Downed") == true or CharacterModel.GetAttribute(CharacterModel, "IsRagdolled") == true) or false
		DeadBodyBoolean = CharacterModel and CollectionService.HasTag(CollectionService, CharacterModel, "DeadBody") or false

		local HeldItemStateTable = CharacterModel and ShieldModeRuntimeTable.GetBloodZoneHeldItemState and ShieldModeRuntimeTable.GetBloodZoneHeldItemState(CharacterModel) or nil
		HasShieldBoolean = HeldItemStateTable and HeldItemStateTable.hasShield or (CharacterModel and GetBloodZoneMetalShieldTool ~= nil and GetBloodZoneMetalShieldTool(CharacterModel) ~= nil) or false
		ArmedBoolean = HeldItemStateTable and HeldItemStateTable.hasGun or (CharacterModel and HasEquippedGun ~= nil and HasEquippedGun(CharacterModel)) or false

		if CharacterModel and Humanoid and RootPartInstance then
			local HealthNumber = Humanoid.Health
			DeadBoolean = DeadBodyBoolean
				or (Humanoid.GetAttribute and Humanoid.GetAttribute(Humanoid, "Dead") == true)
				or (type(HealthNumber) == "number" and HealthNumber <= 0)
		end
	end

	if IsBloodZonePlaceBoolean and IsCurrentTargetBoolean then
		table.insert(StateTags, "TGT")
	end
	if PriorityBoolean then
		table.insert(StateTags, "P")
	end
	if WhitelistedBoolean then
		table.insert(StateTags, "W")
	end

	if IsBloodZonePlaceBoolean then
		if not CharacterModel or not CharacterModel.Parent then
			table.insert(StateTags, "NOCHAR")
		else
			if SafeBoolean then
				table.insert(StateTags, "SAFE")
			end
			if CarriedBoolean then
				table.insert(StateTags, "CARRY")
			end
			if EscapedBoolean then
				table.insert(StateTags, "ESC")
			end
			if DownedBoolean and not DeadBoolean then
				table.insert(StateTags, "DOWN")
			end
			if HasShieldBoolean then
				table.insert(StateTags, "SHLD")
			elseif ArmedBoolean then
				table.insert(StateTags, "GUN")
			end
		end
	end

	if IsBloodZonePlaceBoolean and IsCurrentTargetBoolean then
		BackgroundColor3 = Color3.fromRGB(140, 100, 0)
		TextColor3 = Color3.fromRGB(255, 245, 170)
	elseif PriorityBoolean then
		BackgroundColor3 = Color3.fromRGB(0, 110, 70)
	elseif WhitelistedBoolean then
		BackgroundColor3 = Color3.fromRGB(110, 45, 45)
		TextColor3 = Color3.fromRGB(255, 210, 210)
	elseif IsBloodZonePlaceBoolean and SafeBoolean then
		BackgroundColor3 = Color3.fromRGB(30, 65, 110)
		TextColor3 = Color3.fromRGB(210, 230, 255)
	elseif IsBloodZonePlaceBoolean and (DeadBoolean or CarriedBoolean or EscapedBoolean) then
		BackgroundColor3 = Color3.fromRGB(55, 55, 55)
		TextColor3 = Color3.fromRGB(190, 190, 190)
	elseif IsBloodZonePlaceBoolean and DownedBoolean then
		BackgroundColor3 = Color3.fromRGB(120, 80, 20)
		TextColor3 = Color3.fromRGB(255, 230, 180)
	elseif IsBloodZonePlaceBoolean and HasShieldBoolean then
		BackgroundColor3 = Color3.fromRGB(55, 70, 85)
		TextColor3 = Color3.fromRGB(225, 235, 255)
	elseif IsBloodZonePlaceBoolean and ArmedBoolean then
		BackgroundColor3 = Color3.fromRGB(45, 75, 45)
		TextColor3 = Color3.fromRGB(220, 255, 220)
	end

	local StateTable = {
		tags = StateTags,
		backgroundColor = BackgroundColor3,
		textColor = TextColor3,
	}
	if PlayerListRuntimeTable.entryStateCache then
		PlayerListRuntimeTable.entryStateCache[PlayerObject] = {
			time = NowNumber,
			character = CharacterModel,
			isCurrentTarget = IsCurrentTargetBoolean,
			isPriority = PriorityBoolean,
			isWhitelist = WhitelistedBoolean,
			state = StateTable,
		}
	end
	return StateTable
end

function PlayerListRuntimeTable.GetOrCreateEmptyLabel()
	local EmptyLabel = PlayerListRuntimeTable.emptyLabel
	if EmptyLabel and EmptyLabel.Parent then
		return EmptyLabel
	end

	EmptyLabel = Instance.new("TextLabel")
	EmptyLabel.Name = "EmptyLabel"
	EmptyLabel.Size = UDim2.new(1, -4, 0, 28)
	EmptyLabel.BackgroundTransparency = 1
	EmptyLabel.Text = "No other players"
	EmptyLabel.Font = Enum.Font.SourceSans
	EmptyLabel.TextSize = 15
	EmptyLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
	EmptyLabel.ZIndex = 102
	EmptyLabel.Visible = false
	EmptyLabel.Parent = PlayerListRuntimeTable.scrollFrame
	PlayerListRuntimeTable.emptyLabel = EmptyLabel
	return EmptyLabel
end

function PlayerListRuntimeTable.GetOrCreateEntryButton(PlayerObject)
	local EntryButton = PlayerListRuntimeTable.entryButtonsByPlayer[PlayerObject]
	if EntryButton and EntryButton.Parent then
		return EntryButton
	end

	EntryButton = Instance.new("TextButton")
	EntryButton.Name = "PlayerEntry_" .. tostring(PlayerObject.UserId)
	EntryButton.Size = UDim2.new(1, -4, 0, 32)
	EntryButton.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
	EntryButton.BorderSizePixel = 0
	EntryButton.AutoButtonColor = false
	EntryButton.Font = Enum.Font.SourceSans
	EntryButton.TextSize = 15
	EntryButton.TextXAlignment = Enum.TextXAlignment.Left
	EntryButton.Text = ""
	EntryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	EntryButton.ZIndex = 102
	EntryButton.Parent = PlayerListRuntimeTable.scrollFrame
	ApplyAimbotUiDecoration(EntryButton, 5, Color3.fromRGB(60, 80, 105))

	local NameLabel = Instance.new("TextLabel")
	NameLabel.Name = "NameLabel"
	NameLabel.Size = UDim2.new(1, -8, 0, 15)
	NameLabel.Position = UDim2.new(0, 4, 0, 1)
	NameLabel.BackgroundTransparency = 1
	NameLabel.Font = Enum.Font.SourceSans
	NameLabel.TextSize = 15
	NameLabel.TextXAlignment = Enum.TextXAlignment.Left
	NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	NameLabel.ZIndex = 103
	NameLabel.Parent = EntryButton

	local TagsLabel = Instance.new("TextLabel")
	TagsLabel.Name = "TagsLabel"
	TagsLabel.Size = UDim2.new(1, -8, 0, 13)
	TagsLabel.Position = UDim2.new(0, 4, 0, 16)
	TagsLabel.BackgroundTransparency = 1
	TagsLabel.Font = Enum.Font.Code
	TagsLabel.TextSize = 11
	TagsLabel.TextXAlignment = Enum.TextXAlignment.Left
	TagsLabel.TextTruncate = Enum.TextTruncate.AtEnd
	TagsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	TagsLabel.ZIndex = 103
	TagsLabel.Parent = EntryButton

	EntryButton.MouseButton1Click.Connect(EntryButton.MouseButton1Click, function()
		if IsAimbotUiInputSuppressed() then
			return
		end
		if PlayerListRuntimeTable.IsPriorityPlayer(PlayerObject) then
			PlayerListRuntimeTable.priorityByPlayer[PlayerObject] = nil
			UpdateDebugStatus("priority target cleared=" .. PlayerObject.Name)
			DebugLog("priority-target", "Priority target cleared for " .. PlayerObject.Name, true)
		else
			PlayerListRuntimeTable.priorityByPlayer[PlayerObject] = true
			PlayerListRuntimeTable.whitelistByPlayer[PlayerObject] = nil
			UpdateDebugStatus("priority target=" .. PlayerObject.Name)
			DebugLog("priority-target", "Priority target set to " .. PlayerObject.Name, true)
		end

		InvalidateSearchableCharacterEntriesCache()
		PlayerListRuntimeTable.RefreshUi(true)
	end)

	EntryButton.MouseButton2Click.Connect(EntryButton.MouseButton2Click, function()
		if IsAimbotUiInputSuppressed() then
			return
		end
		local NextWhitelistedBoolean = not PlayerListRuntimeTable.IsPlayerWhitelisted(PlayerObject)
		PlayerListRuntimeTable.whitelistByPlayer[PlayerObject] = NextWhitelistedBoolean or nil
		if NextWhitelistedBoolean and PlayerListRuntimeTable.IsPriorityPlayer(PlayerObject) then
			PlayerListRuntimeTable.priorityByPlayer[PlayerObject] = nil
		end
		if NextWhitelistedBoolean then
			PlayerListRuntimeTable.ClearTrackedTargetForPlayer(PlayerObject)
		end

		UpdateDebugStatus("whitelist " .. PlayerObject.Name .. "=" .. tostring(NextWhitelistedBoolean))
		DebugLog("whitelist-target", "Whitelist for " .. PlayerObject.Name .. " set to " .. tostring(NextWhitelistedBoolean), true)
		InvalidateSearchableCharacterEntriesCache()
		PlayerListRuntimeTable.RefreshUi(true)
	end)

	PlayerListRuntimeTable.entryButtonsByPlayer[PlayerObject] = EntryButton
	return EntryButton
end

function PlayerListRuntimeTable.RefreshUi(ForceBoolean)
	local NowNumber = tick()
	if not ForceBoolean and (NowNumber - PlayerListRuntimeTable.lastRefreshTime) < PlayerListRuntimeTable.refreshInterval then
		return
	end
	PlayerListRuntimeTable.lastRefreshTime = NowNumber

	PlayerListRuntimeTable.CleanupTargetPreferences()

	local PlayerRowsTable = {}
	for _, PlayerObject in ipairs(Players.GetPlayers(Players)) do
		if PlayerObject ~= LocalPlayer then
			local CharacterModel = IsBloodZonePlaceBoolean and ResolveCharacterModelForPlayer(PlayerObject) or nil
			local IsCurrentTargetBoolean = CurrentTargetPlayerObject == PlayerObject
				or (IsBloodZonePlaceBoolean and CharacterModel ~= nil and CurrentTargetCharacterModel == CharacterModel)
			local DisplayNameString = PlayerListRuntimeTable.GetDisplayName(PlayerObject)
			PlayerRowsTable[#PlayerRowsTable + 1] = {
				player = PlayerObject,
				character = CharacterModel,
				displayName = DisplayNameString,
				displayNameLower = string.lower(DisplayNameString),
				isCurrentTarget = IsCurrentTargetBoolean,
				isPriority = PlayerListRuntimeTable.IsPriorityPlayer(PlayerObject),
				isWhitelist = PlayerListRuntimeTable.IsPlayerWhitelisted(PlayerObject),
				entryState = PlayerListRuntimeTable.GetEntryState(PlayerObject, CharacterModel, IsCurrentTargetBoolean),
			}
		end
	end

	table.sort(PlayerRowsTable, function(LeftEntryTable, RightEntryTable)
		if LeftEntryTable.isCurrentTarget ~= RightEntryTable.isCurrentTarget then
			return LeftEntryTable.isCurrentTarget
		end

		if LeftEntryTable.isPriority ~= RightEntryTable.isPriority then
			return LeftEntryTable.isPriority
		end

		if LeftEntryTable.isWhitelist ~= RightEntryTable.isWhitelist then
			return not LeftEntryTable.isWhitelist
		end

		return LeftEntryTable.displayNameLower < RightEntryTable.displayNameLower
	end)

	local ActivePlayersTable = {}
	if #PlayerRowsTable == 0 then
		PlayerListRuntimeTable.GetOrCreateEmptyLabel().Visible = true
	else
		local EmptyLabel = PlayerListRuntimeTable.emptyLabel
		if EmptyLabel then
			EmptyLabel.Visible = false
		end

		for LayoutOrderNumber, EntryTable in ipairs(PlayerRowsTable) do
			local PlayerObject = EntryTable.player
			ActivePlayersTable[PlayerObject] = true
			local EntryButton = PlayerListRuntimeTable.GetOrCreateEntryButton(PlayerObject)
			local EntryStateTable = EntryTable.entryState
			local DisplayNameString = EntryTable.displayName
			local NameLabel = EntryButton.FindFirstChild and EntryButton.FindFirstChild(EntryButton, "NameLabel") or nil
			local TagsLabel = EntryButton.FindFirstChild and EntryButton.FindFirstChild(EntryButton, "TagsLabel") or nil

			EntryButton.LayoutOrder = LayoutOrderNumber
			EntryButton.BackgroundColor3 = EntryStateTable.backgroundColor
			if NameLabel then
				NameLabel.TextColor3 = EntryStateTable.textColor
				NameLabel.Text = DisplayNameString
			end
			if TagsLabel then
				TagsLabel.TextColor3 = EntryStateTable.textColor
				TagsLabel.Visible = IsBloodZonePlaceBoolean or #EntryStateTable.tags > 0
				TagsLabel.Text = #EntryStateTable.tags > 0 and table.concat(EntryStateTable.tags, " ") or ""
			end
		end
	end

	local StalePlayersTable = {}
	for PlayerObject in pairs(PlayerListRuntimeTable.entryButtonsByPlayer) do
		if not ActivePlayersTable[PlayerObject] then
			table.insert(StalePlayersTable, PlayerObject)
		end
	end
	for _, PlayerObject in ipairs(StalePlayersTable) do
		local EntryButton = PlayerListRuntimeTable.entryButtonsByPlayer[PlayerObject]
		PlayerListRuntimeTable.entryButtonsByPlayer[PlayerObject] = nil
		if EntryButton and EntryButton.Parent then
			EntryButton.Destroy(EntryButton)
		end
	end

	local WhitelistCountNumber = 0
	for _, WhitelistedBoolean in pairs(PlayerListRuntimeTable.whitelistByPlayer) do
		if WhitelistedBoolean then
			WhitelistCountNumber = WhitelistCountNumber + 1
		end
	end

	local PriorityCountNumber = 0
	for _, PriorityBoolean in pairs(PlayerListRuntimeTable.priorityByPlayer) do
		if PriorityBoolean then
			PriorityCountNumber = PriorityCountNumber + 1
		end
	end
	PlayerListRuntimeTable.titleLabel.Text = "Players (" .. tostring(#PlayerRowsTable) .. ")"
	if IsBloodZonePlaceBoolean then
		PlayerListRuntimeTable.statusLabel.Text = "LMB: priority | RMB: whitelist\nP: " .. tostring(PriorityCountNumber) .. " | W: " .. tostring(WhitelistCountNumber) .. " | TGT SAFE DOWN SHLD GUN"
	else
		PlayerListRuntimeTable.statusLabel.Text = "LMB: priority | RMB: whitelist\nP: " .. tostring(PriorityCountNumber) .. " | W: " .. tostring(WhitelistCountNumber)
	end
	PlayerListRuntimeTable.scrollFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(#PlayerRowsTable * 34, 34))
end

Players.PlayerAdded.Connect(Players.PlayerAdded, function()
	PlayerListRuntimeTable.RefreshUi(true)
end)

Players.PlayerRemoving.Connect(Players.PlayerRemoving, function(PlayerObject)
	PlayerListRuntimeTable.whitelistByPlayer[PlayerObject] = nil
	PlayerListRuntimeTable.priorityByPlayer[PlayerObject] = nil
	PlayerListRuntimeTable.ClearTrackedTargetForPlayer(PlayerObject)
	ResolveCharacterModelCacheTable[PlayerObject] = nil
	PlayerListRuntimeTable.entryStateCache[PlayerObject] = nil
	InvalidateSearchableCharacterEntriesCache()
	PlayerListRuntimeTable.RefreshUi(true)
end)

function IsLocalCharacterReadyForAimbot(CharacterModel)
	if not CharacterModel or not CharacterModel.Parent then
		return false
	end

	local Humanoid = GetCharacterHumanoid(CharacterModel)
	local RootPartInstance = GetCharacterRootPart(CharacterModel)
	if not Humanoid or not RootPartInstance then
		return false
	end

	if CharacterModel.GetAttribute(CharacterModel, "Carried") then
		return false
	end

	if CharacterModel.GetAttribute(CharacterModel, "Escaped") then
		return false
	end

	if CharacterModel.GetAttribute(CharacterModel, "Downed") then
		return false
	end

	if CharacterModel.GetAttribute(CharacterModel, "IsRagdolled") then
		return false
	end

	if CollectionService.HasTag(CollectionService, CharacterModel, "DeadBody") then
		return false
	end

	if Humanoid.GetAttribute and Humanoid.GetAttribute(Humanoid, "Dead") then
		return false
	end

	local HealthNumber = Humanoid.Health
	return type(HealthNumber) == "number" and HealthNumber > 0
end

function HasEquippedTool(CharacterModel)
	if not CharacterModel then
		return false
	end

	for _, ChildInstance in ipairs(CharacterModel.GetChildren(CharacterModel)) do
		if ChildInstance.IsA(ChildInstance, "Tool") then
			return true
		end
	end

	if IsBloodZonePlaceBoolean then
		if ShieldModeRuntimeTable.GetEquippedGunTool and ShieldModeRuntimeTable.GetEquippedGunTool(CharacterModel) then
			return true
		end

		if CharacterModel.FindFirstChild and CharacterModel.FindFirstChild(CharacterModel, "GUN_CORE", true) then
			return true
		end
	end

	return false
end

HasEquippedGun = function(CharacterModel)
	if not CharacterModel then
		return false
	end

	if IsBloodZonePlaceBoolean and ShieldModeRuntimeTable.GetBloodZoneHeldItemState then
		local HeldItemStateTable = ShieldModeRuntimeTable.GetBloodZoneHeldItemState(CharacterModel)
		return HeldItemStateTable ~= nil and HeldItemStateTable.hasGun == true
	end

	if ShieldModeRuntimeTable.GetEquippedGunTool and ShieldModeRuntimeTable.GetEquippedGunTool(CharacterModel) then
		return true
	end

	if not IsBloodZonePlaceBoolean then
		return false
	end

	if CharacterModel.FindFirstChild and CharacterModel.FindFirstChild(CharacterModel, "GUN_CORE", true) then
		return true
	end

	local GetGunDataByNameFunction = ShieldModeRuntimeTable.GetGunDataByName
	for _, DescendantInstance in ipairs(CharacterModel.GetDescendants(CharacterModel)) do
		if DescendantInstance.IsA(DescendantInstance, "Tool") or DescendantInstance.IsA(DescendantInstance, "Model") then
			if DescendantInstance.Name ~= "Metal Shield"
				and GetGunDataByNameFunction
				and GetGunDataByNameFunction(DescendantInstance.Name) ~= nil then
				return true
			end
		elseif DescendantInstance.IsA(DescendantInstance, "BasePart") then
			if DescendantInstance.Name == "GUN_CORE" then
				return true
			end

			local TargetWeldParentName = DescendantInstance.GetAttribute and DescendantInstance.GetAttribute(DescendantInstance, "TargetWeldParent") or nil
			if type(TargetWeldParentName) == "string" and TargetWeldParentName ~= "" then
				local AncestorInstance = DescendantInstance.Parent
				while AncestorInstance and AncestorInstance ~= CharacterModel do
					if AncestorInstance.IsA(AncestorInstance, "Tool") or AncestorInstance.IsA(AncestorInstance, "Model") then
						if AncestorInstance.Name ~= "Metal Shield"
							and GetGunDataByNameFunction
							and GetGunDataByNameFunction(AncestorInstance.Name) ~= nil then
							return true
						end
					end
					AncestorInstance = AncestorInstance.Parent
				end
			end
		end
	end

	return false
end


function GetBloodZoneMetalShieldTool(CharacterModel)
	if not IsBloodZonePlaceBoolean or not CharacterModel then
		return nil
	end

	if ShieldModeRuntimeTable.GetBloodZoneHeldItemState then
		local HeldItemStateTable = ShieldModeRuntimeTable.GetBloodZoneHeldItemState(CharacterModel)
		if HeldItemStateTable and HeldItemStateTable.shieldInstance then
			return HeldItemStateTable.shieldInstance
		end
	end

	for _, ChildInstance in ipairs(CharacterModel.GetChildren(CharacterModel)) do
		if ChildInstance.IsA(ChildInstance, "Tool") and ChildInstance.Name == "Metal Shield" then
			return ChildInstance
		end
	end

	local DescendantTool = CharacterModel.FindFirstChild and CharacterModel.FindFirstChild(CharacterModel, "Metal Shield", true) or nil
	if DescendantTool and DescendantTool.IsA and DescendantTool.IsA(DescendantTool, "Tool") then
		return DescendantTool
	end

	return nil
end

function ShieldModeRuntimeTable.ResolveWeaponClientModule()
	if not IsBloodZonePlaceBoolean then
		return nil
	end

	if ShieldModeRuntimeTable.weaponClientModule then
		return ShieldModeRuntimeTable.weaponClientModule
	end

	local ModulesFolder = ReplicatedStorageService and ReplicatedStorageService.FindFirstChild(ReplicatedStorageService, "Modules") or nil
	local ClientFolder = ModulesFolder and ModulesFolder.FindFirstChild(ModulesFolder, "Client") or nil
	local GameFolder = ClientFolder and ClientFolder.FindFirstChild(ClientFolder, "Game") or nil
	local WeaponClientModuleScript = GameFolder and GameFolder.FindFirstChild(GameFolder, "WeaponClient") or nil
	if not WeaponClientModuleScript then
		return nil
	end

	local SuccessBoolean, ModuleTable = pcall(require, WeaponClientModuleScript)
	if not SuccessBoolean or type(ModuleTable) ~= "table" then
		return nil
	end

	ShieldModeRuntimeTable.weaponClientModule = ModuleTable
	return ModuleTable
end

function ShieldModeRuntimeTable.ResolveClientProjectilesModule()
	if not IsBloodZonePlaceBoolean then
		return nil
	end

	if ShieldModeRuntimeTable.clientProjectilesModule then
		return ShieldModeRuntimeTable.clientProjectilesModule
	end

	local ModulesFolder = ReplicatedStorageService and ReplicatedStorageService.FindFirstChild(ReplicatedStorageService, "Modules") or nil
	local ClientFolder = ModulesFolder and ModulesFolder.FindFirstChild(ModulesFolder, "Client") or nil
	local GameFolder = ClientFolder and ClientFolder.FindFirstChild(ClientFolder, "Game") or nil
	local WeaponClientModuleScript = GameFolder and GameFolder.FindFirstChild(GameFolder, "WeaponClient") or nil
	local ClientProjectilesModuleScript = WeaponClientModuleScript and WeaponClientModuleScript.FindFirstChild(WeaponClientModuleScript, "ClientProjectiles") or nil
	if not ClientProjectilesModuleScript then
		return nil
	end

	local SuccessBoolean, ModuleTable = pcall(require, ClientProjectilesModuleScript)
	if not SuccessBoolean or type(ModuleTable) ~= "table" then
		return nil
	end

	ShieldModeRuntimeTable.clientProjectilesModule = ModuleTable
	return ModuleTable
end

function ShieldModeRuntimeTable.ResolveCurrentLocalGun(LocalCharacterModel)
	local FrameIdNumber = tonumber(CurrentFrameSequenceNumber) or 0
	local EquippedGunToolInstance = ShieldModeRuntimeTable.GetEquippedGunTool
		and ShieldModeRuntimeTable.GetEquippedGunTool(LocalCharacterModel) or nil
	if ShieldModeRuntimeTable.currentLocalGunResolved
		and ShieldModeRuntimeTable.currentLocalGunFrameId == FrameIdNumber
		and ShieldModeRuntimeTable.currentLocalGunCharacter == LocalCharacterModel
		and ShieldModeRuntimeTable.currentLocalGunTool == EquippedGunToolInstance then
		return ShieldModeRuntimeTable.activeLocalGun
	end

	local function FinalizeResolvedLocalGun(ResolvedLocalGunTable)
		local PreviousLocalGunTable = ShieldModeRuntimeTable.activeLocalGun
		ShieldModeRuntimeTable.activeLocalGun = ResolvedLocalGunTable
		ShieldModeRuntimeTable.currentLocalGunFrameId = FrameIdNumber
		ShieldModeRuntimeTable.currentLocalGunCharacter = LocalCharacterModel
		ShieldModeRuntimeTable.currentLocalGunTool = EquippedGunToolInstance
		ShieldModeRuntimeTable.currentLocalGunResolved = true
		if PreviousLocalGunTable ~= ResolvedLocalGunTable then
			ShieldModeRuntimeTable.currentLocalGunMuzzleOriginFrameId = 0
			ShieldModeRuntimeTable.currentLocalGunMuzzleOriginValue = nil
			ShieldModeRuntimeTable.currentLocalGunRaycastParamsFrameId = 0
			ShieldModeRuntimeTable.currentLocalGunRaycastParamsValue = nil
			ShieldModeRuntimeTable.currentLocalGunCheckParamsFrameId = 0
			ShieldModeRuntimeTable.currentLocalGunCheckParamsValue = nil
			ShieldModeRuntimeTable.currentWeaponBallisticsProfileFrameId = 0
			ShieldModeRuntimeTable.currentWeaponBallisticsProfileCharacter = nil
			ShieldModeRuntimeTable.currentWeaponBallisticsProfileLocalGun = nil
			ShieldModeRuntimeTable.currentWeaponBallisticsProfileValue = nil
		end
		return ResolvedLocalGunTable
	end

	if not IsBloodZonePlaceBoolean or not LocalCharacterModel or not LocalCharacterModel.Parent then
		return FinalizeResolvedLocalGun(nil)
	end

	local ActiveLocalGunTable = ShieldModeRuntimeTable.activeLocalGun
	if type(ActiveLocalGunTable) == "table"
		and type(ActiveLocalGunTable.GetBase) == "function"
		and type(ActiveLocalGunTable.Settings) == "table"
		and IsSupportedBloodZoneWeaponType(ActiveLocalGunTable.Settings.WeaponType)
		and ActiveLocalGunTable.CharacterModel == LocalCharacterModel
		and ActiveLocalGunTable.Equipped
		and ActiveLocalGunTable.Tool == EquippedGunToolInstance then
		return FinalizeResolvedLocalGun(ActiveLocalGunTable)
	end

	local WeaponClientModuleTable = ShieldModeRuntimeTable.ResolveWeaponClientModule()
	local LoadedWeaponsTable = WeaponClientModuleTable and WeaponClientModuleTable.LoadedWeapons or nil
	if type(LoadedWeaponsTable) ~= "table" then
		return FinalizeResolvedLocalGun(nil)
	end

	if EquippedGunToolInstance then
		for _, LoadedWeaponTable in pairs(LoadedWeaponsTable) do
			if type(LoadedWeaponTable) == "table"
				and LoadedWeaponTable.Tool == EquippedGunToolInstance
				and type(LoadedWeaponTable.GetBase) == "function"
				and type(LoadedWeaponTable.Settings) == "table"
				and IsSupportedBloodZoneWeaponType(LoadedWeaponTable.Settings.WeaponType) then
				return FinalizeResolvedLocalGun(LoadedWeaponTable)
			end
		end
	end

	local FallbackLocalGunTable = nil
	for _, LoadedWeaponTable in pairs(LoadedWeaponsTable) do
		local GunToolInstance = LoadedWeaponTable and LoadedWeaponTable.Tool or nil
		local GunSettingsTable = LoadedWeaponTable and LoadedWeaponTable.Settings or nil
		local GunCharacterModel = LoadedWeaponTable and LoadedWeaponTable.CharacterModel or nil
		local GunEquippedBoolean = LoadedWeaponTable and LoadedWeaponTable.Equipped or false
		local GunMatchesCharacterBoolean = GunCharacterModel == LocalCharacterModel
			or (GunToolInstance and GunToolInstance.IsDescendantOf and GunToolInstance.IsDescendantOf(GunToolInstance, LocalCharacterModel))
		if type(LoadedWeaponTable) == "table"
			and GunMatchesCharacterBoolean
			and type(LoadedWeaponTable.GetBase) == "function"
			and type(GunSettingsTable) == "table"
			and IsSupportedBloodZoneWeaponType(GunSettingsTable.WeaponType) then
			if GunEquippedBoolean then
				return FinalizeResolvedLocalGun(LoadedWeaponTable)
			end

			if not FallbackLocalGunTable then
				FallbackLocalGunTable = LoadedWeaponTable
			end
		end
	end

	if FallbackLocalGunTable then
		return FinalizeResolvedLocalGun(FallbackLocalGunTable)
	end

	return FinalizeResolvedLocalGun(nil)
end

function GetLocalGunTipWorldPosition(LocalGunTable)
	if type(LocalGunTable) ~= "table" then
		return nil
	end

	local CurrentBaseInstance = SafeGetLocalGunBase(LocalGunTable)
	if not CurrentBaseInstance then
		return nil
	end

	local TipInstance = CurrentBaseInstance and CurrentBaseInstance.FindFirstChild and CurrentBaseInstance.FindFirstChild(CurrentBaseInstance, "Tip") or nil
	if TipInstance and TipInstance.Parent then
		if TipInstance.IsA and TipInstance.IsA(TipInstance, "Attachment") then
			local SuccessBoolean, TipWorldPositionVector3 = pcall(function()
				return TipInstance.WorldPosition
			end)
			if SuccessBoolean and typeof(TipWorldPositionVector3) == "Vector3" then
				return TipWorldPositionVector3
			end
		end
		if TipInstance.IsA and TipInstance.IsA(TipInstance, "BasePart") then
			return TipInstance.Position
		end
	end

	local FallbackTipInstance = LocalGunTable.Tip
	if FallbackTipInstance and FallbackTipInstance.Parent then
		if FallbackTipInstance.IsA and FallbackTipInstance.IsA(FallbackTipInstance, "Attachment") then
			local SuccessBoolean, TipWorldPositionVector3 = pcall(function()
				return FallbackTipInstance.WorldPosition
			end)
			if SuccessBoolean and typeof(TipWorldPositionVector3) == "Vector3" then
				return TipWorldPositionVector3
			end
		end
		if FallbackTipInstance.IsA and FallbackTipInstance.IsA(FallbackTipInstance, "BasePart") then
			return FallbackTipInstance.Position
		end
	end

	return nil
end

function ShieldModeRuntimeTable.GetCurrentLocalGunMuzzleOrigin(LocalCharacterModel)
	local FrameIdNumber = tonumber(CurrentFrameSequenceNumber) or 0
	local ActiveLocalGunTable = ShieldModeRuntimeTable.ResolveCurrentLocalGun(LocalCharacterModel)
	if ShieldModeRuntimeTable.currentLocalGunMuzzleOriginFrameId == FrameIdNumber
		and ShieldModeRuntimeTable.currentLocalGunCharacter == LocalCharacterModel
		and ShieldModeRuntimeTable.activeLocalGun == ActiveLocalGunTable then
		return ShieldModeRuntimeTable.currentLocalGunMuzzleOriginValue
	end

	if not ActiveLocalGunTable then
		ShieldModeRuntimeTable.currentLocalGunMuzzleOriginFrameId = FrameIdNumber
		ShieldModeRuntimeTable.currentLocalGunMuzzleOriginValue = nil
		return nil
	end

	local MuzzleOriginVector3 = GetLocalGunTipWorldPosition(ActiveLocalGunTable)
	ShieldModeRuntimeTable.currentLocalGunMuzzleOriginFrameId = FrameIdNumber
	ShieldModeRuntimeTable.currentLocalGunMuzzleOriginValue = MuzzleOriginVector3
	return MuzzleOriginVector3
end

function ShieldModeRuntimeTable.GetCurrentLocalGunRaycastParams(LocalCharacterModel)
	local FrameIdNumber = tonumber(CurrentFrameSequenceNumber) or 0
	local ActiveLocalGunTable = ShieldModeRuntimeTable.ResolveCurrentLocalGun(LocalCharacterModel)
	if ShieldModeRuntimeTable.currentLocalGunRaycastParamsFrameId == FrameIdNumber
		and ShieldModeRuntimeTable.currentLocalGunCharacter == LocalCharacterModel
		and ShieldModeRuntimeTable.activeLocalGun == ActiveLocalGunTable then
		return ShieldModeRuntimeTable.currentLocalGunRaycastParamsValue
	end

	local RayParamsObject = ActiveLocalGunTable and ActiveLocalGunTable.RayParams or nil
	local FinalRaycastParamsObject = RayParamsObject or VisibilityRaycastParams
	ShieldModeRuntimeTable.currentLocalGunRaycastParamsFrameId = FrameIdNumber
	ShieldModeRuntimeTable.currentLocalGunRaycastParamsValue = FinalRaycastParamsObject
	return FinalRaycastParamsObject
end

function ShieldModeRuntimeTable.GetCurrentLocalGunCheckParams(LocalCharacterModel)
	local FrameIdNumber = tonumber(CurrentFrameSequenceNumber) or 0
	local ActiveLocalGunTable = ShieldModeRuntimeTable.ResolveCurrentLocalGun(LocalCharacterModel)
	if ShieldModeRuntimeTable.currentLocalGunCheckParamsFrameId == FrameIdNumber
		and ShieldModeRuntimeTable.currentLocalGunCharacter == LocalCharacterModel
		and ShieldModeRuntimeTable.activeLocalGun == ActiveLocalGunTable then
		return ShieldModeRuntimeTable.currentLocalGunCheckParamsValue
	end

	local CheckParamsObject = ActiveLocalGunTable and ActiveLocalGunTable.CheckParams or nil
	ShieldModeRuntimeTable.currentLocalGunCheckParamsFrameId = FrameIdNumber
	ShieldModeRuntimeTable.currentLocalGunCheckParamsValue = CheckParamsObject
	return CheckParamsObject
end

function ShieldModeRuntimeTable.ResolveCurrentWeaponBallisticsProfile(LocalCharacterModel)
	local FrameIdNumber = tonumber(CurrentFrameSequenceNumber) or 0
	local ActiveLocalGunTable = ShieldModeRuntimeTable.ResolveCurrentLocalGun(LocalCharacterModel)
	if ShieldModeRuntimeTable.currentWeaponBallisticsProfileFrameId == FrameIdNumber
		and ShieldModeRuntimeTable.currentWeaponBallisticsProfileCharacter == LocalCharacterModel
		and ShieldModeRuntimeTable.currentWeaponBallisticsProfileLocalGun == ActiveLocalGunTable
		and type(ShieldModeRuntimeTable.currentWeaponBallisticsProfileValue) == "table" then
		return ShieldModeRuntimeTable.currentWeaponBallisticsProfileValue
	end

	local function FinalizeProfile(ProfileResultTable)
		ShieldModeRuntimeTable.currentWeaponBallisticsProfileFrameId = FrameIdNumber
		ShieldModeRuntimeTable.currentWeaponBallisticsProfileCharacter = LocalCharacterModel
		ShieldModeRuntimeTable.currentWeaponBallisticsProfileLocalGun = ActiveLocalGunTable
		ShieldModeRuntimeTable.currentWeaponBallisticsProfileValue = ProfileResultTable
		return ProfileResultTable
	end

	local GunSettingsTable = ActiveLocalGunTable and ActiveLocalGunTable.Settings or nil
	local WeaponTypeString = GunSettingsTable and GunSettingsTable.WeaponType or nil
	local WeaponNameString = GunSettingsTable and GunSettingsTable.Name
		or (ActiveLocalGunTable and ActiveLocalGunTable.Tool and ActiveLocalGunTable.Tool.Name)
		or nil
	local LauncherFallbackProfileTable = WeaponNameString and LauncherBallisticsProfileByNameTable[WeaponNameString] or nil
	local ProjectileNameString = GunSettingsTable and GunSettingsTable.Projectile
		or (LauncherFallbackProfileTable and LauncherFallbackProfileTable.projectileName)
		or nil
	local ProfileTable = {
		localCharacter = LocalCharacterModel,
		localGun = ActiveLocalGunTable,
		settings = GunSettingsTable,
		weaponType = WeaponTypeString,
		isLauncher = WeaponTypeString == "Launcher",
		explodes = GunSettingsTable and GunSettingsTable.Explodes == true or false,
		customShot = GunSettingsTable and GunSettingsTable.CustomShot == true or false,
		launchAsset = GunSettingsTable and GunSettingsTable.LaunchAsset or nil,
		splashRadius = LauncherFallbackProfileTable and tonumber(LauncherFallbackProfileTable.splashRadius) or nil,
		launchMode = LauncherFallbackProfileTable and LauncherFallbackProfileTable.launchMode or nil,
		forceDistanceClamp = LauncherFallbackProfileTable and tonumber(LauncherFallbackProfileTable.forceDistanceClamp) or nil,
		forceDistanceScale = LauncherFallbackProfileTable and tonumber(LauncherFallbackProfileTable.forceDistanceScale) or nil,
		forceDistanceBias = LauncherFallbackProfileTable and tonumber(LauncherFallbackProfileTable.forceDistanceBias) or nil,
		simulationStep = LauncherFallbackProfileTable and tonumber(LauncherFallbackProfileTable.simulationStep) or nil,
		useWorkspaceGravity = LauncherFallbackProfileTable and LauncherFallbackProfileTable.useWorkspaceGravity == true or false,
		delayedExplosion = LauncherFallbackProfileTable and LauncherFallbackProfileTable.delayedExplosion == true or false,
		splashAcceptanceScale = LauncherFallbackProfileTable and tonumber(LauncherFallbackProfileTable.splashAcceptanceScale) or nil,
		muzzleOrigin = ShieldModeRuntimeTable.GetCurrentLocalGunMuzzleOrigin(LocalCharacterModel),
		isProjectile = ProjectileNameString ~= nil or LauncherFallbackProfileTable ~= nil,
		projectileName = ProjectileNameString,
		speed = nil,
		gravity = 0,
		lifetime = nil,
		rayHit = nil,
	}

	local function ApplyProjectileProfileValues(SourceTable)
		if type(SourceTable) ~= "table" then
			return
		end

		if type(ProfileTable.speed) ~= "number" then
			ProfileTable.speed = tonumber(SourceTable.speed or SourceTable.Speed)
		end
		if math.abs(tonumber(ProfileTable.gravity) or 0) <= 0.000001 then
			ProfileTable.gravity = tonumber(SourceTable.gravity or SourceTable.Gravity) or ProfileTable.gravity or 0
		end
		if type(ProfileTable.lifetime) ~= "number" then
			ProfileTable.lifetime = tonumber(SourceTable.lifetime or SourceTable.Lifetime)
		end
		if ProfileTable.rayHit == nil then
			local RayHitValue = SourceTable.rayHit
			if RayHitValue == nil then
				RayHitValue = SourceTable.RayHit
			end
			ProfileTable.rayHit = RayHitValue
		end
		if type(ProfileTable.splashRadius) ~= "number" then
			ProfileTable.splashRadius = tonumber(SourceTable.splashRadius or SourceTable.SplashRadius)
		end
		if type(ProfileTable.launchMode) ~= "string" then
			ProfileTable.launchMode = SourceTable.launchMode
		end
		if type(ProfileTable.forceDistanceClamp) ~= "number" then
			ProfileTable.forceDistanceClamp = tonumber(SourceTable.forceDistanceClamp)
		end
		if type(ProfileTable.forceDistanceScale) ~= "number" then
			ProfileTable.forceDistanceScale = tonumber(SourceTable.forceDistanceScale)
		end
		if type(ProfileTable.forceDistanceBias) ~= "number" then
			ProfileTable.forceDistanceBias = tonumber(SourceTable.forceDistanceBias)
		end
		if type(ProfileTable.simulationStep) ~= "number" then
			ProfileTable.simulationStep = tonumber(SourceTable.simulationStep)
		end
		if ProfileTable.useWorkspaceGravity ~= true and SourceTable.useWorkspaceGravity == true then
			ProfileTable.useWorkspaceGravity = true
		end
		if ProfileTable.delayedExplosion ~= true and SourceTable.delayedExplosion == true then
			ProfileTable.delayedExplosion = true
		end
		if type(ProfileTable.splashAcceptanceScale) ~= "number" then
			ProfileTable.splashAcceptanceScale = tonumber(SourceTable.splashAcceptanceScale)
		end
	end

	if ProjectileNameString == nil and LauncherFallbackProfileTable == nil then
		return FinalizeProfile(ProfileTable)
	end

	ApplyProjectileProfileValues(LauncherFallbackProfileTable)

	local ClientProjectilesModuleTable = ShieldModeRuntimeTable.ResolveClientProjectilesModule()
	local ProjectileDataTable = nil
	local ProjectileDataAccessorTable = ClientProjectilesModuleTable and ClientProjectilesModuleTable.Data or nil
	local GetParamFunction = ProjectileDataAccessorTable and ProjectileDataAccessorTable.GetParam or nil
	if type(GetParamFunction) == "function" then
		local SuccessBoolean, ResultValue = pcall(GetParamFunction, ProjectileNameString)
		if not SuccessBoolean or type(ResultValue) ~= "table" then
			local AlternateSuccessBoolean, AlternateResultValue = pcall(GetParamFunction, ProjectileDataAccessorTable, ProjectileNameString)
			if AlternateSuccessBoolean and type(AlternateResultValue) == "table" then
				SuccessBoolean, ResultValue = AlternateSuccessBoolean, AlternateResultValue
			end
		end
		if SuccessBoolean and type(ResultValue) == "table" then
			ProjectileDataTable = ResultValue
		end
	end
	if not ProjectileDataTable then
		return FinalizeProfile(ProfileTable)
	end

	ProfileTable.projectileData = ProjectileDataTable
	ApplyProjectileProfileValues(ProjectileDataTable)

	local ProjectileParamsTable = ProjectileDataTable.Params
	if type(ProjectileParamsTable) == "table" then
		ProfileTable.gravity = tonumber(ProjectileParamsTable.Gravity) or ProfileTable.gravity or 0
		ProfileTable.lifetime = tonumber(ProjectileParamsTable.Lifetime) or ProfileTable.lifetime

		local CastingParamsTable = ProjectileParamsTable.CastingParams
		if type(CastingParamsTable) == "table" then
			ProfileTable.castType = CastingParamsTable[1]
			ProfileTable.castSize = CastingParamsTable[2]
		end
	end

	return FinalizeProfile(ProfileTable)
end

function ShieldModeRuntimeTable.IsProjectileWeaponProfile(ProfileTable)
	return type(ProfileTable) == "table" and ProfileTable.isProjectile == true
end

function ShieldModeRuntimeTable.IsShotgunWeaponProfile(ProfileTable)
	if type(ProfileTable) ~= "table" or ProfileTable.isProjectile == true then
		return false
	end

	local SettingsTable = ProfileTable.settings
	local WeaponNameString = ProfileTable.weaponName
		or (SettingsTable and SettingsTable.Name)
		or (ProfileTable.localGun and ProfileTable.localGun.Tool and ProfileTable.localGun.Tool.Name)
	if type(WeaponNameString) ~= "string" then
		return false
	end

	return string.find(string.lower(WeaponNameString), "shotgun", 1, true) ~= nil
end

function ShieldModeRuntimeTable.GetShotgunRedirectDistance(ProfileTable, OriginVector3, TargetPositionVector3, OriginalDistanceNumber)
	if not IsSillyModeBehaviorActive()
		or not ShieldModeRuntimeTable.IsShotgunWeaponProfile(ProfileTable)
		or typeof(OriginVector3) ~= "Vector3"
		or typeof(TargetPositionVector3) ~= "Vector3"
		or type(OriginalDistanceNumber) ~= "number"
		or OriginalDistanceNumber <= 0.001 then
		return OriginalDistanceNumber
	end

	local TargetDistanceNumber = (TargetPositionVector3 - OriginVector3).Magnitude
	if TargetDistanceNumber <= 0.001 then
		return OriginalDistanceNumber
	end

	return math.max(OriginalDistanceNumber, TargetDistanceNumber + 6)
end

function ShieldModeRuntimeTable.CanPredictProjectileWeaponProfile(ProfileTable)
	return UseProjectilePredictionBoolean
		and ShieldModeRuntimeTable.IsProjectileWeaponProfile(ProfileTable)
		and (
			(type(ProfileTable.speed) == "number" and ProfileTable.speed > 0)
			or ShouldUseForceCurveProjectileProfile(ProfileTable)
		)
end

function GetCurrentGunVisibilityOrigin(LocalCharacterModel)
	if not LocalCharacterModel or not LocalCharacterModel.Parent then
		return nil
	end

	if ShieldModeRuntimeTable.GetCurrentLocalGunMuzzleOrigin then
		return ShieldModeRuntimeTable.GetCurrentLocalGunMuzzleOrigin(LocalCharacterModel)
	end

	return nil
end

function ResolveTrackedTargetPointVector3(PartInstance, WorldPointVector3, LocalPointVector3)
	if PartInstance and PartInstance.Parent and typeof(LocalPointVector3) == "Vector3" then
		return PartInstance.CFrame:PointToWorldSpace(LocalPointVector3)
	end

	if typeof(WorldPointVector3) == "Vector3" then
		return WorldPointVector3
	end

	if PartInstance and PartInstance.Parent then
		return PartInstance.Position
	end

	return nil
end

function GetCurrentTrackedTargetPointVector3()
	return ResolveTrackedTargetPointVector3(CurrentTargetPartInstance, CurrentTargetPointVector3, CurrentTargetLocalPointVector3)
end

function GetCurrentEffectiveAimPointVector3()
	if typeof(CurrentTargetAimPointVector3) == "Vector3" then
		return CurrentTargetAimPointVector3
	end

	return GetCurrentTrackedTargetPointVector3()
end

function ResolveWeaponAimOriginVector3(LocalCharacterModel, WeaponBallisticsProfileTable)
	local MuzzleOriginVector3 = WeaponBallisticsProfileTable and WeaponBallisticsProfileTable.muzzleOrigin or nil
	if typeof(MuzzleOriginVector3) == "Vector3" then
		return MuzzleOriginVector3
	end

	local HeadPartInstance = LocalCharacterModel and GetCharacterHeadPart(LocalCharacterModel) or nil
	if HeadPartInstance then
		return HeadPartInstance.Position
	end

	local RootPartInstance = LocalCharacterModel and GetCharacterRootPart(LocalCharacterModel) or nil
	if RootPartInstance then
		return RootPartInstance.Position
	end

	local ActiveCamera = WorkspaceService.CurrentCamera or Camera
	return ActiveCamera and ActiveCamera.CFrame.Position or nil
end

function ResolveProjectilePreferredImpactPart(CharacterModel, PartInstance, ProfileTable)
	if not CharacterModel or not CharacterModel.Parent then
		return PartInstance
	end

	if not ShouldPreferProjectileBodyAimForProfile(ProfileTable) then
		return PartInstance
	end

	return GetCharacterRootPart(CharacterModel)
		or GetCharacterTorsoLikePart(CharacterModel)
		or PartInstance
end

function ResolveProjectileBaseTargetPointVector3(CharacterModel, PartInstance, TargetPointVector3, ProfileTable)
	if typeof(TargetPointVector3) ~= "Vector3" then
		return nil, PartInstance
	end

	local PreferredPartInstance = ResolveProjectilePreferredImpactPart(CharacterModel, PartInstance, ProfileTable)
	local PreferredTargetPointVector3 = PreferredPartInstance and PreferredPartInstance.Position or TargetPointVector3
	if ShouldPreferProjectileFeetImpactForProfile(ProfileTable) and PreferredPartInstance then
		local HalfHeightNumber = PreferredPartInstance.Size and (PreferredPartInstance.Size.Y * 0.5) or 1
		local DownwardBiasNumber = math.clamp(HalfHeightNumber * 0.35, 0.35, 1.5)
		PreferredTargetPointVector3 = PreferredTargetPointVector3 - Vector3.new(0, DownwardBiasNumber, 0)
	end

	return PreferredTargetPointVector3, PreferredPartInstance or PartInstance
end

function EvaluateProjectileTravelTime(OriginVector3, TargetPointVector3, TargetVelocityVector3, ProjectileSpeedNumber, GravityNumber, TravelTimeNumber)
	if type(TravelTimeNumber) ~= "number" or TravelTimeNumber <= 0 then
		return nil, nil, nil
	end

	local GravityAccelerationVector3 = Vector3.new(0, -(tonumber(GravityNumber) or 0), 0)
	local FutureTargetPointVector3 = TargetPointVector3 + TargetVelocityVector3 * TravelTimeNumber
	local RequiredVelocityVector3 = (FutureTargetPointVector3 - OriginVector3 - GravityAccelerationVector3 * (0.5 * TravelTimeNumber * TravelTimeNumber)) / TravelTimeNumber
	local RequiredSpeedNumber = RequiredVelocityVector3.Magnitude
	if RequiredSpeedNumber <= 0.001 then
		return nil, nil, nil
	end

	local SpeedErrorNumber = RequiredSpeedNumber - ProjectileSpeedNumber
	local AimDistanceNumber = math.max((FutureTargetPointVector3 - OriginVector3).Magnitude, 32)
	local AimPointVector3 = OriginVector3 + RequiredVelocityVector3.Unit * AimDistanceNumber
	return SpeedErrorNumber, RequiredVelocityVector3, AimPointVector3
end

function SolveLinearInterceptTravelTime(OriginVector3, TargetPointVector3, TargetVelocityVector3, ProjectileSpeedNumber)
	local DisplacementVector3 = TargetPointVector3 - OriginVector3
	local QuadraticANumber = TargetVelocityVector3:Dot(TargetVelocityVector3) - ProjectileSpeedNumber * ProjectileSpeedNumber
	local QuadraticBNumber = 2 * DisplacementVector3:Dot(TargetVelocityVector3)
	local QuadraticCNumber = DisplacementVector3:Dot(DisplacementVector3)
	if math.abs(QuadraticANumber) <= 0.000001 then
		if math.abs(QuadraticBNumber) <= 0.000001 then
			return nil
		end

		local LinearTimeNumber = -QuadraticCNumber / QuadraticBNumber
		if LinearTimeNumber > 0 then
			return LinearTimeNumber
		end

		return nil
	end

	local DiscriminantNumber = QuadraticBNumber * QuadraticBNumber - 4 * QuadraticANumber * QuadraticCNumber
	if DiscriminantNumber < 0 then
		return nil
	end

	local SqrtDiscriminantNumber = math.sqrt(DiscriminantNumber)
	local TravelTimeNumberA = (-QuadraticBNumber - SqrtDiscriminantNumber) / (2 * QuadraticANumber)
	local TravelTimeNumberB = (-QuadraticBNumber + SqrtDiscriminantNumber) / (2 * QuadraticANumber)
	local BestTravelTimeNumber = nil
	for _, TravelTimeNumber in ipairs({ TravelTimeNumberA, TravelTimeNumberB }) do
		if type(TravelTimeNumber) == "number"
			and TravelTimeNumber > 0
			and (not BestTravelTimeNumber or TravelTimeNumber < BestTravelTimeNumber) then
			BestTravelTimeNumber = TravelTimeNumber
		end
	end

	return BestTravelTimeNumber
end

function GetForceCurveProjectileTravelTimeNumber(ProfileTable, DistanceNumber)
	if type(DistanceNumber) ~= "number" or DistanceNumber <= 0.001 then
		return nil, nil
	end

	local DistanceScaleNumber = tonumber(ProfileTable and ProfileTable.forceDistanceScale) or 0.01
	local DistanceBiasNumber = tonumber(ProfileTable and ProfileTable.forceDistanceBias) or 1.001
	local DistanceClampNumber = tonumber(ProfileTable and ProfileTable.forceDistanceClamp)
	local EffectiveDistanceNumber = DistanceNumber
	if type(DistanceClampNumber) == "number" and DistanceClampNumber > 0 then
		EffectiveDistanceNumber = math.min(EffectiveDistanceNumber, DistanceClampNumber)
	end

	local TravelTimeNumber = math.log(EffectiveDistanceNumber * DistanceScaleNumber + DistanceBiasNumber)
	if type(TravelTimeNumber) ~= "number"
		or TravelTimeNumber ~= TravelTimeNumber
		or TravelTimeNumber <= 0.001 then
		return nil, EffectiveDistanceNumber
	end

	return TravelTimeNumber, EffectiveDistanceNumber
end

function SolveForceCurveProjectileAimPointVector3(OriginVector3, TargetPointVector3, TargetVelocityVector3, ProfileTable)
	if typeof(OriginVector3) ~= "Vector3"
		or typeof(TargetPointVector3) ~= "Vector3"
		or typeof(TargetVelocityVector3) ~= "Vector3"
		or not ShouldUseForceCurveProjectileProfile(ProfileTable) then
		return nil, nil
	end

	local MaximumTravelTimeNumber = type(ProfileTable.lifetime) == "number" and ProfileTable.lifetime > 0 and ProfileTable.lifetime or 2
	local MaximumDistanceNumber = tonumber(ProfileTable.forceDistanceClamp)
	local IterativeAimPointVector3 = TargetPointVector3
	local BestAimPointVector3 = nil
	local BestTravelTimeNumber = nil

	for _ = 1, 8 do
		local AimDisplacementVector3 = IterativeAimPointVector3 - OriginVector3
		local AimDistanceNumber = AimDisplacementVector3.Magnitude
		if AimDistanceNumber <= 0.001 then
			return nil, nil
		end
		if type(MaximumDistanceNumber) == "number" and MaximumDistanceNumber > 0 then
			if AimDistanceNumber > (MaximumDistanceNumber + 0.5) then
				return nil, nil
			end
		end

		local TravelTimeNumber = GetForceCurveProjectileTravelTimeNumber(ProfileTable, AimDistanceNumber)
		if type(TravelTimeNumber) ~= "number" or TravelTimeNumber > MaximumTravelTimeNumber then
			return nil, nil
		end

		BestAimPointVector3 = IterativeAimPointVector3
		BestTravelTimeNumber = TravelTimeNumber

		local NextAimPointVector3 = TargetPointVector3 + TargetVelocityVector3 * TravelTimeNumber
		if (NextAimPointVector3 - IterativeAimPointVector3).Magnitude <= 0.05 then
			break
		end

		IterativeAimPointVector3 = NextAimPointVector3
	end

	return BestAimPointVector3, BestTravelTimeNumber
end

function ResolveProjectileLaunchVelocityVector3(OriginVector3, AimPointVector3, ProfileTable)
	if typeof(OriginVector3) ~= "Vector3"
		or typeof(AimPointVector3) ~= "Vector3"
		or type(ProfileTable) ~= "table" then
		return nil, nil
	end

	local LaunchDirectionVector3 = AimPointVector3 - OriginVector3
	local LaunchDistanceNumber = LaunchDirectionVector3.Magnitude
	if LaunchDistanceNumber <= 0.001 then
		return nil, nil
	end

	if ShouldUseForceCurveProjectileProfile(ProfileTable) then
		local TravelTimeNumber, EffectiveDistanceNumber = GetForceCurveProjectileTravelTimeNumber(ProfileTable, LaunchDistanceNumber)
		local MaximumDistanceNumber = tonumber(ProfileTable.forceDistanceClamp)
		if type(MaximumDistanceNumber) == "number"
			and MaximumDistanceNumber > 0
			and LaunchDistanceNumber > (MaximumDistanceNumber + 0.5) then
			return nil, nil
		end
		if type(TravelTimeNumber) ~= "number" then
			return nil, nil
		end

		local GravityNumber = GetProjectileProfileGravityMagnitudeNumber(ProfileTable)
		local LaunchVelocityVector3 = LaunchDirectionVector3.Unit * (EffectiveDistanceNumber / TravelTimeNumber)
			+ Vector3.new(0, GravityNumber * TravelTimeNumber * 0.5, 0)
		return LaunchVelocityVector3, TravelTimeNumber
	end

	local ProjectileSpeedNumber = tonumber(ProfileTable.speed)
	if type(ProjectileSpeedNumber) ~= "number" or ProjectileSpeedNumber <= 0.001 then
		return nil, nil
	end

	return LaunchDirectionVector3.Unit * ProjectileSpeedNumber, LaunchDistanceNumber / ProjectileSpeedNumber
end

function GetProjectileSplashAcceptanceRadiusNumber(ProfileTable, SplashRadiusNumber)
	if type(SplashRadiusNumber) ~= "number" or SplashRadiusNumber <= 0 then
		return 0
	end

	local SplashAcceptanceScaleNumber = tonumber(ProfileTable and ProfileTable.splashAcceptanceScale)
	local AcceptanceRadiusNumber = SplashRadiusNumber
	if type(SplashAcceptanceScaleNumber) == "number" and SplashAcceptanceScaleNumber > 0 then
		AcceptanceRadiusNumber = AcceptanceRadiusNumber * SplashAcceptanceScaleNumber
	end

	if type(ProfileTable) == "table" and ProfileTable.delayedExplosion == true then
		AcceptanceRadiusNumber = math.min(AcceptanceRadiusNumber, SplashRadiusNumber * 0.65)
	end

	return AcceptanceRadiusNumber + 0.5
end

function IsProjectileSplashImpactAcceptable(ProfileTable, ImpactPositionVector3, TargetPointVector3, SplashRadiusNumber)
	if typeof(ImpactPositionVector3) ~= "Vector3" or typeof(TargetPointVector3) ~= "Vector3" then
		return false, math.huge
	end

	local ImpactDistanceNumber = (ImpactPositionVector3 - TargetPointVector3).Magnitude
	local AcceptanceRadiusNumber = GetProjectileSplashAcceptanceRadiusNumber(ProfileTable, SplashRadiusNumber)
	if ImpactDistanceNumber > AcceptanceRadiusNumber then
		return false, ImpactDistanceNumber
	end

	if type(ProfileTable) == "table" and ProfileTable.delayedExplosion == true then
		local VerticalOvershootNumber = ImpactPositionVector3.Y - TargetPointVector3.Y
		local MaximumVerticalOvershootNumber = math.max(1.5, AcceptanceRadiusNumber * 0.35)
		if VerticalOvershootNumber > MaximumVerticalOvershootNumber then
			return false, ImpactDistanceNumber
		end
	end

	return true, ImpactDistanceNumber
end

function SolveStationaryBallisticTravelTime(OriginVector3, TargetPointVector3, ProjectileSpeedNumber, GravityNumber, PreferHighArcBoolean)
	local SignedGravityNumber = tonumber(GravityNumber) or 0
	if math.abs(SignedGravityNumber) <= 0.000001 then
		return (TargetPointVector3 - OriginVector3).Magnitude / ProjectileSpeedNumber
	end
	if SignedGravityNumber < 0 then
		return nil
	end

	local DisplacementVector3 = TargetPointVector3 - OriginVector3
	local HorizontalDistanceNumber = Vector3.new(DisplacementVector3.X, 0, DisplacementVector3.Z).Magnitude
	if HorizontalDistanceNumber <= 0.001 then
		return nil
	end

	local VerticalOffsetNumber = DisplacementVector3.Y
	local ProjectileSpeedSquaredNumber = ProjectileSpeedNumber * ProjectileSpeedNumber
	local DiscriminantNumber = ProjectileSpeedSquaredNumber * ProjectileSpeedSquaredNumber
		- SignedGravityNumber * (SignedGravityNumber * HorizontalDistanceNumber * HorizontalDistanceNumber + 2 * VerticalOffsetNumber * ProjectileSpeedSquaredNumber)
	if DiscriminantNumber < 0 then
		return nil
	end

	local SqrtDiscriminantNumber = math.sqrt(DiscriminantNumber)
	local TangentThetaNumeratorNumber = PreferHighArcBoolean
		and (ProjectileSpeedSquaredNumber + SqrtDiscriminantNumber)
		or (ProjectileSpeedSquaredNumber - SqrtDiscriminantNumber)
	local TangentThetaNumber = TangentThetaNumeratorNumber / (SignedGravityNumber * HorizontalDistanceNumber)
	if type(TangentThetaNumber) ~= "number" or TangentThetaNumber ~= TangentThetaNumber then
		return nil
	end

	local CosThetaNumber = 1 / math.sqrt(1 + TangentThetaNumber * TangentThetaNumber)
	if CosThetaNumber <= 0.001 then
		return nil
	end

	return HorizontalDistanceNumber / (ProjectileSpeedNumber * CosThetaNumber)
end

function SolveProjectileAimPointVector3(OriginVector3, TargetPointVector3, TargetVelocityVector3, ProjectileSpeedNumber, GravityNumber, LifetimeNumber, PreferHighArcBoolean)
	if typeof(OriginVector3) ~= "Vector3"
		or typeof(TargetPointVector3) ~= "Vector3"
		or typeof(TargetVelocityVector3) ~= "Vector3"
		or type(ProjectileSpeedNumber) ~= "number"
		or ProjectileSpeedNumber <= 0.001 then
		return nil, nil
	end

	local MaximumTravelTimeNumber = type(LifetimeNumber) == "number" and LifetimeNumber > 0 and LifetimeNumber or 8
	local MinimumTravelTimeNumber = math.min(0.01, MaximumTravelTimeNumber)
	local BestAimPointVector3 = nil
	local BestTravelTimeNumber = nil
	local BestSpeedErrorNumber = math.huge

	local function ConsiderTravelTime(TravelTimeNumber)
		local ClampedTravelTimeNumber = math.clamp(TravelTimeNumber, MinimumTravelTimeNumber, MaximumTravelTimeNumber)
		local SpeedErrorNumber, RequiredVelocityVector3, AimPointVector3 = EvaluateProjectileTravelTime(
			OriginVector3,
			TargetPointVector3,
			TargetVelocityVector3,
			ProjectileSpeedNumber,
			GravityNumber,
			ClampedTravelTimeNumber
		)
		if type(SpeedErrorNumber) ~= "number" then
			return nil, nil, nil
		end

		local AbsoluteSpeedErrorNumber = math.abs(SpeedErrorNumber)
		local ShouldReplaceBestBoolean = AbsoluteSpeedErrorNumber < (BestSpeedErrorNumber - 0.0001)
		if not ShouldReplaceBestBoolean and math.abs(AbsoluteSpeedErrorNumber - BestSpeedErrorNumber) <= 0.0001 then
			if type(BestTravelTimeNumber) ~= "number" then
				ShouldReplaceBestBoolean = true
			elseif PreferHighArcBoolean then
				ShouldReplaceBestBoolean = ClampedTravelTimeNumber > BestTravelTimeNumber
			else
				ShouldReplaceBestBoolean = ClampedTravelTimeNumber < BestTravelTimeNumber
			end
		end

		if ShouldReplaceBestBoolean then
			BestSpeedErrorNumber = AbsoluteSpeedErrorNumber
			BestTravelTimeNumber = ClampedTravelTimeNumber
			BestAimPointVector3 = AimPointVector3
		end

		return SpeedErrorNumber, RequiredVelocityVector3, AimPointVector3
	end

	local StraightLineTravelTimeNumber = math.clamp(
		(TargetPointVector3 - OriginVector3).Magnitude / ProjectileSpeedNumber,
		MinimumTravelTimeNumber,
		MaximumTravelTimeNumber
	)
	ConsiderTravelTime(StraightLineTravelTimeNumber)

	local SignedGravityNumber = tonumber(GravityNumber) or 0
	if math.abs(SignedGravityNumber) <= 0.000001 then
		local LinearTravelTimeNumber = SolveLinearInterceptTravelTime(OriginVector3, TargetPointVector3, TargetVelocityVector3, ProjectileSpeedNumber)
		if type(LinearTravelTimeNumber) == "number" then
			StraightLineTravelTimeNumber = math.clamp(LinearTravelTimeNumber, MinimumTravelTimeNumber, MaximumTravelTimeNumber)
			ConsiderTravelTime(StraightLineTravelTimeNumber)
		end
	elseif SignedGravityNumber > 0 then
		local IterativeTravelTimeNumber = SolveStationaryBallisticTravelTime(
			OriginVector3,
			TargetPointVector3,
			ProjectileSpeedNumber,
			SignedGravityNumber,
			PreferHighArcBoolean
		)
			or StraightLineTravelTimeNumber
		IterativeTravelTimeNumber = math.clamp(IterativeTravelTimeNumber, MinimumTravelTimeNumber, MaximumTravelTimeNumber)
		ConsiderTravelTime(IterativeTravelTimeNumber)
		for _ = 1, 7 do
			local FutureTargetPointVector3 = TargetPointVector3 + TargetVelocityVector3 * IterativeTravelTimeNumber
			local SolvedTravelTimeNumber = SolveStationaryBallisticTravelTime(
				OriginVector3,
				FutureTargetPointVector3,
				ProjectileSpeedNumber,
				SignedGravityNumber,
				PreferHighArcBoolean
			)
			if type(SolvedTravelTimeNumber) ~= "number" then
				break
			end

			local ClampedTravelTimeNumber = math.clamp(SolvedTravelTimeNumber, MinimumTravelTimeNumber, MaximumTravelTimeNumber)
			local PreviousTravelTimeNumber = IterativeTravelTimeNumber
			IterativeTravelTimeNumber = ClampedTravelTimeNumber
			ConsiderTravelTime(IterativeTravelTimeNumber)
			if math.abs(IterativeTravelTimeNumber - PreviousTravelTimeNumber) <= 0.001 then
				break
			end
		end
	end

	if BestSpeedErrorNumber <= 0.25 then
		return BestAimPointVector3, BestTravelTimeNumber
	end

	local PreviousTimeNumber = MinimumTravelTimeNumber
	local PreviousErrorNumber = ConsiderTravelTime(PreviousTimeNumber)
	local BracketLowTimeNumber = nil
	local BracketHighTimeNumber = nil
	local BracketLowErrorNumber = nil
	local BracketHighErrorNumber = nil
	local SampleCountNumber = 36

	for SampleIndexNumber = 1, SampleCountNumber do
		local AlphaNumber = SampleIndexNumber / SampleCountNumber
		local SampleTimeNumber = MinimumTravelTimeNumber + (MaximumTravelTimeNumber - MinimumTravelTimeNumber) * AlphaNumber
		local SampleErrorNumber = ConsiderTravelTime(SampleTimeNumber)
		if type(PreviousErrorNumber) == "number" and type(SampleErrorNumber) == "number" then
			if PreviousErrorNumber == 0 then
				BracketLowTimeNumber = PreviousTimeNumber
				BracketHighTimeNumber = PreviousTimeNumber
				BracketLowErrorNumber = PreviousErrorNumber
				BracketHighErrorNumber = PreviousErrorNumber
				break
			end
			if SampleErrorNumber == 0
				or (PreviousErrorNumber < 0 and SampleErrorNumber > 0)
				or (PreviousErrorNumber > 0 and SampleErrorNumber < 0) then
				BracketLowTimeNumber = PreviousTimeNumber
				BracketHighTimeNumber = SampleTimeNumber
				BracketLowErrorNumber = PreviousErrorNumber
				BracketHighErrorNumber = SampleErrorNumber
				break
			end
		end
		PreviousTimeNumber = SampleTimeNumber
		PreviousErrorNumber = SampleErrorNumber
	end

	if BracketLowTimeNumber and BracketHighTimeNumber then
		for _ = 1, 16 do
			local MidTimeNumber = (BracketLowTimeNumber + BracketHighTimeNumber) * 0.5
			local MidErrorNumber = ConsiderTravelTime(MidTimeNumber)
			if type(MidErrorNumber) ~= "number" then
				break
			end
			if math.abs(MidErrorNumber) <= 0.001 then
				break
			end
			if type(BracketLowErrorNumber) ~= "number" then
				BracketLowTimeNumber = MidTimeNumber
				BracketLowErrorNumber = MidErrorNumber
			elseif (BracketLowErrorNumber <= 0 and MidErrorNumber <= 0)
				or (BracketLowErrorNumber >= 0 and MidErrorNumber >= 0) then
				BracketLowTimeNumber = MidTimeNumber
				BracketLowErrorNumber = MidErrorNumber
			else
				BracketHighTimeNumber = MidTimeNumber
				BracketHighErrorNumber = MidErrorNumber
			end
		end
	end

	return BestAimPointVector3, BestTravelTimeNumber
end

function SimulateProjectileImpactResult(OriginVector3, AimPointVector3, ProfileTable, RaycastParamsObject, TargetCharacterModel)
	if typeof(OriginVector3) ~= "Vector3"
		or typeof(AimPointVector3) ~= "Vector3"
		or type(ProfileTable) ~= "table" then
		return nil
	end

	local LaunchVelocityVector3 = ResolveProjectileLaunchVelocityVector3(OriginVector3, AimPointVector3, ProfileTable)
	if typeof(LaunchVelocityVector3) ~= "Vector3" or LaunchVelocityVector3.Magnitude <= 0.001 then
		return nil
	end

	local SignedGravityNumber = GetProjectileProfileGravityNumber(ProfileTable)
	local GravityAccelerationVector3 = Vector3.new(0, -SignedGravityNumber, 0)
	local MaximumTravelTimeNumber = type(ProfileTable.lifetime) == "number" and ProfileTable.lifetime > 0 and ProfileTable.lifetime or 8
	local StepDurationNumber = tonumber(ProfileTable.simulationStep) or 0.05
	local PreviousPositionVector3 = OriginVector3
	local ElapsedTimeNumber = 0

	while ElapsedTimeNumber < MaximumTravelTimeNumber do
		local DeltaTimeNumber = math.min(StepDurationNumber, MaximumTravelTimeNumber - ElapsedTimeNumber)
		local NextElapsedTimeNumber = ElapsedTimeNumber + DeltaTimeNumber
		local NextPositionVector3 = OriginVector3
			+ LaunchVelocityVector3 * NextElapsedTimeNumber
			+ GravityAccelerationVector3 * (0.5 * NextElapsedTimeNumber * NextElapsedTimeNumber)
		local SegmentVector3 = NextPositionVector3 - PreviousPositionVector3
		if SegmentVector3.Magnitude > 0.001 then
			local RaycastResult = RunUnredirectedWorkspaceRaycast(PreviousPositionVector3, SegmentVector3, RaycastParamsObject)
			if RaycastResult then
				return {
					hit = RaycastResult,
					hitTarget = IsRaycastResultTargetHit(RaycastResult, TargetCharacterModel),
					impactPosition = RaycastResult.Position,
					elapsedTime = NextElapsedTimeNumber,
				}
			end
		end

		PreviousPositionVector3 = NextPositionVector3
		ElapsedTimeNumber = NextElapsedTimeNumber
	end

	return {
		hit = nil,
		hitTarget = false,
		impactPosition = PreviousPositionVector3,
		elapsedTime = ElapsedTimeNumber,
		expired = true,
	}
end

function ResolveProjectileAimSolutionTable(LocalCharacterModel, CharacterModel, PartInstance, TargetPointVector3, ProfileTable, RequireReachabilityBoolean)
	if typeof(TargetPointVector3) ~= "Vector3"
		or not ShieldModeRuntimeTable.CanPredictProjectileWeaponProfile(ProfileTable) then
		return nil
	end

	local AimOriginVector3 = ResolveWeaponAimOriginVector3(LocalCharacterModel, ProfileTable)
	if typeof(AimOriginVector3) ~= "Vector3" then
		return nil
	end

	local TargetVelocityVector3 = GetCharacterVelocityVector3(CharacterModel, PartInstance)
	local RaycastParamsObject = ProfileTable and ProfileTable.localGun and ProfileTable.localGun.RayParams or VisibilityRaycastParams
	local SplashRadiusNumber = GetProjectileSplashRadiusNumber(ProfileTable) or 0
	local BestSolutionTable = nil

	local function ConsiderArc(PreferHighArcBoolean)
		local AimPointVector3
		local TravelTimeNumber
		if ShouldUseForceCurveProjectileProfile(ProfileTable) then
			if PreferHighArcBoolean then
				return
			end
			AimPointVector3, TravelTimeNumber = SolveForceCurveProjectileAimPointVector3(
				AimOriginVector3,
				TargetPointVector3,
				TargetVelocityVector3,
				ProfileTable
			)
		else
			AimPointVector3, TravelTimeNumber = SolveProjectileAimPointVector3(
				AimOriginVector3,
				TargetPointVector3,
				TargetVelocityVector3,
				ProfileTable.speed,
				GetProjectileProfileGravityNumber(ProfileTable),
				ProfileTable.lifetime,
				PreferHighArcBoolean
			)
		end
		if typeof(AimPointVector3) ~= "Vector3" then
			return
		end
		if type(ProfileTable.lifetime) == "number"
			and type(TravelTimeNumber) == "number"
			and TravelTimeNumber > (ProfileTable.lifetime + 0.05) then
			return
		end

		local CandidateSolutionTable = {
			aimPoint = AimPointVector3,
			travelTime = TravelTimeNumber,
			targetPoint = TargetPointVector3,
			part = PartInstance,
			preferHighArc = PreferHighArcBoolean == true,
			reachabilityScore = RequireReachabilityBoolean and -1 or 0,
			impactDistance = math.huge,
		}

		if RequireReachabilityBoolean then
			local SimulationResultTable = SimulateProjectileImpactResult(
				AimOriginVector3,
				AimPointVector3,
				ProfileTable,
				RaycastParamsObject,
				CharacterModel
			)
			if not SimulationResultTable then
				return
			end

			CandidateSolutionTable.simulation = SimulationResultTable
			local ImpactPositionVector3 = SimulationResultTable.impactPosition
			if SimulationResultTable.hitTarget then
				CandidateSolutionTable.reachabilityScore = 2
				CandidateSolutionTable.impactDistance = 0
			elseif SimulationResultTable.hit and typeof(ImpactPositionVector3) == "Vector3" then
				local SplashImpactAcceptableBoolean, ImpactDistanceNumber = IsProjectileSplashImpactAcceptable(
					ProfileTable,
					ImpactPositionVector3,
					TargetPointVector3,
					SplashRadiusNumber
				)
				CandidateSolutionTable.impactDistance = ImpactDistanceNumber
				if SplashImpactAcceptableBoolean then
					CandidateSolutionTable.reachabilityScore = 1
				else
					return
				end
			else
				return
			end
		end

		local ShouldReplaceBestBoolean = false
		if not BestSolutionTable then
			ShouldReplaceBestBoolean = true
		elseif CandidateSolutionTable.reachabilityScore ~= BestSolutionTable.reachabilityScore then
			ShouldReplaceBestBoolean = CandidateSolutionTable.reachabilityScore > BestSolutionTable.reachabilityScore
		elseif math.abs(CandidateSolutionTable.impactDistance - BestSolutionTable.impactDistance) > 0.05 then
			ShouldReplaceBestBoolean = CandidateSolutionTable.impactDistance < BestSolutionTable.impactDistance
		elseif type(CandidateSolutionTable.travelTime) == "number" and type(BestSolutionTable.travelTime) == "number" then
			ShouldReplaceBestBoolean = CandidateSolutionTable.travelTime < BestSolutionTable.travelTime
		end

		if ShouldReplaceBestBoolean then
			BestSolutionTable = CandidateSolutionTable
		end
	end

	ConsiderArc(false)
	if ShouldPreferHighArcProjectileProfile(ProfileTable) then
		ConsiderArc(true)
	end

	return BestSolutionTable
end

function ResolveTargetAimPointVector3(LocalCharacterModel, CharacterModel, PartInstance, TargetPointVector3)
	if typeof(TargetPointVector3) ~= "Vector3" then
		return nil
	end

	local WeaponBallisticsProfileTable = CurrentWeaponBallisticsProfileTable
	if not ShieldModeRuntimeTable.CanPredictProjectileWeaponProfile(WeaponBallisticsProfileTable) then
		return TargetPointVector3
	end

	local BaseTargetPointVector3, PreferredTargetPartInstance = ResolveProjectileBaseTargetPointVector3(
		CharacterModel,
		PartInstance,
		TargetPointVector3,
		WeaponBallisticsProfileTable
	)
	if typeof(BaseTargetPointVector3) == "Vector3" then
		TargetPointVector3 = BaseTargetPointVector3
		PartInstance = PreferredTargetPartInstance or PartInstance
	end

	local AimOriginVector3 = ResolveWeaponAimOriginVector3(LocalCharacterModel, WeaponBallisticsProfileTable)
	if typeof(AimOriginVector3) ~= "Vector3" then
		return TargetPointVector3
	end

	local ProjectileAimSolutionTable = ResolveProjectileAimSolutionTable(
		LocalCharacterModel,
		CharacterModel,
		PartInstance,
		TargetPointVector3,
		WeaponBallisticsProfileTable,
		ShouldUseProjectileArcVisibilityProfile(WeaponBallisticsProfileTable)
	)
	local AimPointVector3 = ProjectileAimSolutionTable and ProjectileAimSolutionTable.aimPoint or nil
	local TravelTimeNumber = ProjectileAimSolutionTable and ProjectileAimSolutionTable.travelTime or nil
	if typeof(AimPointVector3) ~= "Vector3" then
		return TargetPointVector3
	end

	local LifetimeNumber = tonumber(WeaponBallisticsProfileTable.lifetime)
	if LifetimeNumber and LifetimeNumber > 0 and type(TravelTimeNumber) == "number" and TravelTimeNumber > (LifetimeNumber + 0.05) then
		return TargetPointVector3
	end

	return AimPointVector3
end

function ResolveCurrentSkyTargetData()
	local TargetCharacterModel = CurrentTargetCharacterModel and CurrentTargetCharacterModel.Parent and CurrentTargetCharacterModel or nil
	local TargetPartInstance = CurrentTargetPartInstance and CurrentTargetPartInstance.Parent and CurrentTargetPartInstance or nil
	local TargetPositionVector3 = GetCurrentTrackedTargetPointVector3()
	if not TargetPositionVector3 and TargetPartInstance then
		TargetPositionVector3 = TargetPartInstance.Position
	end

	if not TargetPositionVector3 and TargetCharacterModel then
		local TargetReferencePartInstance = GetCharacterRootPart(TargetCharacterModel) or GetCharacterHeadPart(TargetCharacterModel)
		TargetPositionVector3 = TargetReferencePartInstance and TargetReferencePartInstance.Position or nil
	end

	return TargetPositionVector3, TargetCharacterModel, TargetPartInstance
end

local CachedSkyAimCandidateGroupsByKeyTable = {}

function GetSkyAimCandidateGroups(RequiredPriorityNumber)
	local UseVisibilityPoolBoolean = RequiredPriorityNumber and RequiredPriorityNumber >= 3
	local CacheKeyString = UseVisibilityPoolBoolean and "visibility" or "default"
	local CachedCandidateGroupsTable = CachedSkyAimCandidateGroupsByKeyTable[CacheKeyString]
	if CachedCandidateGroupsTable then
		return CachedCandidateGroupsTable
	end

	local PitchDegreesTable = UseVisibilityPoolBoolean and SkyAimVisibilitySamplePitchDegreesTable or SkyAimSamplePitchDegreesTable
	local YawOffsetDegreesTable = UseVisibilityPoolBoolean and SkyAimVisibilitySampleYawOffsetDegreesTable or SkyAimSampleYawOffsetDegreesTable

	local CandidateGroupsTable = {}
	for _, PitchDegreeNumber in ipairs(PitchDegreesTable) do
		local PitchRadiansNumber = math.rad(PitchDegreeNumber)
		local PitchGroupTable = {
			pitch = PitchDegreeNumber,
			sinPitch = math.sin(PitchRadiansNumber),
			cosPitch = math.cos(PitchRadiansNumber),
			yaws = {},
		}

		for _, YawOffsetDegreeNumber in ipairs(YawOffsetDegreesTable) do
			local YawRadiansNumber = math.rad(YawOffsetDegreeNumber)
			table.insert(PitchGroupTable.yaws, {
				yaw = YawOffsetDegreeNumber,
				rotation = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), YawRadiansNumber),
			})
		end

		table.insert(CandidateGroupsTable, PitchGroupTable)
	end

	CachedSkyAimCandidateGroupsByKeyTable[CacheKeyString] = CandidateGroupsTable
	return CandidateGroupsTable
end

function GetFallbackFlatAimDirectionVector3(LocalCharacterModel, ReferenceDirectionVector3, TargetPositionVector3)
	local RootPartInstance = LocalCharacterModel and GetCharacterRootPart(LocalCharacterModel) or nil
	if RootPartInstance and typeof(TargetPositionVector3) == "Vector3" then
		local TargetFlatDirectionVector3 = Vector3.new(
			TargetPositionVector3.X - RootPartInstance.Position.X,
			0,
			TargetPositionVector3.Z - RootPartInstance.Position.Z
		)
		if TargetFlatDirectionVector3.Magnitude > 0.001 then
			return TargetFlatDirectionVector3.Unit
		end
	end

	if typeof(ReferenceDirectionVector3) == "Vector3" then
		local ReferenceFlatDirectionVector3 = Vector3.new(ReferenceDirectionVector3.X, 0, ReferenceDirectionVector3.Z)
		if ReferenceFlatDirectionVector3.Magnitude > 0.001 then
			return ReferenceFlatDirectionVector3.Unit
		end
	end

	if RootPartInstance then
		local RootLookVector3 = RootPartInstance.CFrame.LookVector
		local RootFlatDirectionVector3 = Vector3.new(RootLookVector3.X, 0, RootLookVector3.Z)
		if RootFlatDirectionVector3.Magnitude > 0.001 then
			return RootFlatDirectionVector3.Unit
		end
	end

	local ActiveCamera = WorkspaceService.CurrentCamera or Camera
	if ActiveCamera then
		local CameraLookVector3 = ActiveCamera.CFrame.LookVector
		local CameraFlatDirectionVector3 = Vector3.new(CameraLookVector3.X, 0, CameraLookVector3.Z)
		if CameraFlatDirectionVector3.Magnitude > 0.001 then
			return CameraFlatDirectionVector3.Unit
		end
	end

	return Vector3.new(0, 0, -1)
end

function BuildFallbackSkyAimSolution(LocalCharacterModel, ReferenceDirectionVector3, TargetPositionVector3)
	local HeadPartInstance = LocalCharacterModel and GetCharacterHeadPart(LocalCharacterModel) or nil
	local RootPartInstance = LocalCharacterModel and GetCharacterRootPart(LocalCharacterModel) or nil
	local ActiveCamera = WorkspaceService.CurrentCamera or Camera
	local MuzzleOriginVector3 = ShieldModeRuntimeTable.GetCurrentLocalGunMuzzleOrigin
		and ShieldModeRuntimeTable.GetCurrentLocalGunMuzzleOrigin(LocalCharacterModel) or nil
	local HitOriginVector3 = MuzzleOriginVector3
		or (HeadPartInstance and HeadPartInstance.Position)
		or (RootPartInstance and RootPartInstance.Position)
		or (ActiveCamera and ActiveCamera.CFrame.Position)
	if typeof(HitOriginVector3) ~= "Vector3" then
		return nil
	end

	local FlatDirectionVector3 = GetFallbackFlatAimDirectionVector3(LocalCharacterModel, ReferenceDirectionVector3, TargetPositionVector3)
	local ShotDirectionVector3 = (Vector3.new(FlatDirectionVector3.X, 1, FlatDirectionVector3.Z)).Unit
	return {
		direction = ShotDirectionVector3,
		hitPosition = HitOriginVector3 + ShotDirectionVector3 * SkyAimHitDistanceNumber,
		facingDirection = FlatDirectionVector3,
		priority = -1,
		isFallback = true,
	}
end

function BuildSkyAimCandidateFacingDirection(BaseFlatDirectionVector3, YawRotationCFrame)
	local FlatDirectionVector3 = Vector3.new(BaseFlatDirectionVector3.X, 0, BaseFlatDirectionVector3.Z)
	if FlatDirectionVector3.Magnitude <= 0.001 then
		FlatDirectionVector3 = Vector3.new(0, 0, -1)
	else
		FlatDirectionVector3 = FlatDirectionVector3.Unit
	end

	local RotatedFlatDirectionVector3 = YawRotationCFrame:VectorToWorldSpace(FlatDirectionVector3)
	RotatedFlatDirectionVector3 = Vector3.new(RotatedFlatDirectionVector3.X, 0, RotatedFlatDirectionVector3.Z)
	if RotatedFlatDirectionVector3.Magnitude <= 0.001 then
		RotatedFlatDirectionVector3 = FlatDirectionVector3
	else
		RotatedFlatDirectionVector3 = RotatedFlatDirectionVector3.Unit
	end

	return RotatedFlatDirectionVector3
end

function BuildSkyAimCandidateDirection(FlatFacingDirectionVector3, PitchSineNumber, PitchCosineNumber)
	local CandidateFlatDirectionVector3 = typeof(FlatFacingDirectionVector3) == "Vector3"
		and Vector3.new(FlatFacingDirectionVector3.X, 0, FlatFacingDirectionVector3.Z)
		or nil
	if typeof(CandidateFlatDirectionVector3) ~= "Vector3" or CandidateFlatDirectionVector3.Magnitude <= 0.001 then
		CandidateFlatDirectionVector3 = Vector3.new(0, 0, -1)
	else
		CandidateFlatDirectionVector3 = CandidateFlatDirectionVector3.Unit
	end

	local CandidateDirectionVector3 = CandidateFlatDirectionVector3 * PitchCosineNumber + Vector3.new(0, PitchSineNumber, 0)
	if CandidateDirectionVector3.Magnitude <= 0.001 then
		return nil
	end

	return CandidateDirectionVector3.Unit
end

function ResolveSkyAimCandidatePose(RootPartInstance, HeadPositionVector3, MuzzleOriginVector3, FacingDirectionVector3)
	if not RootPartInstance
		or typeof(HeadPositionVector3) ~= "Vector3"
		or typeof(MuzzleOriginVector3) ~= "Vector3"
		or typeof(FacingDirectionVector3) ~= "Vector3" then
		return MuzzleOriginVector3, HeadPositionVector3
	end

	local FlatFacingDirectionVector3 = Vector3.new(FacingDirectionVector3.X, 0, FacingDirectionVector3.Z)
	if FlatFacingDirectionVector3.Magnitude <= 0.001 then
		return MuzzleOriginVector3, HeadPositionVector3
	end

	local CurrentRootCFrame = RootPartInstance.CFrame
	local CandidateRootCFrame = CFrame.new(RootPartInstance.Position, RootPartInstance.Position + FlatFacingDirectionVector3.Unit)
	local MuzzleLocalOffsetVector3 = CurrentRootCFrame:PointToObjectSpace(MuzzleOriginVector3)
	local HeadLocalOffsetVector3 = CurrentRootCFrame:PointToObjectSpace(HeadPositionVector3)
	return CandidateRootCFrame:PointToWorldSpace(MuzzleLocalOffsetVector3), CandidateRootCFrame:PointToWorldSpace(HeadLocalOffsetVector3)
end

function GetPointToRayDistance(PointVector3, OriginVector3, DirectionVector3)
	if typeof(PointVector3) ~= "Vector3"
		or typeof(OriginVector3) ~= "Vector3"
		or typeof(DirectionVector3) ~= "Vector3"
		or DirectionVector3.Magnitude <= 0.001 then
		return math.huge, -math.huge
	end

	local DirectionUnitVector3 = DirectionVector3.Unit
	local OffsetVector3 = PointVector3 - OriginVector3
	local AlongNumber = OffsetVector3:Dot(DirectionUnitVector3)
	if AlongNumber <= 0 then
		return OffsetVector3.Magnitude, AlongNumber
	end

	local ClosestPointVector3 = OriginVector3 + DirectionUnitVector3 * AlongNumber
	return (PointVector3 - ClosestPointVector3).Magnitude, AlongNumber
end

IsRaycastResultTargetHit = function(RaycastResult, TargetCharacterModel)
	local HitInstance = RaycastResult and RaycastResult.Instance or nil
	if not TargetCharacterModel or not HitInstance or not HitInstance.IsDescendantOf then
		return false
	end

	return HitInstance.IsDescendantOf(HitInstance, TargetCharacterModel)
end

local InternalAimbotRaycastBypassDepth = 0

RunUnredirectedWorkspaceRaycast = function(OriginVector3, DirectionVector3, RaycastParamsObject)
	InternalAimbotRaycastBypassDepth = InternalAimbotRaycastBypassDepth + 1
	local ResultTable = table.pack(pcall(WorkspaceService.Raycast, WorkspaceService, OriginVector3, DirectionVector3, RaycastParamsObject))
	InternalAimbotRaycastBypassDepth = math.max(InternalAimbotRaycastBypassDepth - 1, 0)
	if not ResultTable[1] then
		error(ResultTable[2], 0)
	end

	return ResultTable[2]
end

function GetSkyAimAlignmentTolerance(TargetPartInstance)
	local ToleranceNumber = 1.25
	if TargetPartInstance and TargetPartInstance.Size then
		local PartRadiusNumber = math.max(TargetPartInstance.Size.X, math.max(TargetPartInstance.Size.Y, TargetPartInstance.Size.Z)) * 0.6
		ToleranceNumber = math.max(ToleranceNumber, PartRadiusNumber)
	end

	return math.clamp(ToleranceNumber, 1.25, 4.5)
end

function ResolveSkyAimSolution(LocalCharacterModel, ReferenceDirectionVector3, EquippedTool, TargetPositionVector3, TargetCharacterModel, TargetPartInstance, SkipCacheBoolean, RequiredPriorityNumber)
	if not IsSillyModeBehaviorActive() or not ShieldModeRuntimeTable.IsSkyAimActive() then
		return nil
	end

	if not LocalCharacterModel
		or not LocalCharacterModel.Parent
		or (not EquippedTool and not HasEquippedTool(LocalCharacterModel)) then
		return nil
	end

	local HumanoidInstance = GetCharacterHumanoid(LocalCharacterModel)
	local RootPartInstance = GetCharacterRootPart(LocalCharacterModel)
	local HeadPartInstance = GetCharacterHeadPart(LocalCharacterModel)
	if not HumanoidInstance
		or not RootPartInstance
		or not HeadPartInstance
		or (tonumber(HumanoidInstance.Health) or 0) <= 0 then
		return nil
	end

	if typeof(TargetPositionVector3) ~= "Vector3" and not TargetCharacterModel and not TargetPartInstance then
		TargetPositionVector3, TargetCharacterModel, TargetPartInstance = ResolveCurrentSkyTargetData()
	end
	local BaseFlatDirectionVector3 = GetFallbackFlatAimDirectionVector3(LocalCharacterModel, ReferenceDirectionVector3, TargetPositionVector3)
	local FallbackSolutionTable = BuildFallbackSkyAimSolution(LocalCharacterModel, ReferenceDirectionVector3, TargetPositionVector3)
	if typeof(TargetPositionVector3) ~= "Vector3" then
		return FallbackSolutionTable
	end

	local HeadPositionVector3 = HeadPartInstance.Position
	local MuzzleOriginVector3 = ShieldModeRuntimeTable.GetCurrentLocalGunMuzzleOrigin
		and ShieldModeRuntimeTable.GetCurrentLocalGunMuzzleOrigin(LocalCharacterModel) or nil
	if typeof(MuzzleOriginVector3) ~= "Vector3" then
		MuzzleOriginVector3 = HeadPositionVector3
	end
	local CurrentLocalGunRaycastParamsObject = ShieldModeRuntimeTable.GetCurrentLocalGunRaycastParams
		and ShieldModeRuntimeTable.GetCurrentLocalGunRaycastParams(LocalCharacterModel) or nil
	local CurrentLocalGunCheckParamsObject = ShieldModeRuntimeTable.GetCurrentLocalGunCheckParams
		and ShieldModeRuntimeTable.GetCurrentLocalGunCheckParams(LocalCharacterModel) or nil
	local CandidateLockDurationNumber = math.max(tonumber(SkyAimCandidateLockDurationNumber) or 0, 0)
	if not SkipCacheBoolean then
		local CachedSolutionTable = ShieldModeRuntimeTable.skyAimSolutionCache
		local CachedSolutionValue = CachedSolutionTable and CachedSolutionTable.solution or nil
		if CachedSolutionValue
			and not CachedSolutionValue.isFallback
			and (CachedSolutionValue.priority or 0) >= 3
			and CandidateLockDurationNumber > 0
			and (tick() - (CachedSolutionTable.time or 0)) < CandidateLockDurationNumber
			and CachedSolutionTable.localCharacter == LocalCharacterModel
			and CachedSolutionTable.targetCharacter == TargetCharacterModel
			and CachedSolutionTable.targetPart == TargetPartInstance
			and CachedSolutionTable.equippedTool == EquippedTool
			and CurrentLocalGunRaycastParamsObject
			and typeof(CachedSolutionValue.muzzleOrigin) == "Vector3" then
			local CachedTargetOffsetVector3 = TargetPositionVector3 - CachedSolutionValue.muzzleOrigin
			if CachedTargetOffsetVector3.Magnitude > 0.001 then
				local CachedLockRaycastResult = RunUnredirectedWorkspaceRaycast(
					CachedSolutionValue.muzzleOrigin,
					CachedTargetOffsetVector3.Unit * math.max(CachedTargetOffsetVector3.Magnitude + 6, 12),
					CurrentLocalGunRaycastParamsObject
				)
				if IsRaycastResultTargetHit(CachedLockRaycastResult, TargetCharacterModel) then
					return CachedSolutionValue
				end
			end
		end
		local CachedSolutionCanBeReusedBoolean = true
		if CachedSolutionValue then
			local CachedPriorityNumber = CachedSolutionValue.priority or 0
			if CachedPriorityNumber < 2 then
				CachedSolutionCanBeReusedBoolean = false
			elseif TargetCharacterModel then
				CachedSolutionCanBeReusedBoolean = false
				local CachedMuzzleOriginVector3 = CachedSolutionValue.muzzleOrigin or CachedSolutionTable.muzzleOrigin
				local CachedDirectionVector3 = CachedSolutionValue.direction
				local CachedTargetDirectionVector3 = CachedSolutionValue.targetDirection or CachedDirectionVector3
				if typeof(CachedMuzzleOriginVector3) == "Vector3"
					and typeof(CachedTargetDirectionVector3) == "Vector3"
					and CachedTargetDirectionVector3.Magnitude > 0.001 then
					if CachedPriorityNumber >= 3 and CurrentLocalGunRaycastParamsObject then
						local CachedTargetDistanceNumber = (TargetPositionVector3 - CachedMuzzleOriginVector3).Magnitude
						if CachedTargetDistanceNumber > 0.001 then
							local CachedRaycastResult = RunUnredirectedWorkspaceRaycast(
								CachedMuzzleOriginVector3,
								CachedTargetDirectionVector3.Unit * math.max(CachedTargetDistanceNumber + 6, 12),
								CurrentLocalGunRaycastParamsObject
							)
							CachedSolutionCanBeReusedBoolean = IsRaycastResultTargetHit(CachedRaycastResult, TargetCharacterModel)
						end
					elseif CachedPriorityNumber >= 2
						and CachedSolutionValue.headPosition
						and CurrentLocalGunCheckParamsObject then
							local CachedHeadRaycastResult = RunUnredirectedWorkspaceRaycast(
								CachedSolutionValue.headPosition,
								CachedDirectionVector3.Unit * 3.5,
								CurrentLocalGunCheckParamsObject
							)
							CachedSolutionCanBeReusedBoolean = CachedHeadRaycastResult == nil
						end
					end
				end
			end
			if CachedSolutionTable
				and CachedSolutionCanBeReusedBoolean
				and (tick() - (CachedSolutionTable.time or 0)) < SkyAimSolutionCacheDurationNumber
				and CachedSolutionTable.localCharacter == LocalCharacterModel
				and CachedSolutionTable.targetCharacter == TargetCharacterModel
				and CachedSolutionTable.targetPart == TargetPartInstance
				and typeof(CachedSolutionTable.targetPosition) == "Vector3"
				and (CachedSolutionTable.targetPosition - TargetPositionVector3).Magnitude <= 0.05
				and typeof(CachedSolutionTable.muzzleOrigin) == "Vector3"
				and (CachedSolutionTable.muzzleOrigin - MuzzleOriginVector3).Magnitude <= 0.05
				and typeof(CachedSolutionTable.headPosition) == "Vector3"
				and (CachedSolutionTable.headPosition - HeadPositionVector3).Magnitude <= 0.05 then
			return CachedSolutionTable.solution
		end
	end

	local TargetDistanceNumber = (TargetPositionVector3 - MuzzleOriginVector3).Magnitude
	local AlignmentToleranceNumber = GetSkyAimAlignmentTolerance(TargetPartInstance)
	local BestSolutionTable = nil
	local BestApproximateSolutionTable = nil
	local PreviousCandidateSolutionTable = nil
	local PreviousSkyAimCacheTable = ShieldModeRuntimeTable.skyAimSolutionCache
	local PreviousSkyAimSolutionTable = PreviousSkyAimCacheTable and PreviousSkyAimCacheTable.solution or nil
	if PreviousSkyAimSolutionTable
		and not PreviousSkyAimSolutionTable.isFallback
		and type(PreviousSkyAimSolutionTable.yaw) == "number"
		and type(PreviousSkyAimSolutionTable.pitch) == "number"
		and CandidateLockDurationNumber > 0
		and (tick() - (PreviousSkyAimCacheTable.time or 0)) < CandidateLockDurationNumber
		and PreviousSkyAimCacheTable.localCharacter == LocalCharacterModel
		and PreviousSkyAimCacheTable.targetCharacter == TargetCharacterModel
		and PreviousSkyAimCacheTable.targetPart == TargetPartInstance
		and PreviousSkyAimCacheTable.equippedTool == EquippedTool then
		PreviousCandidateSolutionTable = PreviousSkyAimSolutionTable
	end

	if RequiredPriorityNumber and RequiredPriorityNumber >= 3 and (not CurrentLocalGunRaycastParamsObject or TargetDistanceNumber <= 0.001) then
		return nil
	end

	local function ConsiderCandidate(CandidateDirectionVector3, CandidateFacingDirectionVector3, CandidateMuzzleOriginVector3, CandidateHeadPositionVector3, PitchDegreeNumber, YawDegreeNumber)
		local CandidateTargetOffsetVector3 = TargetPositionVector3 - CandidateMuzzleOriginVector3
		local CandidateHeadTargetOffsetVector3 = TargetPositionVector3 - CandidateHeadPositionVector3
		if CandidateTargetOffsetVector3.Magnitude <= 0.001 or CandidateHeadTargetOffsetVector3.Magnitude <= 0.001 then
			return
		end

		local CandidateTargetDirectionVector3 = CandidateTargetOffsetVector3.Unit
		local CandidateHeadTargetDirectionVector3 = CandidateHeadTargetOffsetVector3.Unit
		local MuzzleMissDistanceNumber, MuzzleAlongNumber = GetPointToRayDistance(
			TargetPositionVector3,
			CandidateMuzzleOriginVector3,
			CandidateTargetDirectionVector3
		)
		local HeadMissDistanceNumber, HeadAlongNumber = GetPointToRayDistance(
			TargetPositionVector3,
			CandidateHeadPositionVector3,
			CandidateHeadTargetDirectionVector3
		)
		local MissDistanceNumber = math.min(MuzzleMissDistanceNumber, HeadMissDistanceNumber)
		local AlongNumber = math.max(MuzzleAlongNumber, HeadAlongNumber)
		if AlongNumber <= 0 then
			return
		end

		local FlatFacingDirectionVector3 = Vector3.new(CandidateFacingDirectionVector3.X, 0, CandidateFacingDirectionVector3.Z)
		if FlatFacingDirectionVector3.Magnitude <= 0.001 then
			FlatFacingDirectionVector3 = BaseFlatDirectionVector3
		else
			FlatFacingDirectionVector3 = FlatFacingDirectionVector3.Unit
		end

		local AbsoluteYawNumber = math.abs(YawDegreeNumber)
		local PitchDistanceNumber = AbsoluteYawNumber > 0.001
			and math.abs(PitchDegreeNumber)
			or math.abs(PitchDegreeNumber - SkyAimPreferredPitchDegreesNumber)
		local CandidateSolutionTable = {
			direction = CandidateDirectionVector3,
			targetDirection = CandidateTargetDirectionVector3,
			muzzleOrigin = CandidateMuzzleOriginVector3,
			headPosition = CandidateHeadPositionVector3,
			hitPosition = CandidateMuzzleOriginVector3 + CandidateDirectionVector3 * SkyAimHitDistanceNumber,
			facingDirection = FlatFacingDirectionVector3,
			missDistance = MissDistanceNumber,
			upward = CandidateDirectionVector3.Y,
			yaw = YawDegreeNumber,
			yawAbs = AbsoluteYawNumber,
			pitch = PitchDegreeNumber,
			pitchDistance = PitchDistanceNumber,
			priority = 0,
		}

		if not BestApproximateSolutionTable
			or MissDistanceNumber < (BestApproximateSolutionTable.missDistance - 0.01)
			or (math.abs(MissDistanceNumber - BestApproximateSolutionTable.missDistance) <= 0.01
				and PitchDistanceNumber < ((BestApproximateSolutionTable.pitchDistance or math.huge) - 0.01))
			or (math.abs(MissDistanceNumber - BestApproximateSolutionTable.missDistance) <= 0.01
				and math.abs(PitchDistanceNumber - (BestApproximateSolutionTable.pitchDistance or math.huge)) <= 0.01
				and CandidateDirectionVector3.Y > (BestApproximateSolutionTable.upward or -math.huge)) then
			BestApproximateSolutionTable = CandidateSolutionTable
		end

		if MissDistanceNumber > (AlignmentToleranceNumber * 2.5) then
			return
		end

		local DirectHitBoolean = false
		local CandidateTargetDistanceNumber = (TargetPositionVector3 - CandidateMuzzleOriginVector3).Magnitude
		if CurrentLocalGunRaycastParamsObject and CandidateTargetDistanceNumber > 0.001 then
			local RaycastDistanceNumber = math.max(CandidateTargetDistanceNumber + 6, 12)
			local RaycastResult = RunUnredirectedWorkspaceRaycast(
				CandidateMuzzleOriginVector3,
				CandidateTargetDirectionVector3 * RaycastDistanceNumber,
				CurrentLocalGunRaycastParamsObject
			)
			DirectHitBoolean = IsRaycastResultTargetHit(RaycastResult, TargetCharacterModel)
		end

		if RequiredPriorityNumber and RequiredPriorityNumber >= 3 and not DirectHitBoolean then
			return
		end

		local HeadClearBoolean = true
		if CurrentLocalGunCheckParamsObject and (DirectHitBoolean or not RequiredPriorityNumber or RequiredPriorityNumber < 3) then
			HeadClearBoolean = RunUnredirectedWorkspaceRaycast(
				CandidateHeadPositionVector3,
				CandidateDirectionVector3 * 3.5,
				CurrentLocalGunCheckParamsObject
			) == nil
		end

		if DirectHitBoolean and HeadClearBoolean then
			CandidateSolutionTable.priority = 4
		elseif DirectHitBoolean then
			CandidateSolutionTable.priority = 3
		elseif HeadClearBoolean and MissDistanceNumber <= AlignmentToleranceNumber then
			CandidateSolutionTable.priority = 2
		elseif MissDistanceNumber <= AlignmentToleranceNumber then
			CandidateSolutionTable.priority = 1
		end

		local KeepPreviousDirectCandidateBoolean = PreviousCandidateSolutionTable
			and BestSolutionTable
			and (PreviousCandidateSolutionTable.priority or 0) >= 3
			and CandidateSolutionTable.priority >= 3
			and BestSolutionTable.priority >= 3
		if KeepPreviousDirectCandidateBoolean then
			local CandidateYawChangeNumber = math.abs(CandidateSolutionTable.yaw - PreviousCandidateSolutionTable.yaw)
			local BestYawChangeNumber = math.abs(BestSolutionTable.yaw - PreviousCandidateSolutionTable.yaw)
			if CandidateYawChangeNumber < (BestYawChangeNumber - 0.01) then
				BestSolutionTable = CandidateSolutionTable
			elseif CandidateYawChangeNumber > (BestYawChangeNumber + 0.01) then
				return false
			end
		end

		local CandidateDirectHitBoolean = CandidateSolutionTable.priority >= 3
		local BestDirectHitBoolean = BestSolutionTable and (BestSolutionTable.priority or 0) >= 3
		local ShouldReplaceBestBoolean = not BestSolutionTable
		if not ShouldReplaceBestBoolean then
			if CandidateDirectHitBoolean ~= BestDirectHitBoolean then
				ShouldReplaceBestBoolean = CandidateDirectHitBoolean
			elseif not CandidateDirectHitBoolean and CandidateSolutionTable.priority ~= BestSolutionTable.priority then
				ShouldReplaceBestBoolean = CandidateSolutionTable.priority > BestSolutionTable.priority
			elseif PitchDistanceNumber < ((BestSolutionTable.pitchDistance or math.huge) - 0.01) then
				ShouldReplaceBestBoolean = true
			elseif math.abs(PitchDistanceNumber - (BestSolutionTable.pitchDistance or math.huge)) <= 0.01
				and CandidateDirectionVector3.Y > ((BestSolutionTable.upward or -math.huge) + 0.001) then
				ShouldReplaceBestBoolean = true
			elseif math.abs(PitchDistanceNumber - (BestSolutionTable.pitchDistance or math.huge)) <= 0.01
				and math.abs(CandidateDirectionVector3.Y - (BestSolutionTable.upward or -math.huge)) <= 0.001
				and MissDistanceNumber < ((BestSolutionTable.missDistance or math.huge) - 0.01) then
				ShouldReplaceBestBoolean = true
			elseif math.abs(PitchDistanceNumber - (BestSolutionTable.pitchDistance or math.huge)) <= 0.01
				and math.abs(CandidateDirectionVector3.Y - (BestSolutionTable.upward or -math.huge)) <= 0.001
				and math.abs(MissDistanceNumber - (BestSolutionTable.missDistance or math.huge)) <= 0.01
				and AbsoluteYawNumber < (BestSolutionTable.yawAbs or math.huge) then
				ShouldReplaceBestBoolean = true
			end
		end
		if ShouldReplaceBestBoolean then
			BestSolutionTable = CandidateSolutionTable
		end

		if RequiredPriorityNumber and CandidateSolutionTable.priority >= RequiredPriorityNumber then
			return true
		end

		return false
	end

	for _, PitchGroupTable in ipairs(GetSkyAimCandidateGroups(RequiredPriorityNumber)) do
		for _, YawEntryTable in ipairs(PitchGroupTable.yaws) do
			local CandidateFacingDirectionVector3 = BuildSkyAimCandidateFacingDirection(
				BaseFlatDirectionVector3,
				YawEntryTable.rotation
			)
			local CandidateMuzzleOriginVector3, CandidateHeadPositionVector3 = ResolveSkyAimCandidatePose(
				RootPartInstance,
				HeadPositionVector3,
				MuzzleOriginVector3,
				CandidateFacingDirectionVector3
			)
			local CandidateDirectionVector3 = BuildSkyAimCandidateDirection(
				CandidateFacingDirectionVector3,
				PitchGroupTable.sinPitch,
				PitchGroupTable.cosPitch
			)
			if CandidateDirectionVector3 then
				if ConsiderCandidate(
					CandidateDirectionVector3,
					CandidateFacingDirectionVector3,
					CandidateMuzzleOriginVector3,
					CandidateHeadPositionVector3,
					PitchGroupTable.pitch,
					YawEntryTable.yaw
				) then
					break
				end
			end
		end

		if BestSolutionTable
			and (
				((BestSolutionTable.priority or 0) >= 4 and (BestSolutionTable.yawAbs or 0) <= 0.001)
				or (RequiredPriorityNumber and (BestSolutionTable.priority or 0) >= RequiredPriorityNumber)
			) then
			break
		end
	end

	local FinalSolutionTable = BestSolutionTable
	if FinalSolutionTable and (FinalSolutionTable.priority or 0) < 2 then
		FinalSolutionTable = nil
	end

	if RequiredPriorityNumber and RequiredPriorityNumber >= 3 then
		if not FinalSolutionTable or (FinalSolutionTable.priority or -math.huge) < RequiredPriorityNumber then
			return nil
		end
		return FinalSolutionTable
	end

	if not FinalSolutionTable then
		if BestApproximateSolutionTable
			and (BestApproximateSolutionTable.priority or 0) > 0
			and (BestApproximateSolutionTable.missDistance or math.huge) <= (AlignmentToleranceNumber * 4) then
			FinalSolutionTable = BestApproximateSolutionTable
		else
			FinalSolutionTable = FallbackSolutionTable
		end
	end

	if FinalSolutionTable then
		if TraceModeEnabledBoolean then
			TraceLog(
				"sky-aim-final",
				"pitch=" .. tostring(FinalSolutionTable.pitch)
					.. " | yaw=" .. tostring(FinalSolutionTable.yaw or 0)
					.. " | priority=" .. tostring(FinalSolutionTable.priority)
					.. " | miss=" .. string.format("%.2f", FinalSolutionTable.missDistance or -1)
					.. " | facing=" .. FormatDebugVector3(FinalSolutionTable.facingDirection)
					.. " | dir=" .. FormatDebugVector3(FinalSolutionTable.direction),
				false
			)
		end
	end

	if not SkipCacheBoolean then
		ShieldModeRuntimeTable.skyAimSolutionCache = {
			time = tick(),
			localCharacter = LocalCharacterModel,
			targetCharacter = TargetCharacterModel,
			targetPart = TargetPartInstance,
			targetPosition = TargetPositionVector3,
			muzzleOrigin = MuzzleOriginVector3,
			headPosition = HeadPositionVector3,
			equippedTool = EquippedTool,
			solution = FinalSolutionTable,
		}
	end
	return FinalSolutionTable
end


function ShieldModeRuntimeTable.ResetState()
	ShieldModeRuntimeTable.SetReloadSuppressionEnabled(false)
	ShieldModeRuntimeTable.nextShotTime = 0
	ShieldModeRuntimeTable.pendingReequipTime = 0
	ShieldModeRuntimeTable.secondaryReadyTime = 0
	ShieldModeRuntimeTable.reloadHoldUntilTime = 0
	ShieldModeRuntimeTable.reloadObserved = false
	ShieldModeRuntimeTable.reloadDeferredForThreat = false
	ShieldModeRuntimeTable.reloadResumeUntilTime = 0
	ShieldModeRuntimeTable.lastThreatScanTime = 0
	ShieldModeRuntimeTable.cachedThreatData = nil
	ShieldModeRuntimeTable.cachedAimingThreatData = nil
	ShieldModeRuntimeTable.cachedThreatScanCharacter = nil
	ShieldModeRuntimeTable.cachedThreatScanFrameId = 0
	ShieldModeRuntimeTable.skyAimSolutionCache = nil
	ShieldModeRuntimeTable.shotSkyAimDataCache = nil
	ShieldModeRuntimeTable.forcedBodyRotationCFrame = nil
	ShieldModeRuntimeTable.lastEquipAttemptTime = 0
end

function ShieldModeRuntimeTable.GetLocalPlayerBackpack()
	return LocalPlayer and LocalPlayer.FindFirstChild(LocalPlayer, "Backpack") or nil
end

function ShieldModeRuntimeTable.GetEquippedTool(CharacterModel)
	if not CharacterModel then
		return nil
	end

	for _, ChildInstance in ipairs(CharacterModel.GetChildren(CharacterModel)) do
		if ChildInstance.IsA(ChildInstance, "Tool") then
			return ChildInstance
		end
	end

	return nil
end

function ShieldModeRuntimeTable.FindToolByNameInContainer(ContainerInstance, ToolNameString)
	if not ContainerInstance or type(ToolNameString) ~= "string" or ToolNameString == "" then
		return nil
	end

	for _, ChildInstance in ipairs(ContainerInstance.GetChildren(ContainerInstance)) do
		if ChildInstance.IsA(ChildInstance, "Tool") and ChildInstance.Name == ToolNameString then
			return ChildInstance
		end
	end

	return nil
end

function ShieldModeRuntimeTable.GetToolServiceName(ToolInstance)
	if not ToolInstance or not ToolInstance.GetAttribute then
		return nil
	end

	local ServiceNameString = ToolInstance.GetAttribute(ToolInstance, "Service")
	if type(ServiceNameString) == "string" and ServiceNameString ~= "" then
		return ServiceNameString
	end

	return nil
end

function ShieldModeRuntimeTable.IsToolReloading(ToolInstance)
	if not ToolInstance or not ToolInstance.GetAttribute then
		return false
	end

	return ToolInstance.GetAttribute(ToolInstance, "Reloading") == true
end

function ShieldModeRuntimeTable.FindLocalToolByName(CharacterModel, ToolNameString)
	return ShieldModeRuntimeTable.FindToolByNameInContainer(CharacterModel, ToolNameString)
		or ShieldModeRuntimeTable.FindToolByNameInContainer(ShieldModeRuntimeTable.GetLocalPlayerBackpack(), ToolNameString)
end

function ShieldModeRuntimeTable.GetLocalMetalShieldTool(CharacterModel)
	local DirectShieldTool = ShieldModeRuntimeTable.FindLocalToolByName(CharacterModel, "Metal Shield")
	if DirectShieldTool then
		return DirectShieldTool
	end

	local HeldItemStateTable = ShieldModeRuntimeTable.GetBloodZoneHeldItemState
		and ShieldModeRuntimeTable.GetBloodZoneHeldItemState(CharacterModel) or nil
	return HeldItemStateTable and HeldItemStateTable.shieldInstance or nil
end

function ShieldModeRuntimeTable.GetLocalSettings()
	return LocalPlayer and LocalPlayer.FindFirstChild(LocalPlayer, "Settings") or nil
end

function ShieldModeRuntimeTable.SetReloadSuppressionEnabled(EnabledBoolean)
	local SettingsInstance = ShieldModeRuntimeTable.GetLocalSettings()
	if not SettingsInstance or not SettingsInstance.GetAttribute or not SettingsInstance.SetAttribute then
		return
	end

	if EnabledBoolean then
		if not ShieldModeRuntimeTable.reloadSuppressionActive then
			ShieldModeRuntimeTable.savedAutoReloadSetting = SettingsInstance.GetAttribute(SettingsInstance, "AutoReload")
			ShieldModeRuntimeTable.savedCancelReloadingSetting = SettingsInstance.GetAttribute(SettingsInstance, "CancelReloading")
			ShieldModeRuntimeTable.reloadSuppressionActive = true
		end

		if SettingsInstance.GetAttribute(SettingsInstance, "AutoReload") ~= false then
			SettingsInstance.SetAttribute(SettingsInstance, "AutoReload", false)
		end
		if SettingsInstance.GetAttribute(SettingsInstance, "CancelReloading") ~= true then
			SettingsInstance.SetAttribute(SettingsInstance, "CancelReloading", true)
		end
		return
	end

	if not ShieldModeRuntimeTable.reloadSuppressionActive then
		return
	end

	local SavedAutoReloadSetting = ShieldModeRuntimeTable.savedAutoReloadSetting
	if SavedAutoReloadSetting ~= nil and SettingsInstance.GetAttribute(SettingsInstance, "AutoReload") ~= SavedAutoReloadSetting then
		SettingsInstance.SetAttribute(SettingsInstance, "AutoReload", SavedAutoReloadSetting)
	end

	local SavedCancelReloadingSetting = ShieldModeRuntimeTable.savedCancelReloadingSetting
	if SavedCancelReloadingSetting ~= nil and SettingsInstance.GetAttribute(SettingsInstance, "CancelReloading") ~= SavedCancelReloadingSetting then
		SettingsInstance.SetAttribute(SettingsInstance, "CancelReloading", SavedCancelReloadingSetting)
	end

	ShieldModeRuntimeTable.reloadSuppressionActive = false
	ShieldModeRuntimeTable.savedAutoReloadSetting = nil
	ShieldModeRuntimeTable.savedCancelReloadingSetting = nil
end

function ShieldModeRuntimeTable.GetGunCursorAmmoRotation()
	local PlayerGui = LocalPlayer and LocalPlayer.FindFirstChild(LocalPlayer, "PlayerGui") or nil
	local GunCursor = PlayerGui and PlayerGui.FindFirstChild(PlayerGui, "GunCursor") or nil
	local AmmoImage = GunCursor and GunCursor.FindFirstChild(GunCursor, "Ammo") or nil
	local GradientInstance = AmmoImage and AmmoImage.FindFirstChild(AmmoImage, "UIGradient") or nil
	if not GradientInstance then
		return nil
	end

	return tonumber(GradientInstance.Rotation)
end

function ShieldModeRuntimeTable.IsCurrentGunAmmoEmpty()
	local AmmoRotationNumber = ShieldModeRuntimeTable.GetGunCursorAmmoRotation()
	return type(AmmoRotationNumber) == "number" and AmmoRotationNumber >= 134.5
end

function ShieldModeRuntimeTable.IsPersistentSillySkyAimActive()
	return IsSillyModeBehaviorActive() and SillySkyAimEnabledBoolean and not ShieldModeEnabledBoolean
end

function ShieldModeRuntimeTable.IsSkyAimActive()
	return ShieldModeRuntimeTable.IsPersistentSillySkyAimActive()
end

function GetFlatFacingDirectionVector3(DirectionVector3)
	if typeof(DirectionVector3) ~= "Vector3" then
		return nil
	end

	local FlatDirectionVector3 = Vector3.new(DirectionVector3.X, 0, DirectionVector3.Z)
	if FlatDirectionVector3.Magnitude <= 0.001 then
		return nil
	end

	return FlatDirectionVector3.Unit
end

function AreCloseVector3Values(LeftVector3, RightVector3, ToleranceNumber)
	if typeof(LeftVector3) ~= "Vector3" or typeof(RightVector3) ~= "Vector3" then
		return LeftVector3 == RightVector3
	end

	return (LeftVector3 - RightVector3).Magnitude <= (ToleranceNumber or 0.05)
end

function ResolveShotSkyAimDataTable(LocalCharacterModel, ReferenceDirectionVector3, EquippedTool)
	if not IsSillyModeBehaviorActive() then
		return nil
	end

	if not LocalCharacterModel or not LocalCharacterModel.Parent or (not EquippedTool and not HasEquippedTool(LocalCharacterModel)) then
		return nil
	end

	if not ShieldModeRuntimeTable.IsSkyAimActive() then
		return nil
	end

	local WeaponBallisticsProfileTable = CurrentWeaponBallisticsProfileTable
		or ShieldModeRuntimeTable.ResolveCurrentWeaponBallisticsProfile(LocalCharacterModel)
	local FrameIdNumber = tonumber(CurrentFrameSequenceNumber) or 0
	local TargetCharacterModel = CurrentTargetCharacterModel and CurrentTargetCharacterModel.Parent and CurrentTargetCharacterModel or nil
	local TargetPartInstance = CurrentTargetPartInstance and CurrentTargetPartInstance.Parent and CurrentTargetPartInstance or nil
	local AimPointVector3 = GetCurrentEffectiveAimPointVector3()
	if typeof(AimPointVector3) ~= "Vector3" and TargetPartInstance then
		AimPointVector3 = TargetPartInstance.Position
	end

	local CachedShotSkyAimDataTable = ShieldModeRuntimeTable.shotSkyAimDataCache
	if CachedShotSkyAimDataTable
		and CachedShotSkyAimDataTable.frameId == FrameIdNumber
		and CachedShotSkyAimDataTable.localCharacter == LocalCharacterModel
		and CachedShotSkyAimDataTable.weaponProfile == WeaponBallisticsProfileTable
		and CachedShotSkyAimDataTable.targetCharacter == TargetCharacterModel
		and CachedShotSkyAimDataTable.targetPart == TargetPartInstance
		and AreCloseVector3Values(CachedShotSkyAimDataTable.targetPoint, AimPointVector3, 0.05)
		and AreCloseVector3Values(CachedShotSkyAimDataTable.referenceDirection, ReferenceDirectionVector3, 0.01) then
		return CachedShotSkyAimDataTable.data
	end

	local function FinalizeShotSkyAimData(ShotSkyAimDataTable)
		ShieldModeRuntimeTable.shotSkyAimDataCache = {
			frameId = FrameIdNumber,
			localCharacter = LocalCharacterModel,
			weaponProfile = WeaponBallisticsProfileTable,
			targetCharacter = TargetCharacterModel,
			targetPart = TargetPartInstance,
			targetPoint = AimPointVector3,
			referenceDirection = ReferenceDirectionVector3,
			data = ShotSkyAimDataTable,
		}
		return ShotSkyAimDataTable
	end

	if ShieldModeRuntimeTable.IsProjectileWeaponProfile(WeaponBallisticsProfileTable) then
		local AimOriginVector3 = ResolveWeaponAimOriginVector3(LocalCharacterModel, WeaponBallisticsProfileTable)
		if typeof(AimOriginVector3) == "Vector3" and typeof(AimPointVector3) == "Vector3" then
			local DirectionVector3 = AimPointVector3 - AimOriginVector3
			if DirectionVector3.Magnitude > 0.001 then
				return FinalizeShotSkyAimData({
					direction = DirectionVector3.Unit,
					facingDirection = GetFlatFacingDirectionVector3(DirectionVector3),
				})
			end
		end

		return FinalizeShotSkyAimData(nil)
	end

	local SkyAimSolutionTable = ResolveSkyAimSolution(
		LocalCharacterModel,
		ReferenceDirectionVector3,
		EquippedTool,
		AimPointVector3,
		TargetCharacterModel,
		TargetPartInstance
	)
	if not SkyAimSolutionTable then
		return FinalizeShotSkyAimData(nil)
	end

	local FacingDirectionVector3 = SkyAimSolutionTable.facingDirection
	if typeof(FacingDirectionVector3) ~= "Vector3" then
		FacingDirectionVector3 = GetFlatFacingDirectionVector3(SkyAimSolutionTable.direction)
	end

	return FinalizeShotSkyAimData({
		direction = SkyAimSolutionTable.direction,
		facingDirection = FacingDirectionVector3,
		hitPosition = (SkyAimSolutionTable.priority or -1) >= 3 and SkyAimSolutionTable.hitPosition or nil,
		priority = SkyAimSolutionTable.priority,
	})
end

function ShieldModeRuntimeTable.GetShotSkyHitPosition()
	if not IsSillyModeBehaviorActive() then
		return nil
	end

	if not ShieldModeRuntimeTable.IsSkyAimActive() then
		return nil
	end

	local LocalCharacterModel = CurrentFrameLocalCharacterModel
	local LocalCharacterReadyBoolean = CurrentFrameLocalCharacterReadyBoolean
	if not LocalCharacterReadyBoolean or not LocalCharacterModel or not LocalCharacterModel.Parent then
		LocalCharacterModel = ResolveCharacterModelForPlayer(LocalPlayer)
		LocalCharacterReadyBoolean = IsLocalCharacterReadyForAimbot(LocalCharacterModel)
	end
	if not LocalCharacterReadyBoolean then
		return nil
	end

	local EquippedTool = ShieldModeRuntimeTable.GetEquippedTool(LocalCharacterModel)
	if not EquippedTool and not HasEquippedTool(LocalCharacterModel) then
		return nil
	end

	local ShotSkyAimDataTable = ResolveShotSkyAimDataTable(LocalCharacterModel, nil, EquippedTool)
	return ShotSkyAimDataTable and ShotSkyAimDataTable.hitPosition or nil
end

function ShieldModeRuntimeTable.GetShotSkyAimDirection(LocalCharacterModel, ReferenceDirectionVector3, EquippedTool)
	if not IsSillyModeBehaviorActive() then
		return nil
	end

	if not LocalCharacterModel or not LocalCharacterModel.Parent or (not EquippedTool and not HasEquippedTool(LocalCharacterModel)) then
		return nil
	end

	local HumanoidInstance = GetCharacterHumanoid(LocalCharacterModel)
	local RootPartInstance = GetCharacterRootPart(LocalCharacterModel)
	if not HumanoidInstance or not RootPartInstance or (tonumber(HumanoidInstance.Health) or 0) <= 0 then
		return nil
	end

	local ShotSkyAimDataTable = ResolveShotSkyAimDataTable(LocalCharacterModel, ReferenceDirectionVector3, EquippedTool)
	return ShotSkyAimDataTable and ShotSkyAimDataTable.direction or nil
end

function ShieldModeRuntimeTable.GetShotSkyFacingDirection(LocalCharacterModel, ReferenceDirectionVector3, EquippedTool)
	if not IsSillyModeBehaviorActive() then
		return nil
	end

	if not LocalCharacterModel or not LocalCharacterModel.Parent or (not EquippedTool and not HasEquippedTool(LocalCharacterModel)) then
		return nil
	end

	local HumanoidInstance = GetCharacterHumanoid(LocalCharacterModel)
	local RootPartInstance = GetCharacterRootPart(LocalCharacterModel)
	if not HumanoidInstance or not RootPartInstance or (tonumber(HumanoidInstance.Health) or 0) <= 0 then
		return nil
	end

	local ShotSkyAimDataTable = ResolveShotSkyAimDataTable(LocalCharacterModel, ReferenceDirectionVector3, EquippedTool)
	return ShotSkyAimDataTable and ShotSkyAimDataTable.facingDirection or nil
end

function ShieldModeRuntimeTable.ResolveCursorModule()
	if not IsBloodZonePlaceBoolean then
		return nil
	end

	if ShieldModeRuntimeTable.cursorModule then
		return ShieldModeRuntimeTable.cursorModule
	end

	local ModulesFolder = ReplicatedStorageService and ReplicatedStorageService.FindFirstChild(ReplicatedStorageService, "Modules") or nil
	local ClientFolder = ModulesFolder and ModulesFolder.FindFirstChild(ModulesFolder, "Client") or nil
	local HudFolder = ClientFolder and ClientFolder.FindFirstChild(ClientFolder, "HUD") or nil
	local GameUiFolder = HudFolder and HudFolder.FindFirstChild(HudFolder, "GameUi") or nil
	local CursorModuleScript = GameUiFolder and GameUiFolder.FindFirstChild(GameUiFolder, "Cursor") or nil
	if not CursorModuleScript then
		return nil
	end

	local SuccessBoolean, ModuleTable = pcall(require, CursorModuleScript)
	if not SuccessBoolean or type(ModuleTable) ~= "table" then
		return nil
	end

	ShieldModeRuntimeTable.cursorModule = ModuleTable
	return ModuleTable
end

function ShieldModeRuntimeTable.ResolveLocalGunModule()
	if not IsBloodZonePlaceBoolean then
		return nil
	end

	if ShieldModeRuntimeTable.localGunModule then
		return ShieldModeRuntimeTable.localGunModule
	end

	local ModulesFolder = ReplicatedStorageService and ReplicatedStorageService.FindFirstChild(ReplicatedStorageService, "Modules") or nil
	local ClientFolder = ModulesFolder and ModulesFolder.FindFirstChild(ModulesFolder, "Client") or nil
	local GameFolder = ClientFolder and ClientFolder.FindFirstChild(ClientFolder, "Game") or nil
	local WeaponClientModuleScript = GameFolder and GameFolder.FindFirstChild(GameFolder, "WeaponClient") or nil
	local LocalWeaponFolder = WeaponClientModuleScript and WeaponClientModuleScript.FindFirstChild(WeaponClientModuleScript, "LocalWeapon") or nil
	local LocalGunModuleScript = LocalWeaponFolder and LocalWeaponFolder.FindFirstChild(LocalWeaponFolder, "LocalGun") or nil
	if not LocalGunModuleScript then
		return nil
	end

	local SuccessBoolean, ModuleTable = pcall(require, LocalGunModuleScript)
	if not SuccessBoolean or type(ModuleTable) ~= "table" then
		return nil
	end

	ShieldModeRuntimeTable.localGunModule = ModuleTable
	return ModuleTable
end

function ShieldModeRuntimeTable.EnsureLocalGunHooks()
	if ShieldModeRuntimeTable.localGunHooksApplied or not IsBloodZonePlaceBoolean then
		return
	end

	local LocalGunModuleTable = ShieldModeRuntimeTable.ResolveLocalGunModule()
	local LocalGunOperationsTable = LocalGunModuleTable and (LocalGunModuleTable.__Operations or LocalGunModuleTable) or nil
	if not LocalGunOperationsTable
		or type(LocalGunOperationsTable.DoRecoil) ~= "function"
		or type(LocalGunOperationsTable.FireGun) ~= "function" then
		return
	end

	local OriginalDoRecoilFunction = LocalGunOperationsTable.DoRecoil
	local OriginalFireGunFunction = LocalGunOperationsTable.FireGun
	LocalGunOperationsTable.DoRecoil = function(SelfTable, ...)
		if IsSillyModeBehaviorActive() then
			local LocalCharacterModuleTable = ShieldModeRuntimeTable.ResolveLocalCharacterModule()
			if LocalCharacterModuleTable and type(LocalCharacterModuleTable.Rotate3rdPersonTime) == "number" then
				LocalCharacterModuleTable.Rotate3rdPersonTime = 0
			end
			return
		end

		return OriginalDoRecoilFunction(SelfTable, ...)
	end
	LocalGunOperationsTable.FireGun = function(SelfTable, ...)
		local PreviousActiveFiringLocalGun = ShieldModeRuntimeTable.activeFiringLocalGun
		ShieldModeRuntimeTable.activeFiringLocalGun = SelfTable
		local ResultTable = table.pack(pcall(OriginalFireGunFunction, SelfTable, ...))
		ShieldModeRuntimeTable.activeFiringLocalGun = PreviousActiveFiringLocalGun
		if not ResultTable[1] then
			error(ResultTable[2], 0)
		end
		return table.unpack(ResultTable, 2, ResultTable.n)
	end

	ShieldModeRuntimeTable.localGunHooksApplied = true
	DebugLog("localgun-hooks", "Installed Blood Zone LocalGun recoil and FireGun context hooks", true)
end

function ShieldModeRuntimeTable.EnsureCursorHooks()
	if ShieldModeRuntimeTable.cursorHooksApplied or not IsBloodZonePlaceBoolean then
		return
	end

	local CursorModuleTable = ShieldModeRuntimeTable.ResolveCursorModule()
	if not CursorModuleTable or type(CursorModuleTable.GetHit) ~= "function" then
		return
	end

	local OriginalGetHitFunction = CursorModuleTable.GetHit
	CursorModuleTable.GetHit = function(SelfTable, ...)
		if not CurrentTargetPartInstance or not CurrentTargetCharacterModel or not CurrentTargetPartInstance.Parent then
			return OriginalGetHitFunction(SelfTable, ...)
		end

		local LocalCharacterModel = CurrentFrameLocalCharacterModel
		local LocalCharacterReadyBoolean = CurrentFrameLocalCharacterReadyBoolean
		if not LocalCharacterReadyBoolean or not LocalCharacterModel or not LocalCharacterModel.Parent then
			LocalCharacterModel = ResolveCharacterModelForPlayer(LocalPlayer)
			LocalCharacterReadyBoolean = IsLocalCharacterReadyForAimbot(LocalCharacterModel)
			if not LocalCharacterReadyBoolean then
				return OriginalGetHitFunction(SelfTable, ...)
			end
		end

		local WeaponBallisticsProfileTable = CurrentWeaponBallisticsProfileTable
		if not WeaponBallisticsProfileTable then
			WeaponBallisticsProfileTable = ShieldModeRuntimeTable.ResolveCurrentWeaponBallisticsProfile(LocalCharacterModel)
		end
		if ShieldModeRuntimeTable.IsProjectileWeaponProfile(WeaponBallisticsProfileTable)
			and ShieldModeRuntimeTable.ShouldRedirectTowardCurrentTarget(LocalCharacterModel)
			and ShouldApplyNormalHookHitChance() then
			local ProjectileAimPointVector3 = GetCurrentEffectiveAimPointVector3()
			if typeof(ProjectileAimPointVector3) == "Vector3" then
				return ProjectileAimPointVector3
			end
		end

		if not IsSillyModeBehaviorActive() then
			return OriginalGetHitFunction(SelfTable, ...)
		end

		local ForcedHitPositionVector3 = ShieldModeRuntimeTable.GetShotSkyHitPosition()
		if ForcedHitPositionVector3 then
			return ForcedHitPositionVector3
		end

		return OriginalGetHitFunction(SelfTable, ...)
	end

	ShieldModeRuntimeTable.cursorHooksApplied = true
	DebugLog("shot-sky-cursor-hook", "Installed Blood Zone cursor hit override for shot sky aim", true)
end

function CollectVisibleShieldParts(ShieldInstance)
	local ShieldPartsTable = {}
	if not ShieldInstance or not ShieldInstance.GetDescendants then
		return ShieldPartsTable
	end

	for _, DescendantInstance in ipairs(ShieldInstance.GetDescendants(ShieldInstance)) do
		if DescendantInstance.IsA(DescendantInstance, "BasePart")
			and DescendantInstance.Transparency < 0.95 then
			table.insert(ShieldPartsTable, DescendantInstance)
		end
	end

	return ShieldPartsTable
end

function ShieldModeRuntimeTable.GetBloodZoneHeldItemState(CharacterModel)
	local StateTable = {
		hasGun = false,
		hasShield = false,
		gunInstance = nil,
		shieldInstance = nil,
		shieldParts = nil,
	}
	if not IsBloodZonePlaceBoolean or not CharacterModel then
		return StateTable
	end

	local NowNumber = tick()
	local CachedEntryTable = ShieldModeRuntimeTable.heldItemStateCache and ShieldModeRuntimeTable.heldItemStateCache[CharacterModel] or nil
	if CachedEntryTable and (NowNumber - (CachedEntryTable.time or 0)) < (ShieldModeRuntimeTable.heldItemStateCacheDuration or 0) then
		return CachedEntryTable.state or StateTable
	end

	local SeenInstancesTable = {}
	local GetGunDataByNameFunction = ShieldModeRuntimeTable.GetGunDataByName
	local function MarkShield(ItemInstance)
		if not StateTable.shieldInstance then
			StateTable.shieldInstance = ItemInstance
		end
		StateTable.hasShield = true
	end
	local function MarkGun(ItemInstance)
		if not StateTable.gunInstance then
			StateTable.gunInstance = ItemInstance
		end
		StateTable.hasGun = true
	end
	local function ResolveHeldItemRoot(ItemInstance)
		local CurrentInstance = ItemInstance
		while CurrentInstance and CurrentInstance ~= CharacterModel do
			local ParentInstance = CurrentInstance.Parent
			if ParentInstance == CharacterModel then
				return CurrentInstance
			end
			if ParentInstance and ParentInstance.Name == "EmoteAddons" and ParentInstance.Parent == CharacterModel then
				return CurrentInstance
			end
			CurrentInstance = ParentInstance
		end
		return ItemInstance
	end
	local function ConsiderHeldItem(ItemInstance)
		if not ItemInstance or SeenInstancesTable[ItemInstance] then
			return
		end
		SeenInstancesTable[ItemInstance] = true

		local ItemNameString = ItemInstance.Name
		if ItemNameString == "Metal Shield" then
			MarkShield(ItemInstance)
		end

		local ServiceNameString = ItemInstance.GetAttribute and ItemInstance.GetAttribute(ItemInstance, "Service") or nil
		if ServiceNameString == "GunService" then
			MarkGun(ItemInstance)
		elseif type(ItemNameString) == "string"
			and ItemNameString ~= ""
			and ItemNameString ~= "Metal Shield"
			and GetGunDataByNameFunction
			and GetGunDataByNameFunction(ItemNameString) ~= nil then
			MarkGun(ItemInstance)
		end

		if ItemInstance.FindFirstChild and ItemInstance.FindFirstChild(ItemInstance, "GUN_CORE", true) then
			MarkGun(ItemInstance)
		end
	end

	for _, ChildInstance in ipairs(CharacterModel.GetChildren(CharacterModel)) do
		if ChildInstance.IsA(ChildInstance, "Tool") then
			ConsiderHeldItem(ChildInstance)
		end
	end

	local EmoteAddonsFolder = CharacterModel.FindFirstChild and CharacterModel.FindFirstChild(CharacterModel, "EmoteAddons") or nil
	local HasEmoteAddonChildrenBoolean = false
	if EmoteAddonsFolder then
		for _, ChildInstance in ipairs(EmoteAddonsFolder.GetChildren(EmoteAddonsFolder)) do
			HasEmoteAddonChildrenBoolean = true
			ConsiderHeldItem(ChildInstance)
		end
	end

	if HasEmoteAddonChildrenBoolean and (not StateTable.hasGun or not StateTable.hasShield) then
		for _, DescendantInstance in ipairs(CharacterModel.GetDescendants(CharacterModel)) do
			if not StateTable.hasShield and DescendantInstance.Name == "Metal Shield" then
				MarkShield(ResolveHeldItemRoot(DescendantInstance))
			end

			if not StateTable.hasGun then
				if DescendantInstance.Name == "GUN_CORE" then
					MarkGun(ResolveHeldItemRoot(DescendantInstance))
				else
					local ServiceNameString = DescendantInstance.GetAttribute and DescendantInstance.GetAttribute(DescendantInstance, "Service") or nil
					if ServiceNameString == "GunService" then
						MarkGun(ResolveHeldItemRoot(DescendantInstance))
					end
				end
			end

			if StateTable.hasGun and StateTable.hasShield then
				break
			end
		end
	end

	if StateTable.shieldInstance then
		StateTable.shieldParts = CollectVisibleShieldParts(StateTable.shieldInstance)
	end

	if ShieldModeRuntimeTable.heldItemStateCache then
		ShieldModeRuntimeTable.heldItemStateCache[CharacterModel] = {
			time = NowNumber,
			state = StateTable,
		}
	end

	return StateTable
end

function ShieldModeRuntimeTable.GetBloodZoneShieldVisibleParts(CharacterModel)
	if not IsBloodZonePlaceBoolean or not CharacterModel then
		return nil
	end

	local StateTable = ShieldModeRuntimeTable.GetBloodZoneHeldItemState(CharacterModel)
	return StateTable and StateTable.shieldParts or nil
end

function ShieldModeRuntimeTable.ResolveModuleData()
	if not IsBloodZonePlaceBoolean then
		return nil, nil
	end

	local ModulesFolder = ReplicatedStorageService and ReplicatedStorageService.FindFirstChild(ReplicatedStorageService, "Modules") or nil
	if not ModulesFolder then
		return ShieldModeRuntimeTable.localData, ShieldModeRuntimeTable.weaponData
	end

	if not ShieldModeRuntimeTable.localData then
		local ClientFolder = ModulesFolder.FindFirstChild(ModulesFolder, "Client")
		local LocalDataModule = ClientFolder and ClientFolder.FindFirstChild(ClientFolder, "LocalData")
		if LocalDataModule then
			local SuccessBoolean, ResultValue = pcall(require, LocalDataModule)
			if SuccessBoolean and type(ResultValue) == "table" then
				ShieldModeRuntimeTable.localData = ResultValue
			end
		end
	end

	if not ShieldModeRuntimeTable.weaponData then
		local DataFolder = ModulesFolder.FindFirstChild(ModulesFolder, "Data")
		local WeaponDataModule = DataFolder and DataFolder.FindFirstChild(DataFolder, "WeaponData")
		if WeaponDataModule then
			local SuccessBoolean, ResultValue = pcall(require, WeaponDataModule)
			if SuccessBoolean and type(ResultValue) == "table" then
				ShieldModeRuntimeTable.weaponData = ResultValue
			end
		end
	end

	return ShieldModeRuntimeTable.localData, ShieldModeRuntimeTable.weaponData
end

function ShieldModeRuntimeTable.GetLoadoutWeaponName(SlotNameString)
	local LocalDataTable = ShieldModeRuntimeTable.ResolveModuleData()
	local DataSlotTable = LocalDataTable and LocalDataTable.DataSlot or nil
	local LoadoutTable = DataSlotTable and DataSlotTable.Loadout or nil
	local WeaponNameString = LoadoutTable and LoadoutTable[SlotNameString] or nil
	if type(WeaponNameString) == "string" and WeaponNameString ~= "" then
		return WeaponNameString
	end

	return nil
end

function ShieldModeRuntimeTable.GetGunDataByName(WeaponNameString)
	if type(WeaponNameString) ~= "string" or WeaponNameString == "" then
		return nil
	end

	local _, WeaponDataTable = ShieldModeRuntimeTable.ResolveModuleData()
	local GunDataTable = WeaponDataTable and WeaponDataTable.Gun or nil
	local WeaponEntryTable = GunDataTable and GunDataTable[WeaponNameString] or nil
	if type(WeaponEntryTable) == "table" then
		return WeaponEntryTable
	end

	return nil
end

function ShieldModeRuntimeTable.IsGunTool(ToolInstance)
	if not ToolInstance or not ToolInstance.IsA(ToolInstance, "Tool") then
		return false
	end

	local ServiceNameString = ShieldModeRuntimeTable.GetToolServiceName(ToolInstance)
	if ServiceNameString == "GunService" then
		return true
	end

	if ToolInstance.FindFirstChild(ToolInstance, "GUN_CORE", true) then
		return true
	end

	return ShieldModeRuntimeTable.GetGunDataByName(ToolInstance.Name) ~= nil
end

function ShieldModeRuntimeTable.GetEquippedGunTool(CharacterModel)
	local EquippedTool = ShieldModeRuntimeTable.GetEquippedTool(CharacterModel)
	if not EquippedTool or EquippedTool.Name == "Metal Shield" then
		return nil
	end

	if ShieldModeRuntimeTable.IsGunTool(EquippedTool) then
		return EquippedTool
	end

	return nil
end

function ShieldModeRuntimeTable.IsThreatCharacterValid(CharacterModel)
	if not CharacterModel or not CharacterModel.Parent then
		return false
	end

	local Humanoid = GetCharacterHumanoid(CharacterModel)
	local RootPartInstance = GetCharacterRootPart(CharacterModel)
	if not Humanoid or not RootPartInstance then
		return false
	end

	if CharacterModel.GetAttribute(CharacterModel, "Carried") then
		return false
	end

	if CharacterModel.GetAttribute(CharacterModel, "Escaped") then
		return false
	end

	if CharacterModel.GetAttribute(CharacterModel, "Downed") then
		return false
	end

	if CharacterModel.GetAttribute(CharacterModel, "IsRagdolled") then
		return false
	end

	if CollectionService.HasTag(CollectionService, CharacterModel, "DeadBody") then
		return false
	end

	if Humanoid.GetAttribute and Humanoid.GetAttribute(Humanoid, "Dead") then
		return false
	end

	if IsCharacterForceFieldProtected(CharacterModel, Humanoid) then
		return false
	end

	local HealthNumber = Humanoid.Health
	if type(HealthNumber) ~= "number" or HealthNumber <= 0 then
		return false
	end

	if ShieldModeRuntimeTable.GetEquippedGunTool(CharacterModel) then
		return true
	end

	local HeldItemStateTable = ShieldModeRuntimeTable.GetBloodZoneHeldItemState
		and ShieldModeRuntimeTable.GetBloodZoneHeldItemState(CharacterModel) or nil
	return HeldItemStateTable ~= nil and HeldItemStateTable.hasGun == true
end

function ShieldModeRuntimeTable.GetThreatAimData(ThreatCharacterModel, LocalCharacterModel)
	if not ShieldModeRuntimeTable.IsThreatCharacterValid(ThreatCharacterModel) then
		return nil
	end

	local ThreatHeadPartInstance = GetCharacterHeadPart(ThreatCharacterModel)
	local ThreatRootPartInstance = GetCharacterRootPart(ThreatCharacterModel)
	local ThreatOriginPartInstance = ThreatHeadPartInstance or ThreatRootPartInstance
	local LocalRootPartInstance = GetCharacterRootPart(LocalCharacterModel)
	local LocalHeadPartInstance = GetCharacterHeadPart(LocalCharacterModel)
	if not ThreatOriginPartInstance or not LocalRootPartInstance then
		return nil
	end

	local CandidateLocalParts = {}
	if LocalHeadPartInstance then
		table.insert(CandidateLocalParts, LocalHeadPartInstance)
	end
	table.insert(CandidateLocalParts, LocalRootPartInstance)

	local PreferredLocalPartInstance = GetPreferredTargetPart(LocalCharacterModel)
	if PreferredLocalPartInstance and PreferredLocalPartInstance ~= LocalHeadPartInstance and PreferredLocalPartInstance ~= LocalRootPartInstance then
		table.insert(CandidateLocalParts, PreferredLocalPartInstance)
	end

	local ThreatOriginVector3 = ThreatOriginPartInstance.Position
	local BestThreatData = nil
	for _, LocalPartInstance in ipairs(CandidateLocalParts) do
		local ToLocalVector3 = LocalPartInstance.Position - ThreatOriginVector3
		local DistanceNumber = ToLocalVector3.Magnitude
		if DistanceNumber <= 0.001 or DistanceNumber > MaxDistanceNumber then
			continue
		end

		local ToLocalUnitVector3 = ToLocalVector3.Unit
		local HeadLookDotNumber = ThreatHeadPartInstance and ThreatHeadPartInstance.CFrame.LookVector:Dot(ToLocalUnitVector3) or -1
		local RootLookDotNumber = ThreatRootPartInstance and ThreatRootPartInstance.CFrame.LookVector:Dot(ToLocalUnitVector3) or -1
		local AimDotNumber = math.max(HeadLookDotNumber, RootLookDotNumber)
		if AimDotNumber < 0.82 then
			continue
		end

		local LineOfSightResult = RaycastBetweenIgnoringGlass(
			ThreatOriginVector3,
			LocalPartInstance.Position,
			{ ThreatCharacterModel, LocalCharacterModel }
		)
		if LineOfSightResult then
			continue
		end

		local ThreatScoreNumber = (AimDotNumber * 1000) - (DistanceNumber * 0.12) + (HeadLookDotNumber * 35)
		if not BestThreatData or ThreatScoreNumber > BestThreatData.score then
			BestThreatData = {
				character = ThreatCharacterModel,
				part = ThreatOriginPartInstance,
				position = ThreatOriginVector3,
				targetPart = LocalPartInstance,
				targetPosition = LocalPartInstance.Position,
				score = ThreatScoreNumber,
				dot = AimDotNumber,
				distance = DistanceNumber,
				source = "aiming",
			}
		end
	end

	return BestThreatData
end

function ShieldModeRuntimeTable.ResolveDirectionIndicatorModule()
	if not IsBloodZonePlaceBoolean then
		return nil
	end

	if ShieldModeRuntimeTable.directionIndicatorModule then
		return ShieldModeRuntimeTable.directionIndicatorModule
	end

	local ModulesFolder = ReplicatedStorageService and ReplicatedStorageService.FindFirstChild(ReplicatedStorageService, "Modules") or nil
	local ClientFolder = ModulesFolder and ModulesFolder.FindFirstChild(ModulesFolder, "Client") or nil
	local HudFolder = ClientFolder and ClientFolder.FindFirstChild(ClientFolder, "HUD") or nil
	local GameUiFolder = HudFolder and HudFolder.FindFirstChild(HudFolder, "GameUi") or nil
	local CursorFolder = GameUiFolder and GameUiFolder.FindFirstChild(GameUiFolder, "Cursor") or nil
	local DirectionIndicatorModuleScript = CursorFolder and CursorFolder.FindFirstChild(CursorFolder, "DirectionIndicator") or nil
	if not DirectionIndicatorModuleScript then
		return nil
	end

	local SuccessBoolean, ModuleTable = pcall(require, DirectionIndicatorModuleScript)
	if not SuccessBoolean or type(ModuleTable) ~= "table" then
		return nil
	end

	ShieldModeRuntimeTable.directionIndicatorModule = ModuleTable
	return ModuleTable
end

function ShieldModeRuntimeTable.GetDamageIndicatorThreatData(LocalCharacterModel)
	local DirectionIndicatorModuleTable = ShieldModeRuntimeTable.ResolveDirectionIndicatorModule()
	local ActiveIndicatorsTable = DirectionIndicatorModuleTable and DirectionIndicatorModuleTable.ActiveIndicators or nil
	local LocalRootPartInstance = GetCharacterRootPart(LocalCharacterModel)
	if type(ActiveIndicatorsTable) ~= "table" or not LocalRootPartInstance then
		return nil
	end

	local BestThreatData = nil
	for SubjectValue, IndicatorData in pairs(ActiveIndicatorsTable) do
		local WorldPositionVector3 = IndicatorData and IndicatorData.WorldPosition or nil
		local DeleteTimerNumber = tonumber(IndicatorData and IndicatorData.DeleteTimer) or 0
		if typeof(WorldPositionVector3) ~= "Vector3" or DeleteTimerNumber <= 0 then
			continue
		end

		local FlatDirectionVector3 = Vector3.new(
			WorldPositionVector3.X - LocalRootPartInstance.Position.X,
			0,
			WorldPositionVector3.Z - LocalRootPartInstance.Position.Z
		)
		local FlatDistanceNumber = FlatDirectionVector3.Magnitude
		if FlatDistanceNumber <= 0.001 then
			continue
		end

		local ThreatScoreNumber = DeleteTimerNumber * 1000 - FlatDistanceNumber * 0.05
		if not BestThreatData or ThreatScoreNumber > BestThreatData.score then
			BestThreatData = {
				character = nil,
				part = nil,
				position = WorldPositionVector3,
				score = ThreatScoreNumber,
				dot = 1,
				distance = FlatDistanceNumber,
				source = "damage",
				subject = SubjectValue,
			}
		end
	end

	return BestThreatData
end

function ShieldModeRuntimeTable.GetVisibleArmedThreatData(ThreatCharacterModel, LocalCharacterModel)
	if not ShieldModeRuntimeTable.IsThreatCharacterValid(ThreatCharacterModel) then
		return nil
	end

	local ThreatPartInstance = GetPreferredTargetPart(ThreatCharacterModel) or GetCharacterRootPart(ThreatCharacterModel) or GetCharacterHeadPart(ThreatCharacterModel)
	local LocalRootPartInstance = GetCharacterRootPart(LocalCharacterModel)
	if not ThreatPartInstance or not LocalRootPartInstance then
		return nil
	end

	local ThreatPositionVector3 = ThreatPartInstance.Position
	local FlatDirectionVector3 = Vector3.new(
		ThreatPositionVector3.X - LocalRootPartInstance.Position.X,
		0,
		ThreatPositionVector3.Z - LocalRootPartInstance.Position.Z
	)
	local FlatDistanceNumber = FlatDirectionVector3.Magnitude
	if FlatDistanceNumber <= 0.001 or FlatDistanceNumber > MaxDistanceNumber then
		return nil
	end

	local LineOfSightResult = RaycastBetweenIgnoringGlass(
		LocalRootPartInstance.Position,
		ThreatPositionVector3,
		{ ThreatCharacterModel, LocalCharacterModel }
	)
	if LineOfSightResult then
		return nil
	end

	return {
		character = ThreatCharacterModel,
		part = ThreatPartInstance,
		position = ThreatPositionVector3,
		score = 500 - FlatDistanceNumber * 0.1,
		dot = 0,
		distance = FlatDistanceNumber,
		source = "visible",
	}
end

function IsThreatDataCacheEntryUsable(ThreatDataTable)
	return ThreatDataTable == nil
		or (ThreatDataTable.position ~= nil
			and ((not ThreatDataTable.character) or ThreatDataTable.character.Parent))
end

function ResolveCachedThreatData(LocalCharacterModel)
	if not LocalCharacterModel then
		return nil, nil
	end

	local NowNumber = tick()
	local FrameIdNumber = tonumber(CurrentFrameSequenceNumber) or 0
	local CacheAgeNumber = NowNumber - (ShieldModeRuntimeTable.lastThreatScanTime or 0)
	local CacheCharacterMatchesBoolean = ShieldModeRuntimeTable.cachedThreatScanCharacter == LocalCharacterModel
	local CacheIsCurrentFrameBoolean = FrameIdNumber > 0
		and ShieldModeRuntimeTable.cachedThreatScanFrameId == FrameIdNumber
	local CacheIsFreshBoolean = CacheAgeNumber < (ShieldModeRuntimeTable.threatScanInterval or 0.08)
	if CacheCharacterMatchesBoolean
		and (CacheIsCurrentFrameBoolean or CacheIsFreshBoolean)
		and IsThreatDataCacheEntryUsable(ShieldModeRuntimeTable.cachedThreatData)
		and IsThreatDataCacheEntryUsable(ShieldModeRuntimeTable.cachedAimingThreatData) then
		return ShieldModeRuntimeTable.cachedThreatData, ShieldModeRuntimeTable.cachedAimingThreatData
	end

	ShieldModeRuntimeTable.lastThreatScanTime = NowNumber
	ShieldModeRuntimeTable.cachedThreatScanCharacter = LocalCharacterModel
	ShieldModeRuntimeTable.cachedThreatScanFrameId = FrameIdNumber
	ShieldModeRuntimeTable.cachedThreatData = nil
	ShieldModeRuntimeTable.cachedAimingThreatData = nil

	local TeamCheckEnabledBoolean = false
	local LocalTeamObject = nil
	if not IsCustomCharacterGameBoolean and LocalPlayer.Team ~= nil then
		TeamCheckEnabledBoolean = true
		LocalTeamObject = LocalPlayer.Team
	end

	local BestThreatData = ShieldModeRuntimeTable.GetDamageIndicatorThreatData(LocalCharacterModel)
	local BestAimingThreatData = nil
	local CharacterEntries = GetSearchableCharacterEntries(LocalCharacterModel, TeamCheckEnabledBoolean, LocalTeamObject)
	for _, CharacterEntry in ipairs(CharacterEntries) do
		local AimingThreatData = ShieldModeRuntimeTable.GetThreatAimData(CharacterEntry.character, LocalCharacterModel)
		if AimingThreatData and (not BestAimingThreatData or AimingThreatData.score > BestAimingThreatData.score) then
			BestAimingThreatData = AimingThreatData
		end

		local ThreatData = AimingThreatData
		if not ThreatData then
			ThreatData = ShieldModeRuntimeTable.GetVisibleArmedThreatData(CharacterEntry.character, LocalCharacterModel)
		end
		if ThreatData and (not BestThreatData or ThreatData.score > BestThreatData.score) then
			BestThreatData = ThreatData
		end
	end

	ShieldModeRuntimeTable.cachedThreatData = BestThreatData
	ShieldModeRuntimeTable.cachedAimingThreatData = BestAimingThreatData
	return BestThreatData, BestAimingThreatData
end

function ShieldModeRuntimeTable.ResolveThreatData(LocalCharacterModel)
	local ThreatData = ResolveCachedThreatData(LocalCharacterModel)
	return ThreatData
end

function ShieldModeRuntimeTable.ResolveAimingThreatData(LocalCharacterModel)
	local _, AimingThreatData = ResolveCachedThreatData(LocalCharacterModel)
	return AimingThreatData
end

function ShieldModeRuntimeTable.GetThreatFacingDirection(LocalCharacterModel, MetalShieldTool, EquippedTool)
	if not IsEffectiveShieldModeEnabled() or not LocalCharacterModel or not MetalShieldTool then
		return nil, nil
	end

	local LocalRootPartInstance = GetCharacterRootPart(LocalCharacterModel)
	if not LocalRootPartInstance then
		return nil, nil
	end

	local ThreatData = ShieldModeRuntimeTable.ResolveThreatData(LocalCharacterModel)
	if not ThreatData or not ThreatData.position then
		return nil, nil
	end

	local FlatDirectionVector3 = Vector3.new(
		ThreatData.position.X - LocalRootPartInstance.Position.X,
		0,
		ThreatData.position.Z - LocalRootPartInstance.Position.Z
	)
	if FlatDirectionVector3.Magnitude <= 0.001 then
		return nil, nil
	end

	return FlatDirectionVector3.Unit, ThreatData
end

function GetThreatAimDirectionVector3(LocalCharacterModel, ThreatData, FallbackDirectionVector3)
	if not LocalCharacterModel or not ThreatData or typeof(ThreatData.position) ~= "Vector3" then
		return FallbackDirectionVector3
	end

	local AimOriginPartInstance = GetCharacterHeadPart(LocalCharacterModel) or GetCharacterRootPart(LocalCharacterModel)
	if not AimOriginPartInstance then
		return FallbackDirectionVector3
	end

	local ThreatAimDirectionVector3 = ThreatData.position - AimOriginPartInstance.Position
	if ThreatAimDirectionVector3.Magnitude <= 0.001 then
		return FallbackDirectionVector3
	end

	return ThreatAimDirectionVector3.Unit
end

function ShieldModeRuntimeTable.ApplyBodyFacingOverride(SelfTable, FacingDirectionVector3, DeltaTimeNumber)
	if not FacingDirectionVector3
		or not SelfTable
		or not SelfTable.Root
		or not SelfTable.Head
		or not SelfTable.Humanoid
		or not SelfTable.Character
		or not SelfTable.Character.PivotTo
		or SelfTable.Humanoid.GetState(SelfTable.Humanoid) == Enum.HumanoidStateType.Climbing then
		return false
	end

	if SelfTable.Root == WorkspaceService or SelfTable.Character == WorkspaceService or SelfTable.Head == WorkspaceService then
		TraceLog(
			"body-face-workspace",
			"root=" .. DescribeDebugInstance(SelfTable.Root)
				.. " | head=" .. DescribeDebugInstance(SelfTable.Head)
				.. " | character=" .. DescribeDebugInstance(SelfTable.Character)
				.. " | facing=" .. FormatDebugVector3(FacingDirectionVector3),
			true
		)
	end

	local FlatDirectionVector3 = Vector3.new(FacingDirectionVector3.X, 0, FacingDirectionVector3.Z)
	if FlatDirectionVector3.Magnitude <= 0.001 then
		return false
	end

	local TargetRotationCFrame = CFrame.new(SelfTable.Root.Position, SelfTable.Root.Position + FlatDirectionVector3.Unit)
	local PreviousRotationCFrame = ShieldModeRuntimeTable.forcedBodyRotationCFrame or SelfTable.Root.CFrame.Rotation
	local RotationAlphaNumber = math.clamp((tonumber(DeltaTimeNumber) or 0.016) * 10, 0, 1)
	local NewRotationCFrame = CFrame.new(SelfTable.Root.Position) * PreviousRotationCFrame:Lerp(TargetRotationCFrame.Rotation, RotationAlphaNumber)
	SelfTable.Humanoid.AutoRotate = false
	SelfTable.Character.PivotTo(SelfTable.Character, NewRotationCFrame)
	ShieldModeRuntimeTable.forcedBodyRotationCFrame = NewRotationCFrame.Rotation

	local CharacterHumanoid = SelfTable.Character.FindFirstChild and SelfTable.Character.FindFirstChild(SelfTable.Character, "Humanoid") or nil
	if CharacterHumanoid then
		CharacterHumanoid.CameraOffset = (SelfTable.Root.CFrame * CFrame.new(0, 1.5, 0)):PointToObjectSpace(SelfTable.Head.Position)
	end

	if type(SelfTable.Rotate3rdPersonTime) == "number" then
		SelfTable.Rotate3rdPersonTime = math.max(SelfTable.Rotate3rdPersonTime, 0.2)
	end

	return true
end

function ShieldModeRuntimeTable.ShouldDelayReloadForThreat(LocalCharacterModel)
	local ThreatData = LocalCharacterModel and ShieldModeRuntimeTable.ResolveAimingThreatData(LocalCharacterModel) or nil
	if not ThreatData then
		return false, nil
	end

	return (tonumber(ThreatData.dot) or -1) >= 0.88, ThreatData
end

function ShieldModeRuntimeTable.ResolveLocalCharacterModule()
	if not IsBloodZonePlaceBoolean then
		return nil
	end

	if ShieldModeRuntimeTable.localCharacterModule then
		return ShieldModeRuntimeTable.localCharacterModule
	end

	local ModulesFolder = ReplicatedStorageService and ReplicatedStorageService.FindFirstChild(ReplicatedStorageService, "Modules") or nil
	local ClientFolder = ModulesFolder and ModulesFolder.FindFirstChild(ModulesFolder, "Client") or nil
	local GameFolder = ClientFolder and ClientFolder.FindFirstChild(ClientFolder, "Game") or nil
	local LocalCharacterModuleScript = GameFolder and GameFolder.FindFirstChild(GameFolder, "LocalCharacter") or nil
	if not LocalCharacterModuleScript then
		return nil
	end

	local SuccessBoolean, ModuleTable = pcall(require, LocalCharacterModuleScript)
	if not SuccessBoolean or type(ModuleTable) ~= "table" then
		return nil
	end

	ShieldModeRuntimeTable.localCharacterModule = ModuleTable
	return ModuleTable
end

function ShieldModeRuntimeTable.EnsureLocalCharacterHooks()
	if ShieldModeRuntimeTable.localCharacterHooksApplied or not IsBloodZonePlaceBoolean then
		return
	end

	local LocalCharacterModuleTable = ShieldModeRuntimeTable.ResolveLocalCharacterModule()
	if not LocalCharacterModuleTable then
		return
	end

	local OriginalUpdateLookFunction = LocalCharacterModuleTable.UpdateLook
	local OriginalUpdateLimbsFunction = LocalCharacterModuleTable.UpdateLimbs
	if type(OriginalUpdateLookFunction) ~= "function" or type(OriginalUpdateLimbsFunction) ~= "function" then
		return
	end

	LocalCharacterModuleTable.UpdateLook = function(SelfTable, DirectionVector3, DeltaTimeNumber)
		if IsSillyModeBehaviorActive() and type(SelfTable and SelfTable.Rotate3rdPersonTime) == "number" then
			SelfTable.Rotate3rdPersonTime = 0
		end

		local LocalCharacterModel = SelfTable and SelfTable.Character or nil
		local MetalShieldTool = LocalCharacterModel and ShieldModeRuntimeTable.GetLocalMetalShieldTool(LocalCharacterModel) or nil
		local EquippedTool = LocalCharacterModel and ShieldModeRuntimeTable.GetEquippedTool(LocalCharacterModel) or nil
		local ForcedDirectionVector3, ThreatData = ShieldModeRuntimeTable.GetThreatFacingDirection(LocalCharacterModel, MetalShieldTool, EquippedTool)
		local ThreatAimDirectionVector3 = GetThreatAimDirectionVector3(LocalCharacterModel, ThreatData, ForcedDirectionVector3)
		local ShotSkyAimDataTable = ResolveShotSkyAimDataTable(LocalCharacterModel, DirectionVector3, EquippedTool)
		local ShotSkyDirectionVector3 = ShotSkyAimDataTable and ShotSkyAimDataTable.direction or nil
		local ShotSkyFacingDirectionVector3 = ShotSkyAimDataTable and ShotSkyAimDataTable.facingDirection or nil

		if ForcedDirectionVector3 and ShieldModeRuntimeTable.ApplyBodyFacingOverride(SelfTable, ForcedDirectionVector3, DeltaTimeNumber) then
			DirectionVector3 = ThreatAimDirectionVector3 or DirectionVector3
			if type(SelfTable.Rotate3rdPersonTime) == "number" then
				SelfTable.Rotate3rdPersonTime = math.max(SelfTable.Rotate3rdPersonTime, 0.2)
			end
			if DebugModeEnabledBoolean then
				DebugLog(
					"shield-face-override",
					"Shield Mode overriding LocalCharacter.UpdateLook toward " .. GetCharacterModelDebugName(ThreatData.character)
						.. " | dot=" .. string.format("%.2f", ThreatData.dot or -1)
						.. " | aim=" .. FormatDebugVector3(ThreatAimDirectionVector3),
					false
				)
			end
			return
		end

		local AppliedShotSkyFacingOverrideBoolean = false
		if ShotSkyDirectionVector3 then
			if ShotSkyFacingDirectionVector3 then
				AppliedShotSkyFacingOverrideBoolean = ShieldModeRuntimeTable.ApplyBodyFacingOverride(
					SelfTable,
					ShotSkyFacingDirectionVector3,
					DeltaTimeNumber
				) == true
			end
			DirectionVector3 = ShotSkyDirectionVector3
			if type(SelfTable.Rotate3rdPersonTime) == "number" then
				SelfTable.Rotate3rdPersonTime = math.max(SelfTable.Rotate3rdPersonTime, 0.2)
			end
			if AppliedShotSkyFacingOverrideBoolean then
				return
			end
		end

		if not AppliedShotSkyFacingOverrideBoolean then
			ShieldModeRuntimeTable.forcedBodyRotationCFrame = nil
		end
		return OriginalUpdateLookFunction(SelfTable, DirectionVector3, DeltaTimeNumber)
	end

	LocalCharacterModuleTable.UpdateLimbs = function(SelfTable, DirectionVector3, DeltaTimeNumber)
		if IsSillyModeBehaviorActive() and type(SelfTable and SelfTable.Rotate3rdPersonTime) == "number" then
			SelfTable.Rotate3rdPersonTime = 0
		end

		local LocalCharacterModel = SelfTable and SelfTable.Character or nil
		local MetalShieldTool = LocalCharacterModel and ShieldModeRuntimeTable.GetLocalMetalShieldTool(LocalCharacterModel) or nil
		local EquippedTool = LocalCharacterModel and ShieldModeRuntimeTable.GetEquippedTool(LocalCharacterModel) or nil
		local ShotSkyDirectionVector3 = ShieldModeRuntimeTable.GetShotSkyAimDirection(LocalCharacterModel, DirectionVector3, EquippedTool)
		local ForcedDirectionVector3, ThreatData = ShieldModeRuntimeTable.GetThreatFacingDirection(LocalCharacterModel, MetalShieldTool, EquippedTool)
		local ThreatAimDirectionVector3 = GetThreatAimDirectionVector3(LocalCharacterModel, ThreatData, ForcedDirectionVector3)
		if ForcedDirectionVector3 then
			DirectionVector3 = ThreatAimDirectionVector3 or ForcedDirectionVector3
			if type(SelfTable.Rotate3rdPersonTime) == "number" then
				SelfTable.Rotate3rdPersonTime = math.max(SelfTable.Rotate3rdPersonTime, 0.2)
			end
		elseif ShotSkyDirectionVector3 then
			DirectionVector3 = ShotSkyDirectionVector3
			if type(SelfTable.Rotate3rdPersonTime) == "number" then
				SelfTable.Rotate3rdPersonTime = math.max(SelfTable.Rotate3rdPersonTime, 0.2)
			end
		end
		return OriginalUpdateLimbsFunction(SelfTable, DirectionVector3, DeltaTimeNumber)
	end

	ShieldModeRuntimeTable.localCharacterHooksApplied = true
	DebugLog("shield-hooks", "Installed LocalCharacter facing override hooks", true)
end

function ShieldModeRuntimeTable.ApplyThreatFacing(LocalCharacterModel, MetalShieldTool, EquippedTool)
	local ForcedDirectionVector3, ThreatData = ShieldModeRuntimeTable.GetThreatFacingDirection(LocalCharacterModel, MetalShieldTool, EquippedTool)
	if not ForcedDirectionVector3 or not ThreatData then
		return
	end

	local LocalCharacterModuleTable = ShieldModeRuntimeTable.ResolveLocalCharacterModule()
	if LocalCharacterModuleTable then
		ShieldModeRuntimeTable.ApplyBodyFacingOverride(
			LocalCharacterModuleTable,
			ForcedDirectionVector3,
			0.016
		)
	end

	if DebugModeEnabledBoolean then
		DebugLog(
			"shield-face",
			"Shield Mode facing threat " .. GetCharacterModelDebugName(ThreatData.character) .. " | dot=" .. string.format("%.2f", ThreatData.dot or -1) .. " | dist=" .. string.format("%.1f", ThreatData.distance or -1),
			false
		)
	end
end

function ShieldModeRuntimeTable.GetSecondaryTool(CharacterModel)
	local SecondaryWeaponNameString = ShieldModeRuntimeTable.GetLoadoutWeaponName("Secondary")
	if SecondaryWeaponNameString then
		local SecondaryTool = ShieldModeRuntimeTable.FindLocalToolByName(CharacterModel, SecondaryWeaponNameString)
		if SecondaryTool then
			return SecondaryTool, SecondaryWeaponNameString
		end
	end

	for _, ContainerInstance in ipairs({ ShieldModeRuntimeTable.GetLocalPlayerBackpack(), CharacterModel }) do
		if ContainerInstance then
			for _, ChildInstance in ipairs(ContainerInstance.GetChildren(ContainerInstance)) do
				if ChildInstance.IsA(ChildInstance, "Tool")
					and ChildInstance.Name ~= "Metal Shield"
					and ShieldModeRuntimeTable.IsGunTool(ChildInstance) then
					return ChildInstance, ChildInstance.Name
				end
			end
		end
	end

	return nil, SecondaryWeaponNameString
end

function ShieldModeRuntimeTable.EquipTool(CharacterModel, ToolInstance)
	if not CharacterModel or not ToolInstance then
		return false
	end

	if ToolInstance.Parent == CharacterModel then
		return true
	end

	local BackpackInstance = ShieldModeRuntimeTable.GetLocalPlayerBackpack()
	if ToolInstance.Parent ~= BackpackInstance then
		return false
	end

	local Humanoid = GetCharacterHumanoid(CharacterModel)
	if not Humanoid then
		return false
	end

	if Humanoid.UnequipTools then
		Humanoid.UnequipTools(Humanoid)
	end

	if Humanoid.EquipTool then
		Humanoid.EquipTool(Humanoid, ToolInstance)
		return true
	end

	return false
end

function ShieldModeRuntimeTable.TryEquipTool(CharacterModel, ToolInstance, ReasonString, ForceBoolean)
	if not CharacterModel or not ToolInstance then
		return false
	end

	local NowNumber = tick()
	if not ForceBoolean and (NowNumber - ShieldModeRuntimeTable.lastEquipAttemptTime) < ShieldModeRuntimeTable.equipThrottle then
		return false
	end

	if ShieldModeRuntimeTable.EquipTool(CharacterModel, ToolInstance) then
		ShieldModeRuntimeTable.lastEquipAttemptTime = NowNumber
		if DebugModeEnabledBoolean then
			DebugLog("shield-equip-" .. ToolInstance.Name, "Shield Mode equipped " .. ToolInstance.Name .. " (" .. ReasonString .. ")", false)
		end
		return true
	end

	return false
end

function ShieldModeRuntimeTable.UpdateCombatState(LocalCharacterModel, WantsShotBoolean)
	if not IsEffectiveShieldModeEnabled() or not LocalCharacterModel then
		return false, nil
	end

	ShieldModeRuntimeTable.EnsureLocalCharacterHooks()

	local MetalShieldTool = ShieldModeRuntimeTable.GetLocalMetalShieldTool(LocalCharacterModel)
	local SecondaryTool, SecondaryWeaponNameString = ShieldModeRuntimeTable.GetSecondaryTool(LocalCharacterModel)
	local SecondaryWeaponDataTable = ShieldModeRuntimeTable.GetGunDataByName(SecondaryWeaponNameString)
	if not MetalShieldTool then
		return false, nil
	end

	if not SecondaryTool then
		local EquippedTool = ShieldModeRuntimeTable.GetEquippedTool(LocalCharacterModel)
		if EquippedTool ~= MetalShieldTool then
			ShieldModeRuntimeTable.TryEquipTool(LocalCharacterModel, MetalShieldTool, "missing secondary", false)
			EquippedTool = ShieldModeRuntimeTable.GetEquippedTool(LocalCharacterModel)
		end
		ShieldModeRuntimeTable.ApplyThreatFacing(LocalCharacterModel, MetalShieldTool, EquippedTool)
		return true, nil
	end

	local ShootTimeNumber = tonumber(SecondaryWeaponDataTable and SecondaryWeaponDataTable.ShootTime) or 0.12
	local ReloadTimeNumber = tonumber(SecondaryWeaponDataTable and SecondaryWeaponDataTable.ReloadTime) or 1.7
	local ReequipDelayNumber = math.clamp(ShootTimeNumber * 0.28, 0.03, 0.08)
	local ReadyDelayNumber = math.clamp(ShootTimeNumber * 0.18, 0.02, 0.06)
	local NowNumber = tick()
	local EquippedTool = ShieldModeRuntimeTable.GetEquippedTool(LocalCharacterModel)
	local SecondaryReloadingBoolean = ShieldModeRuntimeTable.IsToolReloading(SecondaryTool)
	local DelayReloadBoolean, DelayReloadThreatData = ShieldModeRuntimeTable.ShouldDelayReloadForThreat(LocalCharacterModel)
	local AmmoEmptyBoolean = ShieldModeRuntimeTable.IsCurrentGunAmmoEmpty()
	local ReloadResumeWindowNumber = math.max(ReadyDelayNumber, 0.3)

	ShieldModeRuntimeTable.SetReloadSuppressionEnabled(DelayReloadBoolean)

	if AmmoEmptyBoolean and DelayReloadBoolean then
		ShieldModeRuntimeTable.reloadDeferredForThreat = true
		ShieldModeRuntimeTable.reloadResumeUntilTime = 0
	end

	if AmmoEmptyBoolean and not DelayReloadBoolean and not SecondaryReloadingBoolean then
		ShieldModeRuntimeTable.reloadDeferredForThreat = true
		if ShieldModeRuntimeTable.reloadResumeUntilTime <= 0 then
			ShieldModeRuntimeTable.reloadResumeUntilTime = NowNumber + ReloadResumeWindowNumber
		end
	end

	if SecondaryReloadingBoolean then
		if DelayReloadBoolean then
			ShieldModeRuntimeTable.reloadObserved = false
			ShieldModeRuntimeTable.reloadDeferredForThreat = true
			ShieldModeRuntimeTable.reloadHoldUntilTime = 0
			ShieldModeRuntimeTable.pendingReequipTime = 0
			ShieldModeRuntimeTable.secondaryReadyTime = 0
			ShieldModeRuntimeTable.reloadResumeUntilTime = 0
			if EquippedTool ~= MetalShieldTool then
				ShieldModeRuntimeTable.TryEquipTool(LocalCharacterModel, MetalShieldTool, "delay reload for threat", true)
				EquippedTool = ShieldModeRuntimeTable.GetEquippedTool(LocalCharacterModel)
			end
			ShieldModeRuntimeTable.ApplyThreatFacing(LocalCharacterModel, MetalShieldTool, EquippedTool)
			if DebugModeEnabledBoolean then
				DebugLog("shield-reload-defer", "Shield Mode deferred reload because threat pressure from " .. GetCharacterModelDebugName(DelayReloadThreatData and DelayReloadThreatData.character), false)
			end
			return true, nil
		end

		if not ShieldModeRuntimeTable.reloadObserved then
			ShieldModeRuntimeTable.reloadObserved = true
			ShieldModeRuntimeTable.reloadHoldUntilTime = NowNumber + ReloadTimeNumber + 0.05
			ShieldModeRuntimeTable.reloadResumeUntilTime = 0
			if DebugModeEnabledBoolean then
				DebugLog("shield-reloading-start", "Shield Mode started reloading " .. tostring(SecondaryWeaponNameString), false)
			end
		end
		ShieldModeRuntimeTable.pendingReequipTime = 0
		ShieldModeRuntimeTable.secondaryReadyTime = 0
		if EquippedTool ~= SecondaryTool then
			ShieldModeRuntimeTable.TryEquipTool(LocalCharacterModel, SecondaryTool, "reload", true)
		end
		if DebugModeEnabledBoolean then
			DebugLog("shield-reloading", "Shield Mode holding " .. tostring(SecondaryWeaponNameString) .. " while it reloads", false)
		end
		return true, nil
	elseif ShieldModeRuntimeTable.reloadObserved then
		ShieldModeRuntimeTable.reloadObserved = false
		ShieldModeRuntimeTable.reloadHoldUntilTime = NowNumber + ReadyDelayNumber
		ShieldModeRuntimeTable.secondaryReadyTime = NowNumber + ReadyDelayNumber
		ShieldModeRuntimeTable.pendingReequipTime = 0
		ShieldModeRuntimeTable.reloadResumeUntilTime = 0
		ShieldModeRuntimeTable.nextShotTime = math.max(ShieldModeRuntimeTable.nextShotTime, NowNumber + ReadyDelayNumber)
		if DebugModeEnabledBoolean then
			DebugLog("shield-reload-finished", "Shield Mode reload finished for " .. tostring(SecondaryWeaponNameString), false)
		end
	end

	if ShieldModeRuntimeTable.reloadHoldUntilTime > 0 then
		if NowNumber < ShieldModeRuntimeTable.reloadHoldUntilTime then
			if EquippedTool ~= SecondaryTool then
				ShieldModeRuntimeTable.TryEquipTool(LocalCharacterModel, SecondaryTool, "reload recovery", false)
			end
			return true, nil
		end

		ShieldModeRuntimeTable.reloadHoldUntilTime = 0
	end

	if ShieldModeRuntimeTable.pendingReequipTime > 0 and NowNumber >= ShieldModeRuntimeTable.pendingReequipTime then
		ShieldModeRuntimeTable.pendingReequipTime = 0
		if EquippedTool ~= MetalShieldTool then
			ShieldModeRuntimeTable.TryEquipTool(LocalCharacterModel, MetalShieldTool, "post-shot re-equip", true)
			EquippedTool = ShieldModeRuntimeTable.GetEquippedTool(LocalCharacterModel)
		end
	end

	ShieldModeRuntimeTable.ApplyThreatFacing(LocalCharacterModel, MetalShieldTool, EquippedTool)

	if ShieldModeRuntimeTable.reloadDeferredForThreat then
		if DelayReloadBoolean then
			if EquippedTool ~= MetalShieldTool then
				ShieldModeRuntimeTable.TryEquipTool(LocalCharacterModel, MetalShieldTool, "hold shield during deferred reload", true)
			end
			return true, nil
		end

		ShieldModeRuntimeTable.reloadDeferredForThreat = false
		ShieldModeRuntimeTable.reloadResumeUntilTime = NowNumber + ReloadResumeWindowNumber
		if EquippedTool ~= SecondaryTool then
			ShieldModeRuntimeTable.TryEquipTool(LocalCharacterModel, SecondaryTool, "resume deferred reload", true)
		end
		return true, nil
	end

	if ShieldModeRuntimeTable.reloadResumeUntilTime > 0 then
		if AmmoEmptyBoolean then
			if EquippedTool ~= SecondaryTool then
				ShieldModeRuntimeTable.TryEquipTool(LocalCharacterModel, SecondaryTool, "safe reload window", true)
			end
			if NowNumber < ShieldModeRuntimeTable.reloadResumeUntilTime then
				return true, nil
			end
		end

		ShieldModeRuntimeTable.reloadResumeUntilTime = 0
	end

	if AmmoEmptyBoolean then
		ShieldModeRuntimeTable.secondaryReadyTime = 0
		if EquippedTool ~= MetalShieldTool then
			ShieldModeRuntimeTable.TryEquipTool(LocalCharacterModel, MetalShieldTool, "empty secondary hold shield", true)
		end
		return true, nil
	end

	if not WantsShotBoolean then
		ShieldModeRuntimeTable.secondaryReadyTime = 0
		if EquippedTool ~= MetalShieldTool then
			ShieldModeRuntimeTable.TryEquipTool(LocalCharacterModel, MetalShieldTool, "idle", false)
		end
		return true, nil
	end

	if NowNumber < ShieldModeRuntimeTable.nextShotTime then
		ShieldModeRuntimeTable.secondaryReadyTime = 0
		if EquippedTool ~= MetalShieldTool then
			ShieldModeRuntimeTable.TryEquipTool(LocalCharacterModel, MetalShieldTool, "cooldown", false)
		end
		return true, nil
	end

	if EquippedTool ~= SecondaryTool then
		if ShieldModeRuntimeTable.TryEquipTool(LocalCharacterModel, SecondaryTool, "prepare shot", false) then
			ShieldModeRuntimeTable.secondaryReadyTime = NowNumber + ReadyDelayNumber
		end
		return true, nil
	end

	if ShieldModeRuntimeTable.secondaryReadyTime <= 0 then
		ShieldModeRuntimeTable.secondaryReadyTime = NowNumber + ReadyDelayNumber
		return true, nil
	end

	if NowNumber < ShieldModeRuntimeTable.secondaryReadyTime then
		return true, nil
	end

	return true, {
		now = NowNumber,
		shootTime = ShootTimeNumber,
		reequipDelay = ReequipDelayNumber,
		secondaryName = SecondaryWeaponNameString,
	}
end

function ShieldModeRuntimeTable.FinalizeShot(ShotContextTable)
	if not ShotContextTable then
		return
	end

	ShieldModeRuntimeTable.nextShotTime = ShotContextTable.now + ShotContextTable.shootTime
	ShieldModeRuntimeTable.pendingReequipTime = ShotContextTable.now + ShotContextTable.reequipDelay
	ShieldModeRuntimeTable.secondaryReadyTime = 0
	LastAutoFireTimeNumber = ShotContextTable.now
	if DebugModeEnabledBoolean then
		DebugLog("shield-shot", "Shield Mode fired " .. tostring(ShotContextTable.secondaryName) .. " | shootTime=" .. string.format("%.3f", ShotContextTable.shootTime), false)
	end
end

function AppendUniqueIgnoredInstance(IgnoredInstancesTable, IgnoredInstance)
	if not IgnoredInstancesTable or not IgnoredInstance then
		return
	end

	for _, ExistingIgnoredInstance in ipairs(IgnoredInstancesTable) do
		if ExistingIgnoredInstance == IgnoredInstance then
			return
		end
	end

	table.insert(IgnoredInstancesTable, IgnoredInstance)
end

function IsTypingInTextBox()
	if not UserInputService.GetFocusedTextBox then
		return false
	end

	return UserInputService.GetFocusedTextBox(UserInputService) ~= nil
end

function FindPlayerForCharacterModel(CharacterModel)
	if not CharacterModel then
		return nil
	end

	local MatchingPlayerObject = Players.GetPlayerFromCharacter(Players, CharacterModel)
	if MatchingPlayerObject then
		return MatchingPlayerObject
	end

	if IsCustomCharacterGameBoolean then
		for _, PlayerObject in ipairs(Players.GetPlayers(Players)) do
			if FindCustomCharacterForPlayer(PlayerObject) == CharacterModel then
				return PlayerObject
			end
		end
	end

	return nil
end

function IsLocalControlledCharacterModel(CharacterModel, LocalCharacterModel)
	if not CharacterModel then
		return false
	end

	if LocalCharacterModel and CharacterModel == LocalCharacterModel then
		return true
	end

	local Humanoid = GetCharacterHumanoid(CharacterModel)
	if Humanoid and Camera and Camera.CameraSubject == Humanoid then
		return true
	end

	return false
end

ProjectilePreferredTargetPartNamesTable = {
	"HumanoidRootPart",
	"UpperTorso",
	"Torso",
	"LowerTorso",
	"Center",
	"HitboxPart",
	"Head",
}
StandardPreferredTargetPartNamesTable = {
	"HitboxPart",
	"Head",
	"HumanoidRootPart",
	"Torso",
	"Center",
}
PriorityTargetablePartNamesTable = {
	hitboxpart = true,
	head = true,
	humanoidrootpart = true,
	torso = true,
	center = true,
}

function IsPartUnderIgnoredAncestor(PartInstance, CharacterModel)
	local AncestorInstance = PartInstance and PartInstance.Parent or nil
	while AncestorInstance and AncestorInstance ~= CharacterModel do
		if AncestorInstance.IsA(AncestorInstance, "Accessory") or AncestorInstance.IsA(AncestorInstance, "Tool") then
			return true
		end
		AncestorInstance = AncestorInstance.Parent
	end
	return false
end

GetPreferredTargetPart = function(CharacterModel)
	if not CharacterModel then
		return nil
	end

	local PreferProjectileBodyAimBoolean = ShouldPreferProjectileBodyAimForProfile(CurrentWeaponBallisticsProfileTable)
	local PreferredPartNamesInOrderTable = PreferProjectileBodyAimBoolean
		and ProjectilePreferredTargetPartNamesTable
		or StandardPreferredTargetPartNamesTable

	local PrimaryPartInstance = CharacterModel.PrimaryPart
	if PrimaryPartInstance
		and PrimaryPartInstance.IsA(PrimaryPartInstance, "BasePart")
		and not IsPartUnderIgnoredAncestor(PrimaryPartInstance, CharacterModel)
		and (not PreferProjectileBodyAimBoolean or string.lower(PrimaryPartInstance.Name) ~= "head") then
		return PrimaryPartInstance
	end

	for _, PreferredPartNameString in ipairs(PreferredPartNamesInOrderTable) do
		local PreferredPartInstance = CharacterModel.FindFirstChild(CharacterModel, PreferredPartNameString)
		if PreferredPartInstance
			and PreferredPartInstance.IsA(PreferredPartInstance, "BasePart")
			and not IsPartUnderIgnoredAncestor(PreferredPartInstance, CharacterModel) then
			return PreferredPartInstance
		end
	end

	return nil
end

function GetTargetableParts(CharacterModel)
	if not CharacterModel then
		return {}
	end

	local NowNumber = tick()
	local CachedEntryTable = TargetablePartsCacheTable[CharacterModel]
	local FrameIdNumber = tonumber(CurrentFrameSequenceNumber) or 0
	if CachedEntryTable
		and FrameIdNumber > 0
		and CachedEntryTable.frameId == FrameIdNumber then
		return CachedEntryTable.parts
	end

	local ChildCountNumber = #CharacterModel.GetChildren(CharacterModel)
	if CachedEntryTable
		and CachedEntryTable.childCount == ChildCountNumber
		and (NowNumber - CachedEntryTable.time) < TargetablePartsCacheDurationNumber then
		return CachedEntryTable.parts
	end

	local PriorityTargetableParts = {}
	local FallbackTargetableParts = {}
	local SeenPartsTable = {}

	local function AddPartIfTargetable(PartInstance)
		if SeenPartsTable[PartInstance] or not PartInstance.IsA(PartInstance, "BasePart") then
			return
		end

		if IsPartUnderIgnoredAncestor(PartInstance, CharacterModel) then
			return
		end

		SeenPartsTable[PartInstance] = true
		local PartNameLowerString = string.lower(PartInstance.Name)
		if PriorityTargetablePartNamesTable[PartNameLowerString] then
			table.insert(PriorityTargetableParts, PartInstance)
		else
			table.insert(FallbackTargetableParts, PartInstance)
		end
	end

	local PreferredPartInstance = GetPreferredTargetPart(CharacterModel)
	if PreferredPartInstance then
		AddPartIfTargetable(PreferredPartInstance)
	end

	for _, ChildInstance in ipairs(CharacterModel.GetChildren(CharacterModel)) do
		if ChildInstance.IsA(ChildInstance, "BasePart") then
			AddPartIfTargetable(ChildInstance)
		end
	end

	if #PriorityTargetableParts > 0 then
		TargetablePartsCacheTable[CharacterModel] = {
			childCount = ChildCountNumber,
			time = NowNumber,
			frameId = FrameIdNumber,
			parts = PriorityTargetableParts,
		}
		return PriorityTargetableParts
	end

	TargetablePartsCacheTable[CharacterModel] = {
		childCount = ChildCountNumber,
		time = NowNumber,
		frameId = FrameIdNumber,
		parts = FallbackTargetableParts,
	}
	return FallbackTargetableParts
end

GetSearchableCharacterEntries = function(LocalCharacterModel, TeamCheckEnabledBoolean, LocalTeamObject)
	local CacheKeyString = tostring(LocalCharacterModel) .. "|" .. tostring(TeamCheckEnabledBoolean) .. "|" .. tostring(LocalTeamObject)
	local NowNumber = tick()
	if CachedSearchableCharacterEntriesKeyString == CacheKeyString
		and (NowNumber - CachedSearchableCharacterEntriesTimeNumber) < SearchableCharacterEntriesCacheDurationNumber then
		return CachedSearchableCharacterEntriesTable
	end

	local CharacterEntries = {}
	local SeenCharacterModels = {}

	local function AddCharacterEntry(PlayerObject, CharacterModel)
		if not IsHumanoidCharacterModel(CharacterModel) then
			return
		end
		if not GetCharacterRootPart(CharacterModel) then
			return
		end
		if IsLocalControlledCharacterModel(CharacterModel, LocalCharacterModel) then
			return
		end
		if SeenCharacterModels[CharacterModel] then
			return
		end

		if IsCustomCharacterGameBoolean and not PlayerObject then
			return
		end

		if PlayerObject and PlayerListRuntimeTable.IsPlayerWhitelisted(PlayerObject) then
			return
		end

		if TeamCheckEnabledBoolean and PlayerObject and LocalTeamObject and PlayerObject.Team == LocalTeamObject then
			return
		end

		SeenCharacterModels[CharacterModel] = true
		table.insert(CharacterEntries, {
			player = PlayerObject,
			character = CharacterModel,
		})
	end

	if IsCustomCharacterGameBoolean then
		for _, CharacterModel in ipairs(GetCharacterModelsFromCharactersFolder()) do
			local MatchingPlayerObject = FindPlayerForCharacterModel(CharacterModel)
			AddCharacterEntry(MatchingPlayerObject, CharacterModel)
		end
	else
		for _, PlayerObject in ipairs(Players.GetPlayers(Players)) do
			if PlayerObject == LocalPlayer then
				continue
			end

			local CharacterModel = ResolveCharacterModelForPlayer(PlayerObject)
			if CharacterModel then
				AddCharacterEntry(PlayerObject, CharacterModel)
			end
		end
	end

	if DebugModeEnabledBoolean then
		DebugLog("search-pool", "Prepared " .. tostring(#CharacterEntries) .. " searchable character models", false)
	end

	CachedSearchableCharacterEntriesTable = CharacterEntries
	CachedSearchableCharacterEntriesKeyString = CacheKeyString
	CachedSearchableCharacterEntriesTimeNumber = NowNumber
	return CharacterEntries
end


function CreateSectionHeader(SectionTitleString, YOffsetNumber)
	local HeaderFrame = Instance.new("Frame")
	HeaderFrame.Name = SectionTitleString .. "HeaderFrame"
	HeaderFrame.Size = UDim2.new(1, -20, 0, 20)
	HeaderFrame.Position = UDim2.new(0, 10, 0, YOffsetNumber)
	HeaderFrame.BackgroundTransparency = 1
	HeaderFrame.ZIndex = 101
	HeaderFrame.Parent = MenuFrame

	local HeaderLabel = Instance.new("TextLabel")
	HeaderLabel.Name = SectionTitleString .. "HeaderLabel"
	HeaderLabel.Size = UDim2.new(0, 120, 1, 0)
	HeaderLabel.BackgroundTransparency = 1
	HeaderLabel.Text = SectionTitleString
	HeaderLabel.Font = Enum.Font.SourceSansSemibold
	HeaderLabel.TextSize = 14
	HeaderLabel.TextColor3 = Color3.fromRGB(0, 200, 200)
	HeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
	HeaderLabel.ZIndex = 102
	HeaderLabel.Parent = HeaderFrame

	local Divider = Instance.new("Frame")
	Divider.Name = SectionTitleString .. "Divider"
	Divider.Size = UDim2.new(1, -125, 0, 1)
	Divider.Position = UDim2.new(0, 125, 0.5, 0)
	Divider.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	Divider.BorderSizePixel = 0
	Divider.ZIndex = 101
	Divider.Parent = HeaderFrame
end

CreateSectionHeader("Aim Settings", 30)

local SmoothingValueLabel = Instance.new("TextLabel")
SmoothingValueLabel.Name = "SmoothingValueLabel"
SmoothingValueLabel.Size = UDim2.new(1, -10, 0, 20)
SmoothingValueLabel.Position = UDim2.new(0, 5, 0, 52)
SmoothingValueLabel.BackgroundTransparency = 1
SmoothingValueLabel.TextXAlignment = Enum.TextXAlignment.Left
SmoothingValueLabel.Font = Enum.Font.SourceSans
SmoothingValueLabel.TextSize = 16
SmoothingValueLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
SmoothingValueLabel.Text = "Smoothing: " .. string.format("%.2f", AimbotSmoothingNumber)
SmoothingValueLabel.ZIndex = 101
SmoothingValueLabel.Parent = MenuFrame

local SmoothSliderBackFrame = Instance.new("Frame")
SmoothSliderBackFrame.Name = "SmoothSliderBackFrame"
SmoothSliderBackFrame.Size = UDim2.new(1, -20, 0, 8)
SmoothSliderBackFrame.Position = UDim2.new(0, 10, 0, 76)
SmoothSliderBackFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
SmoothSliderBackFrame.BorderSizePixel = 0
SmoothSliderBackFrame.ZIndex = 101
SmoothSliderBackFrame.Parent = MenuFrame

local SmoothSliderFillFrame = Instance.new("Frame")
SmoothSliderFillFrame.Name = "SmoothSliderFillFrame"
SmoothSliderFillFrame.Size = UDim2.new(0, 0, 1, 0)
SmoothSliderFillFrame.Position = UDim2.new(0, 0, 0, 0)
SmoothSliderFillFrame.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
SmoothSliderFillFrame.BorderSizePixel = 0
SmoothSliderFillFrame.ZIndex = 102
SmoothSliderFillFrame.Parent = SmoothSliderBackFrame

local SmoothSliderKnobFrame = Instance.new("Frame")
SmoothSliderKnobFrame.Name = "SmoothSliderKnobFrame"
SmoothSliderKnobFrame.Size = UDim2.new(0, 10, 0, 14)
SmoothSliderKnobFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SmoothSliderKnobFrame.BorderSizePixel = 0
SmoothSliderKnobFrame.ZIndex = 103
SmoothSliderKnobFrame.Parent = SmoothSliderBackFrame

local FovValueLabel = Instance.new("TextLabel")
FovValueLabel.Name = "FovValueLabel"
FovValueLabel.Size = UDim2.new(1, -10, 0, 20)
FovValueLabel.Position = UDim2.new(0, 5, 0, 102)
FovValueLabel.BackgroundTransparency = 1
FovValueLabel.TextXAlignment = Enum.TextXAlignment.Left
FovValueLabel.Font = Enum.Font.SourceSans
FovValueLabel.TextSize = 16
FovValueLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
FovValueLabel.Text = "FOV Radius: " .. tostring(FovCircle.Radius)
FovValueLabel.ZIndex = 101
FovValueLabel.Parent = MenuFrame

local FovSliderBackFrame = Instance.new("Frame")
FovSliderBackFrame.Name = "FovSliderBackFrame"
FovSliderBackFrame.Size = UDim2.new(1, -20, 0, 8)
FovSliderBackFrame.Position = UDim2.new(0, 10, 0, 126)
FovSliderBackFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
FovSliderBackFrame.BorderSizePixel = 0
FovSliderBackFrame.ZIndex = 101
FovSliderBackFrame.Parent = MenuFrame

local FovSliderFillFrame = Instance.new("Frame")
FovSliderFillFrame.Name = "FovSliderFillFrame"
FovSliderFillFrame.Size = UDim2.new(0, 0, 1, 0)
FovSliderFillFrame.Position = UDim2.new(0, 0, 0, 0)
FovSliderFillFrame.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
FovSliderFillFrame.BorderSizePixel = 0
FovSliderFillFrame.ZIndex = 102
FovSliderFillFrame.Parent = FovSliderBackFrame

local FovSliderKnobFrame = Instance.new("Frame")
FovSliderKnobFrame.Name = "FovSliderKnobFrame"
FovSliderKnobFrame.Size = UDim2.new(0, 10, 0, 14)
FovSliderKnobFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FovSliderKnobFrame.BorderSizePixel = 0
FovSliderKnobFrame.ZIndex = 103
FovSliderKnobFrame.Parent = FovSliderBackFrame

local HeadshotToggleButton = Instance.new("TextButton")
HeadshotToggleButton.Name = "HeadshotToggleButton"
HeadshotToggleButton.Size = UDim2.new(1, -20, 0, 20)
HeadshotToggleButton.Position = UDim2.new(0, 10, 0, 172)
HeadshotToggleButton.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
HeadshotToggleButton.BorderSizePixel = 0
HeadshotToggleButton.Text = "Headshot Priority: OFF"
HeadshotToggleButton.Font = Enum.Font.SourceSans
HeadshotToggleButton.TextSize = 16
HeadshotToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HeadshotToggleButton.ZIndex = 101
HeadshotToggleButton.Parent = MenuFrame

local AutoFireToggleButton = Instance.new("TextButton")
AutoFireToggleButton.Name = "AutoFireToggleButton"
AutoFireToggleButton.Size = UDim2.new(1, -20, 0, 20)
AutoFireToggleButton.Position = UDim2.new(0, 10, 0, 196)
AutoFireToggleButton.BackgroundColor3 = Color3.fromRGB(0, 60, 120)
AutoFireToggleButton.BorderSizePixel = 0
AutoFireToggleButton.Text = "Auto Fire: ON"
AutoFireToggleButton.Font = Enum.Font.SourceSans
AutoFireToggleButton.TextSize = 16
AutoFireToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoFireToggleButton.ZIndex = 101
AutoFireToggleButton.Parent = MenuFrame

local VisibleCheckToggleButton = Instance.new("TextButton")
VisibleCheckToggleButton.Name = "VisibleCheckToggleButton"
VisibleCheckToggleButton.Size = UDim2.new(1, -20, 0, 20)
VisibleCheckToggleButton.Position = UDim2.new(0, 10, 0, 220)
VisibleCheckToggleButton.BackgroundColor3 = Color3.fromRGB(0, 80, 80)
VisibleCheckToggleButton.BorderSizePixel = 0
VisibleCheckToggleButton.Text = "Visible Check: ON"
VisibleCheckToggleButton.Font = Enum.Font.SourceSans
VisibleCheckToggleButton.TextSize = 16
VisibleCheckToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
VisibleCheckToggleButton.ZIndex = 101
VisibleCheckToggleButton.Parent = MenuFrame

local TargetSegmentationToggleButton = Instance.new("TextButton")
TargetSegmentationToggleButton.Name = "TargetSegmentationToggleButton"
TargetSegmentationToggleButton.Size = UDim2.new(1, -20, 0, 20)
TargetSegmentationToggleButton.Position = UDim2.new(0, 10, 0, 244)
TargetSegmentationToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
TargetSegmentationToggleButton.BorderSizePixel = 0
TargetSegmentationToggleButton.Text = "Sectioning: OFF"
TargetSegmentationToggleButton.Font = Enum.Font.SourceSans
TargetSegmentationToggleButton.TextSize = 16
TargetSegmentationToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetSegmentationToggleButton.ZIndex = 101
TargetSegmentationToggleButton.Parent = MenuFrame

local FovToggleButton = Instance.new("TextButton")
FovToggleButton.Name = "FovToggleButton"
FovToggleButton.Size = UDim2.new(1, -20, 0, 20)
FovToggleButton.Position = UDim2.new(0, 10, 0, 300)
FovToggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
FovToggleButton.BorderSizePixel = 0
FovToggleButton.Text = "FOV Circle: ON"
FovToggleButton.Font = Enum.Font.SourceSans
FovToggleButton.TextSize = 16
FovToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FovToggleButton.ZIndex = 101
FovToggleButton.Parent = MenuFrame

local TargetLineToggleButton = Instance.new("TextButton")
TargetLineToggleButton.Name = "TargetLineToggleButton"
TargetLineToggleButton.Size = UDim2.new(1, -20, 0, 20)
TargetLineToggleButton.Position = UDim2.new(0, 10, 0, 324)
TargetLineToggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
TargetLineToggleButton.BorderSizePixel = 0
TargetLineToggleButton.Text = "Target Line: ON"
TargetLineToggleButton.Font = Enum.Font.SourceSans
TargetLineToggleButton.TextSize = 16
TargetLineToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetLineToggleButton.ZIndex = 101
TargetLineToggleButton.Parent = MenuFrame

local LockKeyToggleButton = Instance.new("TextButton")
LockKeyToggleButton.Name = "LockKeyToggleButton"
LockKeyToggleButton.Size = UDim2.new(1, -20, 0, 20)
LockKeyToggleButton.Position = UDim2.new(0, 10, 0, 376)
LockKeyToggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 0)
LockKeyToggleButton.BorderSizePixel = 0
LockKeyToggleButton.Text = "Lock Key: RMB"
LockKeyToggleButton.Font = Enum.Font.SourceSans
LockKeyToggleButton.TextSize = 16
LockKeyToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LockKeyToggleButton.ZIndex = 101
LockKeyToggleButton.Parent = MenuFrame

local HookMethodToggleButton = Instance.new("TextButton")
HookMethodToggleButton.Name = "HookMethodToggleButton"
HookMethodToggleButton.Size = UDim2.new(1, -20, 0, 20)
HookMethodToggleButton.Position = UDim2.new(0, 10, 0, 400)
HookMethodToggleButton.BackgroundColor3 = Color3.fromRGB(80, 40, 120)
HookMethodToggleButton.BorderSizePixel = 0
HookMethodToggleButton.Text = "Method: Hook"
HookMethodToggleButton.Font = Enum.Font.SourceSans
HookMethodToggleButton.TextSize = 16
HookMethodToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HookMethodToggleButton.ZIndex = 101
HookMethodToggleButton.Parent = MenuFrame

local StickyAimToggleButton = Instance.new("TextButton")
StickyAimToggleButton.Name = "StickyAimToggleButton"
StickyAimToggleButton.Size = UDim2.new(1, -20, 0, 20)
StickyAimToggleButton.Position = UDim2.new(0, 10, 0, 424)
StickyAimToggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
StickyAimToggleButton.BorderSizePixel = 0
StickyAimToggleButton.Text = "Sticky Aim: OFF"
StickyAimToggleButton.Font = Enum.Font.SourceSans
StickyAimToggleButton.TextSize = 16
StickyAimToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StickyAimToggleButton.ZIndex = 101
StickyAimToggleButton.Parent = MenuFrame

local HookHitChanceValueLabel = Instance.new("TextLabel")
HookHitChanceValueLabel.Name = "HookHitChanceValueLabel"
HookHitChanceValueLabel.Size = UDim2.new(1, -10, 0, 20)
HookHitChanceValueLabel.Position = UDim2.new(0, 5, 0, 448)
HookHitChanceValueLabel.BackgroundTransparency = 1
HookHitChanceValueLabel.TextXAlignment = Enum.TextXAlignment.Left
HookHitChanceValueLabel.Font = Enum.Font.SourceSans
HookHitChanceValueLabel.TextSize = 16
HookHitChanceValueLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
HookHitChanceValueLabel.Text = "Hook Hit Chance: " .. tostring(math.floor(NormalHookHitChanceNumber + 0.5)) .. "%"
HookHitChanceValueLabel.ZIndex = 101
HookHitChanceValueLabel.Parent = MenuFrame

local HookHitChanceSliderBackFrame = Instance.new("Frame")
HookHitChanceSliderBackFrame.Name = "HookHitChanceSliderBackFrame"
HookHitChanceSliderBackFrame.Size = UDim2.new(1, -20, 0, 8)
HookHitChanceSliderBackFrame.Position = UDim2.new(0, 10, 0, 472)
HookHitChanceSliderBackFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
HookHitChanceSliderBackFrame.BorderSizePixel = 0
HookHitChanceSliderBackFrame.ZIndex = 101
HookHitChanceSliderBackFrame.Parent = MenuFrame

local HookHitChanceSliderFillFrame = Instance.new("Frame")
HookHitChanceSliderFillFrame.Name = "HookHitChanceSliderFillFrame"
HookHitChanceSliderFillFrame.Size = UDim2.new(0, 0, 1, 0)
HookHitChanceSliderFillFrame.Position = UDim2.new(0, 0, 0, 0)
HookHitChanceSliderFillFrame.BackgroundColor3 = Color3.fromRGB(220, 165, 0)
HookHitChanceSliderFillFrame.BorderSizePixel = 0
HookHitChanceSliderFillFrame.ZIndex = 102
HookHitChanceSliderFillFrame.Parent = HookHitChanceSliderBackFrame

local HookHitChanceSliderKnobFrame = Instance.new("Frame")
HookHitChanceSliderKnobFrame.Name = "HookHitChanceSliderKnobFrame"
HookHitChanceSliderKnobFrame.Size = UDim2.new(0, 10, 0, 14)
HookHitChanceSliderKnobFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
HookHitChanceSliderKnobFrame.BorderSizePixel = 0
HookHitChanceSliderKnobFrame.ZIndex = 103
HookHitChanceSliderKnobFrame.Parent = HookHitChanceSliderBackFrame

local SillyModeToggleButton = nil
local ShieldModeToggleButton = nil
local SillySkyVisibilityToggleButton = nil
if IsBloodZonePlaceBoolean then
	SillyModeToggleButton = Instance.new("TextButton")
	SillyModeToggleButton.Name = "SillyModeToggleButton"
	SillyModeToggleButton.Size = UDim2.new(1, -20, 0, 20)
	SillyModeToggleButton.Position = UDim2.new(0, 10, 0, 500)
	SillyModeToggleButton.BackgroundColor3 = Color3.fromRGB(80, 30, 80)
	SillyModeToggleButton.BorderSizePixel = 0
	SillyModeToggleButton.Text = "Silly Mode: OFF"
	SillyModeToggleButton.Font = Enum.Font.SourceSans
	SillyModeToggleButton.TextSize = 16
	SillyModeToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	SillyModeToggleButton.ZIndex = 101
	SillyModeToggleButton.Parent = MenuFrame

	ShieldModeToggleButton = Instance.new("TextButton")
	ShieldModeToggleButton.Name = "ShieldModeToggleButton"
	ShieldModeToggleButton.Size = UDim2.new(1, -20, 0, 20)
	ShieldModeToggleButton.Position = UDim2.new(0, 10, 0, 524)
	ShieldModeToggleButton.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
	ShieldModeToggleButton.BorderSizePixel = 0
	ShieldModeToggleButton.Text = "Shield Mode: LOCKED"
	ShieldModeToggleButton.Font = Enum.Font.SourceSans
	ShieldModeToggleButton.TextSize = 16
	ShieldModeToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	ShieldModeToggleButton.ZIndex = 101
	ShieldModeToggleButton.Parent = MenuFrame

	SillySkyVisibilityToggleButton = Instance.new("TextButton")
	SillySkyVisibilityToggleButton.Name = "SillySkyVisibilityToggleButton"
	SillySkyVisibilityToggleButton.Size = UDim2.new(1, -20, 0, 20)
	SillySkyVisibilityToggleButton.Position = UDim2.new(0, 10, 0, 548)
	SillySkyVisibilityToggleButton.BackgroundColor3 = Color3.fromRGB(45, 65, 90)
	SillySkyVisibilityToggleButton.BorderSizePixel = 0
	SillySkyVisibilityToggleButton.Text = "Sky Vis Check: LOCKED"
	SillySkyVisibilityToggleButton.Font = Enum.Font.SourceSans
	SillySkyVisibilityToggleButton.TextSize = 16
	SillySkyVisibilityToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	SillySkyVisibilityToggleButton.ZIndex = 101
	SillySkyVisibilityToggleButton.Parent = MenuFrame
end

EspToggleButton = Instance.new("TextButton")
EspToggleButton.Name = "EspToggleButton"
EspToggleButton.Size = UDim2.new(1, -20, 0, 20)
EspToggleButton.Position = UDim2.new(0, 10, 0, IsBloodZonePlaceBoolean and 606 or 530)
EspToggleButton.BackgroundColor3 = Color3.fromRGB(45, 105, 65)
EspToggleButton.BorderSizePixel = 0
EspToggleButton.Text = "ESP: ON"
EspToggleButton.Font = Enum.Font.SourceSans
EspToggleButton.TextSize = 16
EspToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
EspToggleButton.ZIndex = 101
EspToggleButton.Parent = MenuFrame

EspSkeletonToggleButton = Instance.new("TextButton")
EspSkeletonToggleButton.Name = "EspSkeletonToggleButton"
EspSkeletonToggleButton.Size = UDim2.new(1, -20, 0, 20)
EspSkeletonToggleButton.Position = UDim2.new(0, 10, 0, IsBloodZonePlaceBoolean and 630 or 554)
EspSkeletonToggleButton.BackgroundColor3 = Color3.fromRGB(40, 85, 60)
EspSkeletonToggleButton.BorderSizePixel = 0
EspSkeletonToggleButton.Text = "Skeleton ESP: ON"
EspSkeletonToggleButton.Font = Enum.Font.SourceSans
EspSkeletonToggleButton.TextSize = 16
EspSkeletonToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
EspSkeletonToggleButton.ZIndex = 101
EspSkeletonToggleButton.Parent = MenuFrame

EspHighlightToggleButton = Instance.new("TextButton")
EspHighlightToggleButton.Name = "EspHighlightToggleButton"
EspHighlightToggleButton.Size = UDim2.new(1, -20, 0, 20)
EspHighlightToggleButton.Position = UDim2.new(0, 10, 0, IsBloodZonePlaceBoolean and 654 or 578)
EspHighlightToggleButton.BackgroundColor3 = Color3.fromRGB(60, 90, 115)
EspHighlightToggleButton.BorderSizePixel = 0
EspHighlightToggleButton.Text = "Highlight ESP: ON"
EspHighlightToggleButton.Font = Enum.Font.SourceSans
EspHighlightToggleButton.TextSize = 16
EspHighlightToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
EspHighlightToggleButton.ZIndex = 101
EspHighlightToggleButton.Parent = MenuFrame

ApplyAimbotUiDecoration(SmoothSliderBackFrame, 4, Color3.fromRGB(55, 105, 155))
ApplyAimbotUiDecoration(SmoothSliderKnobFrame, 4, Color3.fromRGB(170, 205, 235))
ApplyAimbotUiDecoration(FovSliderBackFrame, 4, Color3.fromRGB(55, 135, 105))
ApplyAimbotUiDecoration(FovSliderKnobFrame, 4, Color3.fromRGB(175, 235, 205))
ApplyAimbotUiDecoration(HookHitChanceSliderBackFrame, 4, Color3.fromRGB(145, 115, 45))
ApplyAimbotUiDecoration(HookHitChanceSliderKnobFrame, 4, Color3.fromRGB(240, 215, 155))
ApplyAimbotUiDecoration(HeadshotToggleButton, 5, Color3.fromRGB(130, 70, 80))
ApplyAimbotUiDecoration(AutoFireToggleButton, 5, Color3.fromRGB(55, 115, 175))
ApplyAimbotUiDecoration(VisibleCheckToggleButton, 5, Color3.fromRGB(45, 140, 140))
ApplyAimbotUiDecoration(TargetSegmentationToggleButton, 5, Color3.fromRGB(85, 95, 110))
ApplyAimbotUiDecoration(FovToggleButton, 5, Color3.fromRGB(90, 105, 120))
ApplyAimbotUiDecoration(TargetLineToggleButton, 5, Color3.fromRGB(90, 105, 120))
ApplyAimbotUiDecoration(LockKeyToggleButton, 5, Color3.fromRGB(135, 125, 45))
ApplyAimbotUiDecoration(HookMethodToggleButton, 5, Color3.fromRGB(120, 80, 160))
ApplyAimbotUiDecoration(StickyAimToggleButton, 5, Color3.fromRGB(95, 105, 120))
ApplyAimbotUiDecoration(EspToggleButton, 5, Color3.fromRGB(70, 130, 90))
ApplyAimbotUiDecoration(EspSkeletonToggleButton, 5, Color3.fromRGB(65, 110, 85))
ApplyAimbotUiDecoration(EspHighlightToggleButton, 5, Color3.fromRGB(85, 120, 150))
if SillyModeToggleButton then
	ApplyAimbotUiDecoration(SillyModeToggleButton, 5, Color3.fromRGB(135, 70, 145))
end
if ShieldModeToggleButton then
	ApplyAimbotUiDecoration(ShieldModeToggleButton, 5, Color3.fromRGB(85, 100, 145))
end
if SillySkyVisibilityToggleButton then
	ApplyAimbotUiDecoration(SillySkyVisibilityToggleButton, 5, Color3.fromRGB(70, 115, 155))
end

CreateAimbotSectionSurface("AimSettingsSurfaceFrame", 44, 100)
CreateAimbotSectionSurface("TargetingSurfaceFrame", 164, 106)
CreateAimbotSectionSurface("VisibilitySurfaceFrame", 288, 60)
CreateAimbotSectionSurface("BehaviorSurfaceFrame", 368, IsBloodZonePlaceBoolean and 202 or 126)
CreateAimbotSectionSurface("EspSurfaceFrame", IsBloodZonePlaceBoolean and 594 or 518, 84)

CreateSectionHeader("Targeting", 150)
CreateSectionHeader("Visibility", 274)
CreateSectionHeader("Behavior", 354)
CreateSectionHeader("ESP", IsBloodZonePlaceBoolean and 580 or 504)

function UpdateHeadshotButtonAppearance()
	if IsSillyModeBehaviorActive() then
		HeadshotToggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
		HeadshotToggleButton.Text = "Headshot Priority: ON (Silly)"
	elseif HeadshotPriorityBoolean then
		HeadshotToggleButton.BackgroundColor3 = Color3.fromRGB(0, 130, 0)
		HeadshotToggleButton.Text = "Headshot Priority: ON"
	else
		HeadshotToggleButton.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
		HeadshotToggleButton.Text = "Headshot Priority: OFF"
	end
end

function UpdateAutoFireButtonAppearance()
	if IsSillyModeBehaviorActive() then
		AutoFireToggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		AutoFireToggleButton.Text = "Auto Fire: ON (Silly)"
	elseif AutoFireEnabledBoolean then
		AutoFireToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 220)
		AutoFireToggleButton.Text = "Auto Fire: ON"
	else
		AutoFireToggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		AutoFireToggleButton.Text = "Auto Fire: OFF"
	end
end

function UpdateVisibleCheckButtonAppearance()
	if IsSillyModeBehaviorActive() then
		VisibleCheckToggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 150)
		VisibleCheckToggleButton.Text = "Visible Check: ON (Silly)"
	elseif VisibleCheckEnabledBoolean then
		VisibleCheckToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 120)
		VisibleCheckToggleButton.Text = "Visible Check: ON"
	else
		VisibleCheckToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		VisibleCheckToggleButton.Text = "Visible Check: OFF"
	end
end

function UpdateTargetSegmentationButtonAppearance()
	if IsSillyModeBehaviorActive() then
		TargetSegmentationToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		TargetSegmentationToggleButton.Text = "Sectioning: OFF (Silly)"
	elseif TargetSegmentationEnabledBoolean then
		TargetSegmentationToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 120)
		TargetSegmentationToggleButton.Text = "Sectioning: ON"
	else
		TargetSegmentationToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		TargetSegmentationToggleButton.Text = "Sectioning: OFF"
	end
end

function UpdateFovToggleButtonAppearance()
	if IsSillyModeBehaviorActive() then
		FovToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		FovToggleButton.Text = "FOV Circle: OFF (Silly)"
	elseif ShowFovCircleBoolean then
		FovToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 120)
		FovToggleButton.Text = "FOV Circle: ON"
	else
		FovToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		FovToggleButton.Text = "FOV Circle: OFF"
	end
end

function UpdateTargetLineToggleButtonAppearance()
	if ShowTargetLineBoolean then
		TargetLineToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 120)
		TargetLineToggleButton.Text = "Target Line: ON"
	else
		TargetLineToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		TargetLineToggleButton.Text = "Target Line: OFF"
	end
end

function UpdateHookMethodButtonAppearance()
	if IsSillyModeBehaviorActive() then
		HookMethodToggleButton.BackgroundColor3 = Color3.fromRGB(180, 70, 220)
		HookMethodToggleButton.Text = "Method: Hook (Silly)"
	elseif UseHookMethodBoolean and UseCameraMethodBoolean then
		HookMethodToggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 150)
		HookMethodToggleButton.Text = "Method: Both"
	elseif UseHookMethodBoolean then
		HookMethodToggleButton.BackgroundColor3 = Color3.fromRGB(150, 70, 200)
		HookMethodToggleButton.Text = "Method: Hook"
	else
		HookMethodToggleButton.BackgroundColor3 = Color3.fromRGB(80, 40, 120)
		HookMethodToggleButton.Text = "Method: Camera"
	end
end

function UpdateStickyAimButtonAppearance()
	if IsSillyModeBehaviorActive() then
		StickyAimToggleButton.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
		StickyAimToggleButton.Text = "Sticky Aim: LOCKED (Silly)"
	elseif StickyAimEnabledBoolean then
		StickyAimToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 90)
		StickyAimToggleButton.Text = "Sticky Aim: ON"
	else
		StickyAimToggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		StickyAimToggleButton.Text = "Sticky Aim: OFF"
	end
end

function UpdateHookHitChanceSliderAppearance()
	local HitChanceNumber = math.clamp(tonumber(NormalHookHitChanceNumber) or 100, 0, 100)
	local RatioNumber = (HitChanceNumber - MinNormalHookHitChanceNumber) / (MaxNormalHookHitChanceNumber - MinNormalHookHitChanceNumber)
	RatioNumber = math.clamp(RatioNumber, 0, 1)

	if IsSillyModeBehaviorActive() then
		HookHitChanceValueLabel.TextColor3 = Color3.fromRGB(145, 145, 145)
		HookHitChanceValueLabel.Text = "Hook Hit Chance: " .. tostring(math.floor(HitChanceNumber + 0.5)) .. "% (Locked in Silly)"
		HookHitChanceSliderBackFrame.BackgroundColor3 = Color3.fromRGB(52, 52, 52)
		HookHitChanceSliderFillFrame.BackgroundColor3 = Color3.fromRGB(110, 110, 110)
	else
		HookHitChanceValueLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
		HookHitChanceValueLabel.Text = "Hook Hit Chance: " .. tostring(math.floor(HitChanceNumber + 0.5)) .. "%"
		HookHitChanceSliderBackFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		HookHitChanceSliderFillFrame.BackgroundColor3 = Color3.fromRGB(220, 165, 0)
	end

	local KnobWidthNumber = HookHitChanceSliderKnobFrame.AbsoluteSize.X
	HookHitChanceSliderFillFrame.Size = UDim2.new(RatioNumber, 0, 1, 0)
	HookHitChanceSliderKnobFrame.Position = UDim2.new(RatioNumber, -KnobWidthNumber / 2, 0.5, -HookHitChanceSliderKnobFrame.AbsoluteSize.Y / 2)
end

function GetCurrentLockKeyMode()
	return LockKeyModesTable[LockKeyModeIndexNumber] or "RMB"
end

function AdvanceLockKeyMode()
	LockKeyModeIndexNumber = LockKeyModeIndexNumber + 1
	if LockKeyModeIndexNumber > #LockKeyModesTable then
		LockKeyModeIndexNumber = 1
	end
	SchedulePersistentStateSave()
	return GetCurrentLockKeyMode()
end

function UpdateLockKeyButtonAppearance()
	if IsSillyModeBehaviorActive() then
		LockKeyToggleButton.BackgroundColor3 = Color3.fromRGB(180, 80, 0)
		LockKeyToggleButton.Text = "Lock Key: Always (Silly)"
		return
	end

	local LockKeyModeString = GetCurrentLockKeyMode()
	if LockKeyModeString == "Always" then
		LockKeyToggleButton.BackgroundColor3 = Color3.fromRGB(180, 80, 0)
		LockKeyToggleButton.Text = "Lock Key: Always"
	elseif LockKeyModeString == "E" then
		LockKeyToggleButton.BackgroundColor3 = Color3.fromRGB(0, 130, 130)
		LockKeyToggleButton.Text = "Lock Key: E"
	else
		LockKeyToggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 0)
		LockKeyToggleButton.Text = "Lock Key: RMB"
	end
end

function UpdateSillyModeButtonAppearance()
	if not SillyModeToggleButton then
		return
	end

	if IsSillyModeBehaviorActive() then
		SillyModeToggleButton.BackgroundColor3 = Color3.fromRGB(190, 60, 190)
		SillyModeToggleButton.Text = "Silly Mode: ON"
	elseif IsSillyModeEnabled() then
		SillyModeToggleButton.BackgroundColor3 = Color3.fromRGB(130, 45, 130)
		SillyModeToggleButton.Text = "Silly Mode: ARMED (Need Tool)"
	else
		SillyModeToggleButton.BackgroundColor3 = Color3.fromRGB(80, 30, 80)
		SillyModeToggleButton.Text = "Silly Mode: OFF"
	end
end

function UpdateShieldModeButtonAppearance()
	if not ShieldModeToggleButton then
		return
	end

	if IsEffectiveShieldModeEnabled() then
		ShieldModeToggleButton.BackgroundColor3 = Color3.fromRGB(90, 120, 220)
		ShieldModeToggleButton.Text = "Shield Mode: ON"
	elseif ShieldModeEnabledBoolean and IsSillyModeEnabled() then
		ShieldModeToggleButton.BackgroundColor3 = Color3.fromRGB(70, 90, 170)
		ShieldModeToggleButton.Text = "Shield Mode: ARMED (Need Tool)"
	elseif IsSillyModeEnabled() then
		ShieldModeToggleButton.BackgroundColor3 = Color3.fromRGB(55, 85, 170)
		ShieldModeToggleButton.Text = "Shield Mode: OFF"
	else
		ShieldModeToggleButton.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
		ShieldModeToggleButton.Text = "Shield Mode: LOCKED (Need Silly)"
	end
end

function UpdateSillySkyVisibilityButtonAppearance()
	if not SillySkyVisibilityToggleButton then
		return
	end

	if IsSillyModeBehaviorActive() and SillySkyAimEnabledBoolean and not ShieldModeEnabledBoolean and SillySkyVisibilityCheckEnabledBoolean then
		SillySkyVisibilityToggleButton.BackgroundColor3 = Color3.fromRGB(70, 130, 185)
		SillySkyVisibilityToggleButton.Text = "Sky Vis Check: ON"
	elseif not IsSillyModeEnabled() then
		SillySkyVisibilityToggleButton.BackgroundColor3 = Color3.fromRGB(45, 65, 90)
		SillySkyVisibilityToggleButton.Text = "Sky Vis Check: LOCKED (Need Silly)"
	elseif not SillySkyVisibilityCheckEnabledBoolean then
		SillySkyVisibilityToggleButton.BackgroundColor3 = Color3.fromRGB(45, 75, 105)
		SillySkyVisibilityToggleButton.Text = "Sky Vis Check: OFF"
	elseif ShieldModeEnabledBoolean then
		SillySkyVisibilityToggleButton.BackgroundColor3 = Color3.fromRGB(55, 70, 95)
		SillySkyVisibilityToggleButton.Text = "Sky Vis Check: LOCKED (Shield ON)"
	elseif not SillySkyAimEnabledBoolean then
		SillySkyVisibilityToggleButton.BackgroundColor3 = Color3.fromRGB(55, 70, 95)
		SillySkyVisibilityToggleButton.Text = "Sky Vis Check: LOCKED (Sky Aim OFF)"
	else
		SillySkyVisibilityToggleButton.BackgroundColor3 = Color3.fromRGB(60, 100, 145)
		SillySkyVisibilityToggleButton.Text = "Sky Vis Check: ARMED (Need Tool)"
	end
end

function UpdateEspToggleButtonAppearance()
	if EspEnabledBoolean then
		EspToggleButton.BackgroundColor3 = Color3.fromRGB(0, 125, 75)
		EspToggleButton.Text = "ESP: ON"
	else
		EspToggleButton.BackgroundColor3 = Color3.fromRGB(55, 65, 60)
		EspToggleButton.Text = "ESP: OFF"
	end
end

function UpdateEspSkeletonToggleButtonAppearance()
	if not EspEnabledBoolean then
		EspSkeletonToggleButton.BackgroundColor3 = Color3.fromRGB(50, 58, 54)
		EspSkeletonToggleButton.Text = "Skeleton ESP: LOCKED"
	elseif EspSkeletonEnabledBoolean then
		EspSkeletonToggleButton.BackgroundColor3 = Color3.fromRGB(0, 110, 80)
		EspSkeletonToggleButton.Text = "Skeleton ESP: ON"
	else
		EspSkeletonToggleButton.BackgroundColor3 = Color3.fromRGB(55, 70, 60)
		EspSkeletonToggleButton.Text = "Skeleton ESP: OFF"
	end
end

function UpdateEspHighlightToggleButtonAppearance()
	if not EspEnabledBoolean then
		EspHighlightToggleButton.BackgroundColor3 = Color3.fromRGB(52, 58, 62)
		EspHighlightToggleButton.Text = "Highlight ESP: LOCKED"
	elseif EspHighlightEnabledBoolean then
		EspHighlightToggleButton.BackgroundColor3 = Color3.fromRGB(55, 125, 165)
		EspHighlightToggleButton.Text = "Highlight ESP: ON"
	else
		EspHighlightToggleButton.BackgroundColor3 = Color3.fromRGB(60, 72, 82)
		EspHighlightToggleButton.Text = "Highlight ESP: OFF"
	end
end

function RefreshBloodZoneBehaviorButtons()
	UpdateHeadshotButtonAppearance()
	UpdateAutoFireButtonAppearance()
	UpdateVisibleCheckButtonAppearance()
	UpdateTargetSegmentationButtonAppearance()
	UpdateFovToggleButtonAppearance()
	UpdateLockKeyButtonAppearance()
	UpdateHookMethodButtonAppearance()
	UpdateStickyAimButtonAppearance()
	UpdateHookHitChanceSliderAppearance()
	UpdateSillyModeButtonAppearance()
	UpdateShieldModeButtonAppearance()
	UpdateSillySkyVisibilityButtonAppearance()
end

function ToggleSillyMode()
	if not IsBloodZonePlaceBoolean then
		return
	end

	SillyModeEnabledBoolean = not SillyModeEnabledBoolean
	if not SillyModeEnabledBoolean then
		SillySkyAimEnabledBoolean = true
	end

	RefreshBloodZoneBehaviorButtons()
	UpdateDebugStatus("silly mode=" .. tostring(SillyModeEnabledBoolean) .. " sky aim=" .. tostring(SillySkyAimEnabledBoolean))
	DebugLog("toggle-silly", "Silly Mode set to " .. tostring(SillyModeEnabledBoolean) .. " | sky aim=" .. tostring(SillySkyAimEnabledBoolean), true)
	SchedulePersistentStateSave()
end

local SetTargetCubeVisible

HeadshotToggleButton.MouseButton1Click.Connect(HeadshotToggleButton.MouseButton1Click, function()
	if IsAimbotUiInputSuppressed() then
		return
	end
	HeadshotPriorityBoolean = not HeadshotPriorityBoolean
	UpdateHeadshotButtonAppearance()
	SchedulePersistentStateSave()
end)

AutoFireToggleButton.MouseButton1Click.Connect(AutoFireToggleButton.MouseButton1Click, function()
	if IsAimbotUiInputSuppressed() then
		return
	end
	AutoFireEnabledBoolean = not AutoFireEnabledBoolean
	UpdateAutoFireButtonAppearance()
	SchedulePersistentStateSave()
end)

VisibleCheckToggleButton.MouseButton1Click.Connect(VisibleCheckToggleButton.MouseButton1Click, function()
	if IsAimbotUiInputSuppressed() then
		return
	end
	VisibleCheckEnabledBoolean = not VisibleCheckEnabledBoolean
	UpdateVisibleCheckButtonAppearance()
	UpdateDebugStatus("visible check=" .. tostring(VisibleCheckEnabledBoolean))
	DebugLog("toggle-visible", "Visible check set to " .. tostring(VisibleCheckEnabledBoolean), true)
	SchedulePersistentStateSave()
end)

TargetSegmentationToggleButton.MouseButton1Click.Connect(TargetSegmentationToggleButton.MouseButton1Click, function()
	if IsAimbotUiInputSuppressed() then
		return
	end
	TargetSegmentationEnabledBoolean = not TargetSegmentationEnabledBoolean
	UpdateTargetSegmentationButtonAppearance()
	CurrentTargetPointVector3 = nil
	CurrentTargetAimPointVector3 = nil
	CurrentTargetLocalPointVector3 = nil
	CurrentTargetCubeCFrame = nil
	CurrentTargetCubeSize = nil
	TargetLine.Visible = false
	if SetTargetCubeVisible then
		SetTargetCubeVisible(false)
	end
	UpdateDebugStatus("sectioning=" .. tostring(TargetSegmentationEnabledBoolean))
	DebugLog("toggle-segmentation", "Sectioning set to " .. tostring(TargetSegmentationEnabledBoolean), true)
	SchedulePersistentStateSave()
end)

FovToggleButton.MouseButton1Click.Connect(FovToggleButton.MouseButton1Click, function()
	if IsAimbotUiInputSuppressed() then
		return
	end
	ShowFovCircleBoolean = not ShowFovCircleBoolean
	UpdateFovToggleButtonAppearance()
	SchedulePersistentStateSave()
end)

TargetLineToggleButton.MouseButton1Click.Connect(TargetLineToggleButton.MouseButton1Click, function()
	if IsAimbotUiInputSuppressed() then
		return
	end
	ShowTargetLineBoolean = not ShowTargetLineBoolean
	UpdateTargetLineToggleButtonAppearance()
	TargetLine.Visible = false
	SetTargetCubeVisible(false)
	UpdateDebugStatus("target line=" .. tostring(ShowTargetLineBoolean))
	DebugLog("toggle-line", "Target line set to " .. tostring(ShowTargetLineBoolean), true)
	SchedulePersistentStateSave()
end)

LockKeyToggleButton.MouseButton1Click.Connect(LockKeyToggleButton.MouseButton1Click, function()
	if IsAimbotUiInputSuppressed() then
		return
	end
	AdvanceLockKeyMode()
	UpdateLockKeyButtonAppearance()
end)

HookMethodToggleButton.MouseButton1Click.Connect(HookMethodToggleButton.MouseButton1Click, function()
	if IsAimbotUiInputSuppressed() then
		return
	end
	if UseHookMethodBoolean and not UseCameraMethodBoolean then
		UseHookMethodBoolean = true
		UseCameraMethodBoolean = true
	elseif UseHookMethodBoolean and UseCameraMethodBoolean then
		UseHookMethodBoolean = false
		UseCameraMethodBoolean = true
	else
		UseHookMethodBoolean = true
		UseCameraMethodBoolean = false
	end
	ResetNormalHookHitChanceDecision()
	UpdateHookMethodButtonAppearance()
	SchedulePersistentStateSave()
end)

StickyAimToggleButton.MouseButton1Click.Connect(StickyAimToggleButton.MouseButton1Click, function()
	if IsAimbotUiInputSuppressed() then
		return
	end
	if IsSillyModeBehaviorActive() then
		UpdateDebugStatus("sticky aim locked while silly mode active")
		DebugLog("toggle-sticky-locked", "Sticky Aim toggle ignored because Silly Mode is active", true)
		UpdateStickyAimButtonAppearance()
		return
	end

	StickyAimEnabledBoolean = not StickyAimEnabledBoolean
	UpdateStickyAimButtonAppearance()
	UpdateDebugStatus("sticky aim=" .. tostring(StickyAimEnabledBoolean))
	DebugLog("toggle-sticky", "Sticky Aim set to " .. tostring(StickyAimEnabledBoolean), true)
	SchedulePersistentStateSave()
end)

if SillyModeToggleButton then
	SillyModeToggleButton.MouseButton1Click.Connect(SillyModeToggleButton.MouseButton1Click, function()
		if IsAimbotUiInputSuppressed() then
			return
		end
		ToggleSillyMode()
	end)
end

if ShieldModeToggleButton then
	ShieldModeToggleButton.MouseButton1Click.Connect(ShieldModeToggleButton.MouseButton1Click, function()
		if IsAimbotUiInputSuppressed() then
			return
		end
		if not IsSillyModeEnabled() then
			UpdateDebugStatus("shield mode requires silly mode enabled")
			DebugLog("toggle-shield-locked", "Shield Mode toggle ignored because Silly Mode is disabled", true)
			UpdateShieldModeButtonAppearance()
			UpdateSillySkyVisibilityButtonAppearance()
			return
		end

		ShieldModeEnabledBoolean = not ShieldModeEnabledBoolean
		UpdateShieldModeButtonAppearance()
		UpdateSillySkyVisibilityButtonAppearance()
		UpdateDebugStatus("shield mode=" .. tostring(ShieldModeEnabledBoolean))
		DebugLog("toggle-shield", "Shield Mode set to " .. tostring(ShieldModeEnabledBoolean), true)
		SchedulePersistentStateSave()
	end)
end

if SillySkyVisibilityToggleButton then
	SillySkyVisibilityToggleButton.MouseButton1Click.Connect(SillySkyVisibilityToggleButton.MouseButton1Click, function()
		if IsAimbotUiInputSuppressed() then
			return
		end
		SillySkyVisibilityCheckEnabledBoolean = not SillySkyVisibilityCheckEnabledBoolean
		UpdateSillySkyVisibilityButtonAppearance()
		UpdateDebugStatus("sky vis check=" .. tostring(SillySkyVisibilityCheckEnabledBoolean))
		DebugLog("toggle-sky-vis", "Silly sky visibility check set to " .. tostring(SillySkyVisibilityCheckEnabledBoolean), true)
		SchedulePersistentStateSave()
	end)
end

EspToggleButton.MouseButton1Click.Connect(EspToggleButton.MouseButton1Click, function()
	if IsAimbotUiInputSuppressed() then
		return
	end
	EspEnabledBoolean = not EspEnabledBoolean
	UpdateEspToggleButtonAppearance()
	UpdateEspSkeletonToggleButtonAppearance()
	UpdateEspHighlightToggleButtonAppearance()
	if not EspEnabledBoolean then
		EspRuntimeTable.HideAll(EspRuntimeTable)
	end
	SchedulePersistentStateSave()
end)

EspSkeletonToggleButton.MouseButton1Click.Connect(EspSkeletonToggleButton.MouseButton1Click, function()
	if IsAimbotUiInputSuppressed() then
		return
	end
	if not EspEnabledBoolean then
		UpdateEspSkeletonToggleButtonAppearance()
		return
	end
	EspSkeletonEnabledBoolean = not EspSkeletonEnabledBoolean
	UpdateEspSkeletonToggleButtonAppearance()
	if not EspSkeletonEnabledBoolean then
		EspRuntimeTable.HideSkeletons(EspRuntimeTable)
	end
	SchedulePersistentStateSave()
end)

EspHighlightToggleButton.MouseButton1Click.Connect(EspHighlightToggleButton.MouseButton1Click, function()
	if IsAimbotUiInputSuppressed() then
		return
	end
	if not EspEnabledBoolean then
		UpdateEspHighlightToggleButtonAppearance()
		return
	end
	EspHighlightEnabledBoolean = not EspHighlightEnabledBoolean
	UpdateEspHighlightToggleButtonAppearance()
	if not EspHighlightEnabledBoolean then
		EspRuntimeTable.ClearHighlights(EspRuntimeTable)
	end
	SchedulePersistentStateSave()
end)

UpdateHeadshotButtonAppearance()
UpdateAutoFireButtonAppearance()
UpdateVisibleCheckButtonAppearance()
UpdateTargetSegmentationButtonAppearance()
UpdateFovToggleButtonAppearance()
UpdateTargetLineToggleButtonAppearance()
UpdateLockKeyButtonAppearance()
UpdateHookMethodButtonAppearance()
UpdateStickyAimButtonAppearance()
UpdateHookHitChanceSliderAppearance()
UpdateSillyModeButtonAppearance()
UpdateShieldModeButtonAppearance()
UpdateSillySkyVisibilityButtonAppearance()
UpdateEspToggleButtonAppearance()
UpdateEspSkeletonToggleButtonAppearance()
UpdateEspHighlightToggleButtonAppearance()
PlayerListRuntimeTable.RefreshUi(true)

function MakeFrameDraggable(FrameInstance, DragHandleInstance)
	DragHandleInstance.Active = true
	DragHandleInstance.InputBegan.Connect(DragHandleInstance.InputBegan, function(InputObject)
		if IsAimbotUiInputSuppressed() then
			return
		end
		if not UiInteractionRuntimeTable.dragEnabled then
			return
		end
		if InputObject.UserInputType == Enum.UserInputType.MouseButton1 then
			UiInteractionRuntimeTable.draggingFrame = FrameInstance
			UiInteractionRuntimeTable.dragStartInputPosition = InputObject.Position
			UiInteractionRuntimeTable.startFramePosition = FrameInstance.Position
		end
	end)
end

UserInputService.InputChanged.Connect(UserInputService.InputChanged, function(InputObject)
	if UiInteractionRuntimeTable.draggingFrame
		and UiInteractionRuntimeTable.dragEnabled
		and UiInteractionRuntimeTable.dragStartInputPosition
		and UiInteractionRuntimeTable.startFramePosition
		and InputObject.UserInputType == Enum.UserInputType.MouseMovement then
		local DeltaVector2 = InputObject.Position - UiInteractionRuntimeTable.dragStartInputPosition
		UiInteractionRuntimeTable.draggingFrame.Position = UDim2.new(
			UiInteractionRuntimeTable.startFramePosition.X.Scale,
			UiInteractionRuntimeTable.startFramePosition.X.Offset + DeltaVector2.X,
			UiInteractionRuntimeTable.startFramePosition.Y.Scale,
			UiInteractionRuntimeTable.startFramePosition.Y.Offset + DeltaVector2.Y
		)
	end
end)

UserInputService.InputEnded.Connect(UserInputService.InputEnded, function(InputObject)
	if InputObject.UserInputType == Enum.UserInputType.MouseButton1 then
		if UiInteractionRuntimeTable.draggingFrame == MenuFrame then
			StoreMenuOpenPosition(MenuFrame.Position, true)
			SchedulePersistentStateSave()
		elseif UiInteractionRuntimeTable.draggingFrame == PlayerListRuntimeTable.frame then
			StorePlayerListOpenPosition(PlayerListRuntimeTable.frame.Position, true)
			SchedulePersistentStateSave()
		end
		UiInteractionRuntimeTable.draggingFrame = nil
		UiInteractionRuntimeTable.dragStartInputPosition = nil
		UiInteractionRuntimeTable.startFramePosition = nil
	end
end)

MakeFrameDraggable(MenuFrame, TitleLabel)
MakeFrameDraggable(PlayerListRuntimeTable.frame, PlayerListRuntimeTable.titleLabel)

function SetSmoothingFromRatio(RatioNumber)
	RatioNumber = math.clamp(RatioNumber, 0, 1)
	AimbotSmoothingNumber = MinSmoothingNumber + (MaxSmoothingNumber - MinSmoothingNumber) * RatioNumber
	SmoothingValueLabel.Text = "Smoothing: " .. string.format("%.2f", AimbotSmoothingNumber)
	local BackWidthNumber = SmoothSliderBackFrame.AbsoluteSize.X
	local KnobWidthNumber = SmoothSliderKnobFrame.AbsoluteSize.X
	SmoothSliderFillFrame.Size = UDim2.new(RatioNumber, 0, 1, 0)
	SmoothSliderKnobFrame.Position = UDim2.new(RatioNumber, -KnobWidthNumber / 2, 0.5, -SmoothSliderKnobFrame.AbsoluteSize.Y / 2)
end

function SetFovFromRatio(RatioNumber)
	RatioNumber = math.clamp(RatioNumber, 0, 1)
	local NewRadiusNumber = MinFovRadiusNumber + (MaxFovRadiusNumber - MinFovRadiusNumber) * RatioNumber
	FovCircle.Radius = NewRadiusNumber
	FovValueLabel.Text = "FOV Radius: " .. tostring(math.floor(NewRadiusNumber))
	local BackWidthNumber = FovSliderBackFrame.AbsoluteSize.X
	local KnobWidthNumber = FovSliderKnobFrame.AbsoluteSize.X
	FovSliderFillFrame.Size = UDim2.new(RatioNumber, 0, 1, 0)
	FovSliderKnobFrame.Position = UDim2.new(RatioNumber, -KnobWidthNumber / 2, 0.5, -FovSliderKnobFrame.AbsoluteSize.Y / 2)
end

function SetNormalHookHitChanceFromRatio(RatioNumber)
	RatioNumber = math.clamp(RatioNumber, 0, 1)
	NormalHookHitChanceNumber = MinNormalHookHitChanceNumber
		+ (MaxNormalHookHitChanceNumber - MinNormalHookHitChanceNumber) * RatioNumber
	ResetNormalHookHitChanceDecision()
	UpdateHookHitChanceSliderAppearance()
end

function UpdateSmoothSliderFromMouse()
	local MouseLocationVector2 = UserInputService.GetMouseLocation(UserInputService)
	local BackPositionVector2 = SmoothSliderBackFrame.AbsolutePosition
	local BackSizeVector2 = SmoothSliderBackFrame.AbsoluteSize
	local RelativeXNumber = math.clamp(MouseLocationVector2.X - BackPositionVector2.X, 0, BackSizeVector2.X)
	local RatioNumber = 0
	if BackSizeVector2.X > 0 then
		RatioNumber = RelativeXNumber / BackSizeVector2.X
	end
	SetSmoothingFromRatio(RatioNumber)
end

function UpdateFovSliderFromMouse()
	local MouseLocationVector2 = UserInputService.GetMouseLocation(UserInputService)
	local BackPositionVector2 = FovSliderBackFrame.AbsolutePosition
	local BackSizeVector2 = FovSliderBackFrame.AbsoluteSize
	local RelativeXNumber = math.clamp(MouseLocationVector2.X - BackPositionVector2.X, 0, BackSizeVector2.X)
	local RatioNumber = 0
	if BackSizeVector2.X > 0 then
		RatioNumber = RelativeXNumber / BackSizeVector2.X
	end
	SetFovFromRatio(RatioNumber)
end

function UpdateNormalHookHitChanceSliderFromMouse()
	if IsSillyModeBehaviorActive() then
		UpdateHookHitChanceSliderAppearance()
		return
	end

	local MouseLocationVector2 = UserInputService.GetMouseLocation(UserInputService)
	local BackPositionVector2 = HookHitChanceSliderBackFrame.AbsolutePosition
	local BackSizeVector2 = HookHitChanceSliderBackFrame.AbsoluteSize
	local RelativeXNumber = math.clamp(MouseLocationVector2.X - BackPositionVector2.X, 0, BackSizeVector2.X)
	local RatioNumber = 0
	if BackSizeVector2.X > 0 then
		RatioNumber = RelativeXNumber / BackSizeVector2.X
	end
	SetNormalHookHitChanceFromRatio(RatioNumber)
end

SmoothSliderBackFrame.InputBegan.Connect(SmoothSliderBackFrame.InputBegan, function(InputObject)
	if IsAimbotUiInputSuppressed() then
		return
	end
	if InputObject.UserInputType == Enum.UserInputType.MouseButton1 then
		UiInteractionRuntimeTable.dragEnabled = false
		UiInteractionRuntimeTable.smoothSliderDragging = true
		UpdateSmoothSliderFromMouse()
	end
end)

SmoothSliderKnobFrame.InputBegan.Connect(SmoothSliderKnobFrame.InputBegan, function(InputObject)
	if IsAimbotUiInputSuppressed() then
		return
	end
	if InputObject.UserInputType == Enum.UserInputType.MouseButton1 then
		UiInteractionRuntimeTable.dragEnabled = false
		UiInteractionRuntimeTable.smoothSliderDragging = true
		UpdateSmoothSliderFromMouse()
	end
end)

FovSliderBackFrame.InputBegan.Connect(FovSliderBackFrame.InputBegan, function(InputObject)
	if IsAimbotUiInputSuppressed() then
		return
	end
	if InputObject.UserInputType == Enum.UserInputType.MouseButton1 then
		UiInteractionRuntimeTable.dragEnabled = false
		UiInteractionRuntimeTable.fovSliderDragging = true
		UpdateFovSliderFromMouse()
	end
end)

FovSliderKnobFrame.InputBegan.Connect(FovSliderKnobFrame.InputBegan, function(InputObject)
	if IsAimbotUiInputSuppressed() then
		return
	end
	if InputObject.UserInputType == Enum.UserInputType.MouseButton1 then
		UiInteractionRuntimeTable.dragEnabled = false
		UiInteractionRuntimeTable.fovSliderDragging = true
		UpdateFovSliderFromMouse()
	end
end)

HookHitChanceSliderBackFrame.InputBegan.Connect(HookHitChanceSliderBackFrame.InputBegan, function(InputObject)
	if IsAimbotUiInputSuppressed() then
		return
	end
	if IsSillyModeBehaviorActive() then
		UpdateDebugStatus("hook hit chance locked while silly mode active")
		DebugLog("slider-hit-chance-locked", "Hook Hit Chance slider ignored because Silly Mode is active", true)
		UpdateHookHitChanceSliderAppearance()
		return
	end
	if InputObject.UserInputType == Enum.UserInputType.MouseButton1 then
		UiInteractionRuntimeTable.dragEnabled = false
		UiInteractionRuntimeTable.hitChanceSliderDragging = true
		UpdateNormalHookHitChanceSliderFromMouse()
	end
end)

HookHitChanceSliderKnobFrame.InputBegan.Connect(HookHitChanceSliderKnobFrame.InputBegan, function(InputObject)
	if IsAimbotUiInputSuppressed() then
		return
	end
	if IsSillyModeBehaviorActive() then
		UpdateDebugStatus("hook hit chance locked while silly mode active")
		DebugLog("slider-hit-chance-locked", "Hook Hit Chance knob ignored because Silly Mode is active", true)
		UpdateHookHitChanceSliderAppearance()
		return
	end
	if InputObject.UserInputType == Enum.UserInputType.MouseButton1 then
		UiInteractionRuntimeTable.dragEnabled = false
		UiInteractionRuntimeTable.hitChanceSliderDragging = true
		UpdateNormalHookHitChanceSliderFromMouse()
	end
end)

UserInputService.InputChanged.Connect(UserInputService.InputChanged, function(InputObject)
	if InputObject.UserInputType == Enum.UserInputType.MouseMovement then
		if UiInteractionRuntimeTable.smoothSliderDragging then
			UpdateSmoothSliderFromMouse()
		end
		if UiInteractionRuntimeTable.fovSliderDragging then
			UpdateFovSliderFromMouse()
		end
		if UiInteractionRuntimeTable.hitChanceSliderDragging then
			UpdateNormalHookHitChanceSliderFromMouse()
		end
	end
end)

UserInputService.InputEnded.Connect(UserInputService.InputEnded, function(InputObject)
	if InputObject.UserInputType == Enum.UserInputType.MouseButton1 then
		if UiInteractionRuntimeTable.smoothSliderDragging
			or UiInteractionRuntimeTable.fovSliderDragging
			or UiInteractionRuntimeTable.hitChanceSliderDragging then
			UiInteractionRuntimeTable.smoothSliderDragging = false
			UiInteractionRuntimeTable.fovSliderDragging = false
			UiInteractionRuntimeTable.hitChanceSliderDragging = false
			UiInteractionRuntimeTable.dragEnabled = true
			SchedulePersistentStateSave()
		end
	end
end)

task.defer(function()
	local DefaultSmoothRatioNumber = (AimbotSmoothingNumber - MinSmoothingNumber) / (MaxSmoothingNumber - MinSmoothingNumber)
	DefaultSmoothRatioNumber = math.clamp(DefaultSmoothRatioNumber, 0, 1)
	SetSmoothingFromRatio(DefaultSmoothRatioNumber)
	local DefaultFovRatioNumber = (FovCircle.Radius - MinFovRadiusNumber) / (MaxFovRadiusNumber - MinFovRadiusNumber)
	DefaultFovRatioNumber = math.clamp(DefaultFovRatioNumber, 0, 1)
	SetFovFromRatio(DefaultFovRatioNumber)
	local DefaultNormalHookHitChanceRatioNumber = (NormalHookHitChanceNumber - MinNormalHookHitChanceNumber)
		/ (MaxNormalHookHitChanceNumber - MinNormalHookHitChanceNumber)
	DefaultNormalHookHitChanceRatioNumber = math.clamp(DefaultNormalHookHitChanceRatioNumber, 0, 1)
	SetNormalHookHitChanceFromRatio(DefaultNormalHookHitChanceRatioNumber)
end)

local MenuIsOpenBoolean = true
local MenuOpenPosition = MenuFrame.Position
local PlayerListOpenPosition = PlayerListRuntimeTable.frame.Position
local MenuClosedPosition = UDim2.new(MenuOpenPosition.X.Scale, MenuOpenPosition.X.Offset, MenuOpenPosition.Y.Scale, MenuOpenPosition.Y.Offset - 150)
local MenuTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MenuHasCustomPositionBoolean = false
local PlayerListHasCustomPositionBoolean = false

function RoundAbsoluteUdim2Position(PositionUdim2)
	if typeof(PositionUdim2) ~= "UDim2" then
		return UDim2.new(0, 0, 0, 0)
	end

	return UDim2.new(
		0,
		math.floor(PositionUdim2.X.Offset + 0.5),
		0,
		math.floor(PositionUdim2.Y.Offset + 0.5)
	)
end

function BuildMenuClosedPositionFromOpenPosition(OpenPositionUdim2)
	local RoundedOpenPosition = RoundAbsoluteUdim2Position(OpenPositionUdim2)
	return UDim2.new(
		0,
		RoundedOpenPosition.X.Offset,
		0,
		math.floor(RoundedOpenPosition.Y.Offset - math.max(90, 150 * (UiResponsiveRuntimeTable.scale or 1)) + 0.5)
	)
end

function ClampAbsoluteUdim2PositionToViewport(OpenPositionUdim2, ViewportWidthNumber, ViewportHeightNumber, FrameWidthScaledNumber, FrameHeightScaledNumber, MarginNumber)
	local RoundedOpenPosition = RoundAbsoluteUdim2Position(OpenPositionUdim2)
	local MaximumXOffsetNumber = math.max(MarginNumber, ViewportWidthNumber - FrameWidthScaledNumber - MarginNumber)
	local MaximumYOffsetNumber = math.max(MarginNumber, ViewportHeightNumber - FrameHeightScaledNumber - MarginNumber)
	return UDim2.new(
		0,
		math.floor(math.clamp(RoundedOpenPosition.X.Offset, MarginNumber, MaximumXOffsetNumber) + 0.5),
		0,
		math.floor(math.clamp(RoundedOpenPosition.Y.Offset, MarginNumber, MaximumYOffsetNumber) + 0.5)
	)
end

function ClampMenuOpenPositionToViewport(OpenPositionUdim2, ViewportWidthNumber, ViewportHeightNumber, MenuWidthScaledNumber, MenuHeightScaledNumber, MarginNumber)
	return ClampAbsoluteUdim2PositionToViewport(
		OpenPositionUdim2,
		ViewportWidthNumber,
		ViewportHeightNumber,
		MenuWidthScaledNumber,
		MenuHeightScaledNumber,
		MarginNumber
	)
end

function StoreMenuOpenPosition(OpenPositionUdim2, HasCustomPositionBoolean)
	MenuOpenPosition = RoundAbsoluteUdim2Position(OpenPositionUdim2)
	MenuClosedPosition = BuildMenuClosedPositionFromOpenPosition(MenuOpenPosition)
	if HasCustomPositionBoolean ~= nil then
		MenuHasCustomPositionBoolean = HasCustomPositionBoolean == true
	end
end

function StorePlayerListOpenPosition(OpenPositionUdim2, HasCustomPositionBoolean)
	PlayerListOpenPosition = RoundAbsoluteUdim2Position(OpenPositionUdim2)
	if HasCustomPositionBoolean ~= nil then
		PlayerListHasCustomPositionBoolean = HasCustomPositionBoolean == true
	end
end

function ApplyPendingPersistentUiState()
	local UiStateTable = PersistentSettingsRuntimeTable.pendingUiState
	if type(UiStateTable) ~= "table" then
		return
	end

	local LoadedMenuOpenPosition = DeserializePersistedPosition(UiStateTable.menuOpenPosition)
	if LoadedMenuOpenPosition then
		StoreMenuOpenPosition(
			LoadedMenuOpenPosition,
			type(UiStateTable.menuHasCustomPosition) == "boolean" and UiStateTable.menuHasCustomPosition or true
		)
	elseif type(UiStateTable.menuHasCustomPosition) == "boolean" then
		MenuHasCustomPositionBoolean = UiStateTable.menuHasCustomPosition
	end

	local LoadedPlayerListOpenPosition = DeserializePersistedPosition(UiStateTable.playerListOpenPosition)
	if LoadedPlayerListOpenPosition then
		StorePlayerListOpenPosition(
			LoadedPlayerListOpenPosition,
			type(UiStateTable.playerListHasCustomPosition) == "boolean" and UiStateTable.playerListHasCustomPosition or true
		)
	elseif type(UiStateTable.playerListHasCustomPosition) == "boolean" then
		PlayerListHasCustomPositionBoolean = UiStateTable.playerListHasCustomPosition
	end

	PersistentSettingsRuntimeTable.pendingUiState = nil
end

function UpdateResponsiveUiLayout()
	local CurrentCamera = WorkspaceService.CurrentCamera or Camera
	local ViewportSizeVector2 = CurrentCamera and CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local ViewportWidthNumber = math.max(ViewportSizeVector2.X, 1)
	local ViewportHeightNumber = math.max(ViewportSizeVector2.Y, 1)
	local MenuWidthNumber = UiResponsiveRuntimeTable.menuWidth
	local MenuHeightNumber = UiResponsiveRuntimeTable.menuHeight
	local PlayerListWidthNumber = UiResponsiveRuntimeTable.playerListWidth
	local GapNumber = UiResponsiveRuntimeTable.gap
	local MarginNumber = UiResponsiveRuntimeTable.margin
	local IsNarrowBoolean = ViewportWidthNumber < UiResponsiveRuntimeTable.narrowBreakpoint
	local PlayerListHeightNumber
	if PlayerListRuntimeTable.collapsed then
		PlayerListHeightNumber = PlayerListRuntimeTable.collapsedHeight
	elseif IsNarrowBoolean then
		PlayerListHeightNumber = UiResponsiveRuntimeTable.narrowPlayerListHeight
	else
		PlayerListHeightNumber = MenuHeightNumber
	end
	local ScaleNumber

	if IsNarrowBoolean then
		local AvailableWidthNumber = math.max(ViewportWidthNumber - MarginNumber * 2, 1)
		local AvailableHeightNumber = math.max(ViewportHeightNumber - MarginNumber * 2 - GapNumber, 1)
		ScaleNumber = math.min(
			1,
			AvailableWidthNumber / MenuWidthNumber,
			AvailableHeightNumber / (MenuHeightNumber + PlayerListHeightNumber)
		)
	else
		local AvailableWidthNumber = math.max(ViewportWidthNumber - MarginNumber * 2 - GapNumber, 1)
		local AvailableHeightNumber = math.max(ViewportHeightNumber - MarginNumber * 2, 1)
		ScaleNumber = math.min(
			1,
			AvailableWidthNumber / (MenuWidthNumber + PlayerListWidthNumber),
			AvailableHeightNumber / MenuHeightNumber
		)
	end

	ScaleNumber = math.max(ScaleNumber, UiResponsiveRuntimeTable.minimumScale)
	local MenuWidthScaledNumber = MenuWidthNumber * ScaleNumber
	local MenuHeightScaledNumber = MenuHeightNumber * ScaleNumber
	local PlayerListWidthScaledNumber = PlayerListWidthNumber * ScaleNumber
	local PlayerListHeightScaledNumber = PlayerListHeightNumber * ScaleNumber
	local MenuXOffsetNumber
	local MenuYOffsetNumber
	local PlayerListXOffsetNumber
	local PlayerListYOffsetNumber

	if IsNarrowBoolean then
		local TotalHeightScaledNumber = MenuHeightScaledNumber + GapNumber + PlayerListHeightScaledNumber
		MenuXOffsetNumber = math.max(MarginNumber, (ViewportWidthNumber - MenuWidthScaledNumber) / 2)
		MenuYOffsetNumber = math.max(MarginNumber, (ViewportHeightNumber - TotalHeightScaledNumber) / 2)
		PlayerListXOffsetNumber = MenuXOffsetNumber
		PlayerListYOffsetNumber = MenuYOffsetNumber + MenuHeightScaledNumber + GapNumber
	else
		local TotalWidthScaledNumber = MenuWidthScaledNumber + GapNumber + PlayerListWidthScaledNumber
		MenuXOffsetNumber = math.max(MarginNumber, (ViewportWidthNumber - TotalWidthScaledNumber) / 2)
		MenuYOffsetNumber = math.max(MarginNumber, (ViewportHeightNumber - MenuHeightScaledNumber) / 2)
		PlayerListXOffsetNumber = MenuXOffsetNumber + MenuWidthScaledNumber + GapNumber
		PlayerListYOffsetNumber = MenuYOffsetNumber
	end

	UiResponsiveRuntimeTable.scale = ScaleNumber
	UiResponsiveRuntimeTable.narrow = IsNarrowBoolean
	MenuScaleObject.Scale = ScaleNumber
	PlayerListScaleObject.Scale = ScaleNumber
	DebugScaleObject.Scale = ScaleNumber
	MenuFrame.Size = UDim2.new(0, MenuWidthNumber, 0, MenuHeightNumber)
	PlayerListRuntimeTable.frame.Size = UDim2.new(0, PlayerListWidthNumber, 0, PlayerListHeightNumber)
	local CenteredMenuOpenPosition = UDim2.new(
		0,
		math.floor(MenuXOffsetNumber + 0.5),
		0,
		math.floor(MenuYOffsetNumber + 0.5)
	)
	local CenteredPlayerListOpenPosition = UDim2.new(
		0,
		math.floor(PlayerListXOffsetNumber + 0.5),
		0,
		math.floor(PlayerListYOffsetNumber + 0.5)
	)
	if MenuHasCustomPositionBoolean then
		StoreMenuOpenPosition(
			ClampMenuOpenPositionToViewport(
				MenuOpenPosition,
				ViewportWidthNumber,
				ViewportHeightNumber,
				MenuWidthScaledNumber,
				MenuHeightScaledNumber,
				MarginNumber
			),
			true
		)
	else
		StoreMenuOpenPosition(CenteredMenuOpenPosition, false)
	end
	MenuFrame.Position = MenuIsOpenBoolean and MenuOpenPosition or MenuClosedPosition
	if PlayerListHasCustomPositionBoolean then
		StorePlayerListOpenPosition(
			ClampAbsoluteUdim2PositionToViewport(
				PlayerListOpenPosition,
				ViewportWidthNumber,
				ViewportHeightNumber,
				PlayerListWidthScaledNumber,
				PlayerListHeightScaledNumber,
				MarginNumber
			),
			true
		)
	else
		StorePlayerListOpenPosition(CenteredPlayerListOpenPosition, false)
	end
	PlayerListRuntimeTable.frame.Position = PlayerListOpenPosition

	local DebugXOffsetNumber = PlayerListXOffsetNumber + PlayerListWidthScaledNumber + GapNumber
	local DebugYOffsetNumber = MenuYOffsetNumber
	if DebugXOffsetNumber + 300 * ScaleNumber > ViewportWidthNumber - MarginNumber then
		DebugXOffsetNumber = MenuXOffsetNumber
		DebugYOffsetNumber = PlayerListYOffsetNumber + PlayerListHeightScaledNumber + GapNumber
	end
	DebugFrame.Position = UDim2.new(
		0,
		math.floor(DebugXOffsetNumber + 0.5),
		0,
		math.floor(DebugYOffsetNumber + 0.5)
	)
end

function UpdatePlayerListCollapseButtonAppearance()
	local ToggleButton = PlayerListRuntimeTable.toggleButton
	if not ToggleButton then
		return
	end

	if PlayerListRuntimeTable.collapsed then
		ToggleButton.Text = "+"
		ToggleButton.BackgroundColor3 = Color3.fromRGB(55, 85, 115)
	else
		ToggleButton.Text = "-"
		ToggleButton.BackgroundColor3 = Color3.fromRGB(45, 75, 105)
	end
	PlayerListRuntimeTable.statusLabel.Visible = not PlayerListRuntimeTable.collapsed
	PlayerListRuntimeTable.scrollFrame.Visible = not PlayerListRuntimeTable.collapsed
end

function SetPlayerListCollapsed(CollapsedBoolean)
	StorePlayerListOpenPosition(PlayerListRuntimeTable.frame.Position, PlayerListHasCustomPositionBoolean)
	PlayerListRuntimeTable.collapsed = CollapsedBoolean == true
	UpdatePlayerListCollapseButtonAppearance()
	UpdateResponsiveUiLayout()
	SchedulePersistentStateSave()
end

function TogglePlayerListCollapsed()
	SetPlayerListCollapsed(not PlayerListRuntimeTable.collapsed)
end

PlayerListRuntimeTable.toggleButton.MouseButton1Click.Connect(PlayerListRuntimeTable.toggleButton.MouseButton1Click, function()
	if IsAimbotUiInputSuppressed() then
		return
	end
	TogglePlayerListCollapsed()
end)

UpdatePlayerListCollapseButtonAppearance()
ApplyPendingPersistentUiState()
UpdateResponsiveUiLayout()
if Camera and Camera.GetPropertyChangedSignal then
	Camera.GetPropertyChangedSignal(Camera, "ViewportSize").Connect(Camera.GetPropertyChangedSignal(Camera, "ViewportSize"), function()
		UpdateResponsiveUiLayout()
	end)
end

MenuFrame.Position = MenuOpenPosition
MenuFrame.Visible = true

function SetMenuOpen(OpenBoolean)
	if MenuIsOpenBoolean == OpenBoolean then
		return
	end
	if not OpenBoolean then
		StoreMenuOpenPosition(MenuFrame.Position, MenuHasCustomPositionBoolean)
	end
	MenuIsOpenBoolean = OpenBoolean
	if OpenBoolean then
		MenuFrame.Visible = true
		MenuFrame.Position = MenuClosedPosition
		local OpenTweenObject = TweenService.Create(TweenService, MenuFrame, MenuTweenInfo, { Position = MenuOpenPosition })
		OpenTweenObject:Play()
	else
		local CloseTweenObject = TweenService.Create(TweenService, MenuFrame, MenuTweenInfo, { Position = MenuClosedPosition })
		CloseTweenObject.Completed.Connect(CloseTweenObject.Completed, function()
			if not MenuIsOpenBoolean then
				MenuFrame.Visible = false
			end
		end)
		CloseTweenObject:Play()
	end
end

UserInputService.InputBegan.Connect(UserInputService.InputBegan, function(InputObject, GameProcessedEvent)
	if GameProcessedEvent then
		return
	end
	if InputObject.KeyCode == Enum.KeyCode.RightShift then
		SetMenuOpen(not MenuIsOpenBoolean)
	elseif IsBloodZonePlaceBoolean and InputObject.KeyCode == Enum.KeyCode.LeftBracket then
		ToggleSillyMode()
	elseif IsBloodZonePlaceBoolean and IsSillyModeBehaviorActive() and not ShieldModeEnabledBoolean and InputObject.KeyCode == Enum.KeyCode.Z then
		SillySkyAimEnabledBoolean = not SillySkyAimEnabledBoolean
		UpdateSillySkyVisibilityButtonAppearance()
		UpdateDebugStatus("silly sky aim=" .. tostring(SillySkyAimEnabledBoolean))
		DebugLog("toggle-sky-aim", "Silly Mode sky aim set to " .. tostring(SillySkyAimEnabledBoolean), true)
		SchedulePersistentStateSave()
	elseif InputObject.KeyCode == Enum.KeyCode.RightBracket and GetCurrentLockKeyMode() == "Always" then
		AdvanceLockKeyMode()
		UpdateLockKeyButtonAppearance()
	end
end)

function IsPointInCircle(PointVector2, CircleCenterVector2, CircleRadiusNumber)
	return (PointVector2 - CircleCenterVector2).Magnitude <= CircleRadiusNumber
end

function GetCubeSize(TargetPart)
	if IsEffectiveVisibleCheckEnabled() and IsEffectiveTargetSegmentationEnabled() then
		local SegmentCount = math.max(VisibleCheckSubdivisionsNumber, 1)
		return Vector3.new(
			TargetPart.Size.X / SegmentCount,
			TargetPart.Size.Y / SegmentCount,
			TargetPart.Size.Z / SegmentCount
		)
	end
	return TargetPart.Size
end

function GetCubeCorners(CubeCFrame, CubeSize)
	local Half = CubeSize * 0.5
	local LocalCorners = {
		Vector3.new(-Half.X, -Half.Y, -Half.Z),
		Vector3.new(Half.X, -Half.Y, -Half.Z),
		Vector3.new(Half.X, Half.Y, -Half.Z),
		Vector3.new(-Half.X, Half.Y, -Half.Z),
		Vector3.new(-Half.X, -Half.Y, Half.Z),
		Vector3.new(Half.X, -Half.Y, Half.Z),
		Vector3.new(Half.X, Half.Y, Half.Z),
		Vector3.new(-Half.X, Half.Y, Half.Z),
	}
	local WorldCorners = {}
	for Index, LocalCorner in ipairs(LocalCorners) do
		WorldCorners[Index] = CubeCFrame:PointToWorldSpace(LocalCorner)
	end
	return WorldCorners
end

SetTargetCubeVisible = function(IsVisible)
	for _, Line in ipairs(TargetCubeLines) do
		Line.Visible = IsVisible
	end
end

function BuildPersistentGlobalStateTable()
	return {
		smoothing = tonumber(AimbotSmoothingNumber) or 0,
		fovRadius = tonumber(FovCircle.Radius) or 0,
		hookHitChance = tonumber(NormalHookHitChanceNumber) or 100,
		headshotPriority = HeadshotPriorityBoolean == true,
		autoFireEnabled = AutoFireEnabledBoolean == true,
		visibleCheckEnabled = VisibleCheckEnabledBoolean == true,
		targetSegmentationEnabled = TargetSegmentationEnabledBoolean == true,
		showFovCircle = ShowFovCircleBoolean == true,
		showTargetLine = ShowTargetLineBoolean == true,
		useHookMethod = UseHookMethodBoolean == true,
		useCameraMethod = UseCameraMethodBoolean == true,
		stickyAimEnabled = StickyAimEnabledBoolean == true,
		lockKeyModeIndex = math.floor(tonumber(LockKeyModeIndexNumber) or 1),
		espEnabled = EspEnabledBoolean == true,
		espSkeletonEnabled = EspSkeletonEnabledBoolean == true,
		espHighlightEnabled = EspHighlightEnabledBoolean == true,
		ui = {
			menuOpenPosition = SerializePersistedPosition(MenuOpenPosition),
			menuHasCustomPosition = MenuHasCustomPositionBoolean == true,
			playerListOpenPosition = SerializePersistedPosition(PlayerListOpenPosition),
			playerListHasCustomPosition = PlayerListHasCustomPositionBoolean == true,
			playerListCollapsed = PlayerListRuntimeTable.collapsed == true,
		},
	}
end

function BuildPersistentGameStateTable()
	if IsBloodZonePlaceBoolean then
		return {
			sillyModeEnabled = SillyModeEnabledBoolean == true,
			sillySkyAimEnabled = SillySkyAimEnabledBoolean == true,
			sillySkyVisibilityCheckEnabled = SillySkyVisibilityCheckEnabledBoolean == true,
			shieldModeEnabled = ShieldModeEnabledBoolean == true,
		}
	end

	return nil
end

SavePersistentStateNow = function()
	if type(writefile) ~= "function" then
		return false
	end

	local ExistingRootStateTable = type(PersistentSettingsRuntimeTable.loadedState) == "table"
		and PersistentSettingsRuntimeTable.loadedState
		or nil
	local GamesTable = type(ExistingRootStateTable and ExistingRootStateTable.games) == "table"
		and ExistingRootStateTable.games
		or {}
	local RootStateTable = {
		version = PersistentSettingsRuntimeTable.version,
		global = BuildPersistentGlobalStateTable(),
		games = GamesTable,
	}

	local GameStateTable = BuildPersistentGameStateTable()
	if GameStateTable then
		GamesTable[PersistentSettingsRuntimeTable.gameKey] = GameStateTable
	else
		GamesTable[PersistentSettingsRuntimeTable.gameKey] = nil
	end

	local EncodeSuccessBoolean, EncodedStateString = pcall(HttpService.JSONEncode, HttpService, RootStateTable)
	if not EncodeSuccessBoolean or type(EncodedStateString) ~= "string" or EncodedStateString == "" then
		return false
	end

	local FilePathString = ResolvePersistentSettingsFilePathForWrite()
	local WriteSuccessBoolean = false
	if type(FilePathString) == "string" and FilePathString ~= "" then
		WriteSuccessBoolean = pcall(writefile, FilePathString, EncodedStateString)
	end
	if not WriteSuccessBoolean and FilePathString ~= PersistentSettingsRuntimeTable.fallbackFilePath then
		PersistentSettingsRuntimeTable.activeFilePath = PersistentSettingsRuntimeTable.fallbackFilePath
		WriteSuccessBoolean = pcall(writefile, PersistentSettingsRuntimeTable.fallbackFilePath, EncodedStateString)
	end
	if WriteSuccessBoolean then
		PersistentSettingsRuntimeTable.loadedState = RootStateTable
	end
	return WriteSuccessBoolean == true
end

SchedulePersistentStateSave = function()
	if type(writefile) ~= "function" then
		return
	end

	PersistentSettingsRuntimeTable.saveSequence = (PersistentSettingsRuntimeTable.saveSequence or 0) + 1
	local SaveSequenceNumber = PersistentSettingsRuntimeTable.saveSequence
	task.delay(0.2, function()
		if PersistentSettingsRuntimeTable.saveSequence ~= SaveSequenceNumber then
			return
		end
		SavePersistentStateNow()
	end)
end

function UpdateTargetCube(CubeCFrame, CubeSize, SurfacePointVector3)
	local WorldCorners = GetCubeCorners(CubeCFrame, CubeSize)
	local ScreenCorners = {}
	local OnScreenFlags = {}

	for Index, Corner in ipairs(WorldCorners) do
		local ScreenPoint, OnScreen = Camera:WorldToViewportPoint(Corner)
		ScreenCorners[Index] = Vector2.new(ScreenPoint.X, ScreenPoint.Y)
		OnScreenFlags[Index] = OnScreen
	end

	for LineIndex, Pair in ipairs(TargetCubeEdgePairsTable) do
		local StartIndex = Pair[1]
		local EndIndex = Pair[2]
		local Line = TargetCubeLines[LineIndex]
		if OnScreenFlags[StartIndex] and OnScreenFlags[EndIndex] then
			Line.From = ScreenCorners[StartIndex]
			Line.To = ScreenCorners[EndIndex]
			Line.Visible = true
		else
			Line.Visible = false
		end
	end
end


function IsGlassVisibilityPart(PartInstance)
	if not PartInstance then
		return false
	end

	local HitFunctionValue = PartInstance.GetAttribute and PartInstance.GetAttribute(PartInstance, "HitFunction") or nil
	return HitFunctionValue == "Glass"
end

VisibilityRaycastBaseParamsFrameId = -1
VisibilityRaycastBaseParamsValue = nil
LowercaseNameCacheTable = {}
HeadLikePartNameCacheTable = {}

function GetLowercaseCachedName(NameString)
	if type(NameString) ~= "string" then
		return ""
	end

	local CachedLowercaseNameString = LowercaseNameCacheTable[NameString]
	if CachedLowercaseNameString then
		return CachedLowercaseNameString
	end

	CachedLowercaseNameString = string.lower(NameString)
	LowercaseNameCacheTable[NameString] = CachedLowercaseNameString
	return CachedLowercaseNameString
end

function IsHeadLikeTargetPart(PartInstance)
	local PartNameString = PartInstance and PartInstance.Name or nil
	if type(PartNameString) ~= "string" then
		return false
	end

	local CachedHeadLikeBoolean = HeadLikePartNameCacheTable[PartNameString]
	if CachedHeadLikeBoolean ~= nil then
		return CachedHeadLikeBoolean
	end

	local HeadLikeBoolean = string.find(GetLowercaseCachedName(PartNameString), "head", 1, true) ~= nil
	HeadLikePartNameCacheTable[PartNameString] = HeadLikeBoolean
	return HeadLikeBoolean
end

function JailbirdVisibilityRuntimeTable.DoesNameMatchFragments(NameString, NameFragmentsTable)
	if type(NameString) ~= "string" or type(NameFragmentsTable) ~= "table" then
		return false
	end

	local LowercaseNameString = GetLowercaseCachedName(NameString)
	for _, NameFragmentString in ipairs(NameFragmentsTable) do
		if string.find(LowercaseNameString, NameFragmentString, 1, true) then
			return true
		end
	end

	return false
end

function JailbirdVisibilityRuntimeTable.DoesInstanceHierarchyMatchFragments(InstanceObject, NameFragmentsTable, MaximumDepthNumber)
	local CurrentInstance = InstanceObject
	local RemainingDepthNumber = tonumber(MaximumDepthNumber) or 0
	while CurrentInstance and RemainingDepthNumber >= 0 do
		if JailbirdVisibilityRuntimeTable.DoesNameMatchFragments(CurrentInstance.Name, NameFragmentsTable) then
			return true
		end
		CurrentInstance = CurrentInstance.Parent
		RemainingDepthNumber = RemainingDepthNumber - 1
	end

	return false
end

function JailbirdVisibilityRuntimeTable.IsCharacterRelatedPart(PartInstance)
	local CurrentInstance = PartInstance
	for _ = 1, 6 do
		if not CurrentInstance then
			return false
		end
		if CurrentInstance.ClassName == "Model"
			and IsHumanoidCharacterModel(CurrentInstance)
			and GetCharacterRootPart(CurrentInstance) then
			return true
		end
		CurrentInstance = CurrentInstance.Parent
	end

	return false
end

function SafeGetPartBooleanProperty(PartInstance, PropertyNameString, DefaultBoolean)
	if not PartInstance or type(PropertyNameString) ~= "string" then
		return DefaultBoolean == true
	end

	local SuccessBoolean, PropertyValue = pcall(function()
		return PartInstance[PropertyNameString]
	end)
	if SuccessBoolean and type(PropertyValue) == "boolean" then
		return PropertyValue
	end

	return DefaultBoolean == true
end

function SafeGetBooleanAttribute(InstanceObject, AttributeNameString)
	if not InstanceObject
		or type(AttributeNameString) ~= "string"
		or not InstanceObject.GetAttribute then
		return nil
	end

	local SuccessBoolean, AttributeValue = pcall(InstanceObject.GetAttribute, InstanceObject, AttributeNameString)
	if not SuccessBoolean then
		return nil
	end

	if type(AttributeValue) == "boolean" then
		return AttributeValue
	end

	if type(AttributeValue) == "number" then
		return AttributeValue ~= 0
	end

	if type(AttributeValue) == "string" then
		local LowercaseValueString = GetLowercaseCachedName(AttributeValue)
		if LowercaseValueString == "true"
			or LowercaseValueString == "1"
			or LowercaseValueString == "yes" then
			return true
		end
		if LowercaseValueString == "false"
			or LowercaseValueString == "0"
			or LowercaseValueString == "no" then
			return false
		end
	end

	return nil
end

function SafeHasCollectionTag(InstanceObject, TagNameString)
	if not InstanceObject or type(TagNameString) ~= "string" then
		return false
	end

	local SuccessBoolean, HasTagBoolean = pcall(CollectionService.HasTag, CollectionService, InstanceObject, TagNameString)
	return SuccessBoolean and HasTagBoolean == true
end

function JailbirdVisibilityRuntimeTable.GetMapCacheInstance()
	local MapCacheInstance = JailbirdVisibilityRuntimeTable.mapCacheInstance
	if MapCacheInstance and MapCacheInstance.Parent then
		return MapCacheInstance
	end

	MapCacheInstance = WorkspaceService and WorkspaceService.FindFirstChild and WorkspaceService.FindFirstChild(WorkspaceService, "Map_Cache") or nil
	JailbirdVisibilityRuntimeTable.mapCacheInstance = MapCacheInstance
	return MapCacheInstance
end

function JailbirdVisibilityRuntimeTable.IsPassThroughPart(PartInstance)
	if not IsJailbirdPlaceBoolean
		or not PartInstance
		or not PartInstance.Parent
		or not PartInstance.IsA
		or not PartInstance.IsA(PartInstance, "BasePart") then
		return false
	end

	local CachedPassThroughBoolean = JailbirdVisibilityRuntimeTable.passThroughByPart[PartInstance]
	if CachedPassThroughBoolean ~= nil then
		return CachedPassThroughBoolean
	end

	if JailbirdVisibilityRuntimeTable.IsCharacterRelatedPart(PartInstance) then
		JailbirdVisibilityRuntimeTable.passThroughByPart[PartInstance] = false
		return false
	end

	if PartInstance.Transparency >= 1 then
		JailbirdVisibilityRuntimeTable.passThroughByPart[PartInstance] = true
		return true
	end

	local IsPassThroughBoolean = SafeHasCollectionTag(PartInstance, "IgnoreBullet")
		or PartInstance.Name == "Glass_Breakable"
		or SafeGetBooleanAttribute(PartInstance, "IgnoreBullet") == true
	JailbirdVisibilityRuntimeTable.passThroughByPart[PartInstance] = IsPassThroughBoolean
	return IsPassThroughBoolean
end

function CloneRaycastParamsWithIgnoredInstances(BaseRaycastParamsObject, ExtraIgnoredInstancesTable)
	local RaycastParamsObject = RaycastParams.new()
	if BaseRaycastParamsObject then
		RaycastParamsObject.FilterType = BaseRaycastParamsObject.FilterType
		RaycastParamsObject.IgnoreWater = BaseRaycastParamsObject.IgnoreWater
		pcall(function()
			RaycastParamsObject.CollisionGroup = BaseRaycastParamsObject.CollisionGroup
		end)
		pcall(function()
			RaycastParamsObject.RespectCanCollide = BaseRaycastParamsObject.RespectCanCollide
		end)
		pcall(function()
			RaycastParamsObject.BruteForceAllSlow = BaseRaycastParamsObject.BruteForceAllSlow
		end)
	else
		RaycastParamsObject.FilterType = Enum.RaycastFilterType.Blacklist
	end

	local FilterDescendantsInstances = {}
	local BaseIgnoredInstances = BaseRaycastParamsObject and BaseRaycastParamsObject.FilterDescendantsInstances or {}
	for _, IgnoredInstance in ipairs(BaseIgnoredInstances) do
		AppendUniqueIgnoredInstance(FilterDescendantsInstances, IgnoredInstance)
	end

	if ExtraIgnoredInstancesTable then
		for _, IgnoredInstance in ipairs(ExtraIgnoredInstancesTable) do
			AppendUniqueIgnoredInstance(FilterDescendantsInstances, IgnoredInstance)
		end
	end

	RaycastParamsObject.FilterDescendantsInstances = FilterDescendantsInstances
	return RaycastParamsObject
end

function GetVisibilityRaycastBaseParams()
	local FrameIdNumber = tonumber(CurrentFrameSequenceNumber) or 0
	if VisibilityRaycastBaseParamsFrameId == FrameIdNumber and VisibilityRaycastBaseParamsValue then
		return VisibilityRaycastBaseParamsValue
	end

	if IsBloodZonePlaceBoolean and ShieldModeRuntimeTable.GetCurrentLocalGunRaycastParams then
		local LocalCharacterModel = CurrentFrameLocalCharacterReadyBoolean and CurrentFrameLocalCharacterModel or ResolveCharacterModelForPlayer(LocalPlayer)
		local BaseRaycastParamsObject = ShieldModeRuntimeTable.GetCurrentLocalGunRaycastParams(LocalCharacterModel)
		if BaseRaycastParamsObject then
			VisibilityRaycastBaseParamsFrameId = FrameIdNumber
			VisibilityRaycastBaseParamsValue = BaseRaycastParamsObject
			return BaseRaycastParamsObject
		end
	end

	VisibilityRaycastBaseParamsFrameId = FrameIdNumber
	VisibilityRaycastBaseParamsValue = VisibilityRaycastParams
	return VisibilityRaycastParams
end

function DoesSegmentIntersectPartBounds(SegmentStartVector3, SegmentEndVector3, PartInstance)
	if not SegmentStartVector3 or not SegmentEndVector3 or not PartInstance then
		return false
	end

	local LocalStartVector3 = PartInstance.CFrame:PointToObjectSpace(SegmentStartVector3)
	local LocalEndVector3 = PartInstance.CFrame:PointToObjectSpace(SegmentEndVector3)
	local LocalDirectionVector3 = LocalEndVector3 - LocalStartVector3
	local HalfSizeVector3 = PartInstance.Size * 0.5
	local MinimumTimeNumber = 0
	local MaximumTimeNumber = 1
	local EpsilonNumber = 0.00001

	local function ClipAxis(StartCoordinateNumber, DirectionCoordinateNumber, HalfExtentNumber)
		if math.abs(DirectionCoordinateNumber) <= EpsilonNumber then
			return StartCoordinateNumber >= -HalfExtentNumber and StartCoordinateNumber <= HalfExtentNumber
		end

		local InverseDirectionNumber = 1 / DirectionCoordinateNumber
		local NearTimeNumber = (-HalfExtentNumber - StartCoordinateNumber) * InverseDirectionNumber
		local FarTimeNumber = (HalfExtentNumber - StartCoordinateNumber) * InverseDirectionNumber
		if NearTimeNumber > FarTimeNumber then
			NearTimeNumber, FarTimeNumber = FarTimeNumber, NearTimeNumber
		end

		MinimumTimeNumber = math.max(MinimumTimeNumber, NearTimeNumber)
		MaximumTimeNumber = math.min(MaximumTimeNumber, FarTimeNumber)
		return MaximumTimeNumber >= MinimumTimeNumber
	end

	if not ClipAxis(LocalStartVector3.X, LocalDirectionVector3.X, HalfSizeVector3.X) then
		return false
	end

	if not ClipAxis(LocalStartVector3.Y, LocalDirectionVector3.Y, HalfSizeVector3.Y) then
		return false
	end

	if not ClipAxis(LocalStartVector3.Z, LocalDirectionVector3.Z, HalfSizeVector3.Z) then
		return false
	end

	return MaximumTimeNumber >= 0 and MinimumTimeNumber <= 1
end

function IsTargetPointBlockedByMetalShield(TargetPositionVector3, CharacterModel)
	if not IsBloodZonePlaceBoolean or not TargetPositionVector3 or not CharacterModel then
		return false
	end

	local VisibilityOriginVector3 = CurrentVisibilityOriginVector3 or Camera.CFrame.Position
	local ShieldPartsTable = ShieldModeRuntimeTable.GetBloodZoneShieldVisibleParts
		and ShieldModeRuntimeTable.GetBloodZoneShieldVisibleParts(CharacterModel) or nil
	if type(ShieldPartsTable) == "table" then
		for _, ShieldPartInstance in ipairs(ShieldPartsTable) do
			if ShieldPartInstance.Parent
				and ShieldPartInstance.Transparency < 0.95
				and DoesSegmentIntersectPartBounds(VisibilityOriginVector3, TargetPositionVector3, ShieldPartInstance) then
				return true
			end
		end
		return false
	end

	local MetalShieldTool = GetBloodZoneMetalShieldTool(CharacterModel)
	if not MetalShieldTool then
		return false
	end

	for _, DescendantInstance in ipairs(MetalShieldTool.GetDescendants(MetalShieldTool)) do
		if DescendantInstance.IsA(DescendantInstance, "BasePart")
			and DescendantInstance.Transparency < 0.95
			and DoesSegmentIntersectPartBounds(VisibilityOriginVector3, TargetPositionVector3, DescendantInstance) then
			return true
		end
	end

	return false
end

RaycastBetweenIgnoringGlass = function(OriginVector3, TargetPositionVector3, ExtraIgnoredInstancesTable)
	if not OriginVector3 or not TargetPositionVector3 then
		return nil
	end

	local FullDirectionVector3 = TargetPositionVector3 - OriginVector3
	local FullDistanceNumber = FullDirectionVector3.Magnitude
	if FullDistanceNumber <= 0.001 then
		return nil
	end

	local DirectionUnitVector3 = FullDirectionVector3.Unit
	local BaseRaycastParamsObject = GetVisibilityRaycastBaseParams()
	local MutableIgnoredInstancesTable = nil
	local HasExtraIgnoredInstancesBoolean = ExtraIgnoredInstancesTable and #ExtraIgnoredInstancesTable > 0
	local CurrentOriginVector3 = OriginVector3
	local RemainingDistanceNumber = FullDistanceNumber

	if IsJailbirdPlaceBoolean then
		local MapCacheInstance = JailbirdVisibilityRuntimeTable.GetMapCacheInstance()
		if MapCacheInstance then
			MutableIgnoredInstancesTable = {}
			if HasExtraIgnoredInstancesBoolean then
				for _, IgnoredInstance in ipairs(ExtraIgnoredInstancesTable) do
					AppendUniqueIgnoredInstance(MutableIgnoredInstancesTable, IgnoredInstance)
				end
			end
			AppendUniqueIgnoredInstance(MutableIgnoredInstancesTable, MapCacheInstance)
			HasExtraIgnoredInstancesBoolean = #MutableIgnoredInstancesTable > 0
		end
	end

	for _ = 1, 16 do
		local ActiveIgnoredInstancesTable = MutableIgnoredInstancesTable
		if not ActiveIgnoredInstancesTable and HasExtraIgnoredInstancesBoolean then
			ActiveIgnoredInstancesTable = ExtraIgnoredInstancesTable
		end
		local RaycastParamsObject = ActiveIgnoredInstancesTable and CloneRaycastParamsWithIgnoredInstances(BaseRaycastParamsObject, ActiveIgnoredInstancesTable)
			or BaseRaycastParamsObject
		local RaycastResult = RunUnredirectedWorkspaceRaycast(
			CurrentOriginVector3,
			DirectionUnitVector3 * RemainingDistanceNumber,
			RaycastParamsObject
		)

		if not RaycastResult then
			return nil
		end

		if not IsGlassVisibilityPart(RaycastResult.Instance)
			and not JailbirdVisibilityRuntimeTable.IsPassThroughPart(RaycastResult.Instance) then
			return RaycastResult
		end

		if not MutableIgnoredInstancesTable then
			MutableIgnoredInstancesTable = {}
			if HasExtraIgnoredInstancesBoolean then
				for _, IgnoredInstance in ipairs(ExtraIgnoredInstancesTable) do
					AppendUniqueIgnoredInstance(MutableIgnoredInstancesTable, IgnoredInstance)
				end
			end
		end
		AppendUniqueIgnoredInstance(MutableIgnoredInstancesTable, RaycastResult.Instance)
		CurrentOriginVector3 = RaycastResult.Position + DirectionUnitVector3 * 0.01
		RemainingDistanceNumber = FullDistanceNumber - (CurrentOriginVector3 - OriginVector3).Magnitude
		if RemainingDistanceNumber <= 0.001 then
			return nil
		end
	end

	return nil
end

function RaycastToTargetIgnoringGlass(TargetPositionVector3)
	local OriginVector3 = CurrentVisibilityOriginVector3 or Camera.CFrame.Position
	return RaycastBetweenIgnoringGlass(OriginVector3, TargetPositionVector3, nil)
end

function CanUseSkyVisibilityCheck()
	return IsBloodZonePlaceBoolean
		and SillySkyVisibilityCheckEnabledBoolean
		and IsSillyModeBehaviorActive()
		and SillySkyAimEnabledBoolean
		and not ShieldModeEnabledBoolean
		and not ShieldModeRuntimeTable.IsProjectileWeaponProfile(CurrentWeaponBallisticsProfileTable)
end

function IsVisible(TargetPositionVector3, CharacterModel, PartInstance)
	if IsTargetPointBlockedByMetalShield(TargetPositionVector3, CharacterModel) then
		return false
	end

	local Result = RaycastToTargetIgnoringGlass(TargetPositionVector3)
	if not Result then
		return true
	end

	local HitTargetBoolean = false
	if PartInstance then
		HitTargetBoolean = Result.Instance == PartInstance or Result.Instance:IsDescendantOf(CharacterModel)
	else
		HitTargetBoolean = Result.Instance.IsDescendantOf(Result.Instance, CharacterModel)
	end
	if HitTargetBoolean then
		return true
	end

	return false
end

IsCharacterForceFieldProtected = function(CharacterModel, Humanoid)
	if not CharacterModel then
		return false
	end

	if CharacterModel.GetAttribute(CharacterModel, "InSafeZone") then
		return true
	end

	if Humanoid and Humanoid.GetAttribute and Humanoid.GetAttribute(Humanoid, "InSafeZone") then
		return true
	end

	if CharacterModel.FindFirstChildWhichIsA then
		local ForceFieldInstance = CharacterModel.FindFirstChildWhichIsA(CharacterModel, "ForceField", true)
		if ForceFieldInstance then
			return true
		end
	end

	if CharacterModel.FindFirstChild(CharacterModel, "ForceField", true) then
		return true
	end

	if CharacterModel.FindFirstChild(CharacterModel, "ForceFieldPARTICLE", true) then
		return true
	end

	return false
end

function ComputeCharacterAlive(CharacterModel)
	if not CharacterModel or not CharacterModel.Parent then
		return false
	end

	local Humanoid = GetCharacterHumanoid(CharacterModel)
	local RootPartInstance = GetCharacterRootPart(CharacterModel)
	if not Humanoid or not RootPartInstance then
		return false
	end

	if CharacterModel.GetAttribute(CharacterModel, "Carried") then
		return false
	end

	if CharacterModel.GetAttribute(CharacterModel, "Escaped") then
		return false
	end

	if CollectionService.HasTag(CollectionService, CharacterModel, "DeadBody") then
		return false
	end

	if Humanoid.GetAttribute and Humanoid.GetAttribute(Humanoid, "Dead") then
		return false
	end

	if IsCharacterForceFieldProtected(CharacterModel, Humanoid) then
		return false
	end

	if IsCustomCharacterGameBoolean then
		if CharacterModel.GetAttribute(CharacterModel, "Downed") then
			return true
		end

		if CharacterModel.GetAttribute(CharacterModel, "IsRagdolled") then
			return true
		end
	end

	local HealthNumber = Humanoid.Health
	if type(HealthNumber) == "number" then
		if HealthNumber > 0 then
			return true
		end

		return false
	end

	return false
end

function IsCharacterAlive(CharacterModel)
	if not CharacterModel then
		return false
	end

	local CachedAliveValue = FrameCharacterAliveCacheTable[CharacterModel]
	if CachedAliveValue ~= nil then
		return CachedAliveValue
	end

	local AliveBoolean = ComputeCharacterAlive(CharacterModel)
	FrameCharacterAliveCacheTable[CharacterModel] = AliveBoolean
	return AliveBoolean
end

EspRuntimeTable.CreateLine = function(self, ThicknessNumber)
	local Line = Drawing.new("Line")
	Line.Thickness = ThicknessNumber or 1
	Line.Transparency = 1
	Line.Color = self.defaultColor
	Line.Visible = false
	return Line
end

EspRuntimeTable.CreateText = function(self, SizeNumber)
	local TextDrawing = Drawing.new("Text")
	TextDrawing.Size = SizeNumber or 13
	TextDrawing.Transparency = 1
	TextDrawing.Color = self.infoColor
	TextDrawing.Visible = false
	TextDrawing.Center = true
	pcall(function()
		TextDrawing.Outline = true
	end)
	return TextDrawing
end

EspRuntimeTable.CreateSquare = function(self, FilledBoolean)
	local Square = Drawing.new("Square")
	Square.Filled = FilledBoolean == true
	Square.Thickness = 1
	Square.Transparency = 1
	Square.Visible = false
	return Square
end

EspRuntimeTable.GetHighlightHost = function(self)
	local HighlightHost = self.highlightHost
	if HighlightHost and HighlightHost.Parent then
		return HighlightHost
	end

	HighlightHost = Instance.new("Folder")
	HighlightHost.Name = "TrueAimHighlights"
	pcall(function()
		HighlightHost.Parent = WorkspaceService
	end)
	if not HighlightHost.Parent then
		local PlayerGui = LocalPlayer and LocalPlayer.FindFirstChild(LocalPlayer, "PlayerGui") or nil
		if PlayerGui then
			pcall(function()
				HighlightHost.Parent = PlayerGui
			end)
		end
	end
	if not HighlightHost.Parent and MenuGui then
		pcall(function()
			HighlightHost.Parent = MenuGui
		end)
	end
	if not HighlightHost.Parent then
		return nil
	end

	self.highlightHost = HighlightHost
	return HighlightHost
end

EspRuntimeTable.CreateHighlight = function(self, CharacterModel)
	if not CharacterModel or not CharacterModel.Parent then
		return nil
	end
	local HighlightHost = self:GetHighlightHost()
	if not HighlightHost then
		return nil
	end
	local HighlightObject = Instance.new("Highlight")
	HighlightObject.Name = "TrueAimHighlight"
	HighlightObject.Adornee = CharacterModel
	HighlightObject.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	HighlightObject.FillTransparency = self.highlightFillTransparency or 0.84
	HighlightObject.OutlineTransparency = self.highlightOutlineTransparency or 0.08
	HighlightObject.Enabled = false
	HighlightObject.Parent = HighlightHost
	return HighlightObject
end

EspRuntimeTable.RemoveDrawingObject = function(self, DrawingObject)
	if not DrawingObject then
		return
	end
	pcall(function()
		if DrawingObject.Remove then
			DrawingObject.Remove(DrawingObject)
		elseif DrawingObject.Destroy then
			DrawingObject.Destroy(DrawingObject)
		end
	end)
end

EspRuntimeTable.ResolvePartFromNames = function(self, CharacterModel, PartNamesTable)
	if not CharacterModel or type(PartNamesTable) ~= "table" then
		return nil
	end
	for _, PartNameString in ipairs(PartNamesTable) do
		local PartInstance = CharacterModel.FindFirstChild(CharacterModel, PartNameString)
		if PartInstance and PartInstance.IsA(PartInstance, "BasePart") then
			return PartInstance
		end
	end
	return nil
end

EspRuntimeTable.ResolveRigProfile = function(self, CharacterModel)
	local Humanoid = GetCharacterHumanoid(CharacterModel)
	if Humanoid and Humanoid.RigType == Enum.HumanoidRigType.R6 then
		return self.rigProfiles.R6
	end
	if CharacterModel
		and (
			CharacterModel.FindFirstChild(CharacterModel, "UpperTorso")
			or CharacterModel.FindFirstChild(CharacterModel, "LowerTorso")
		) then
		return self.rigProfiles.R15
	end
	return self.rigProfiles.Fallback
end

EspRuntimeTable.GetAccentColor = function(self, PlayerObject, CharacterModel)
	if CharacterModel and CurrentTargetCharacterModel == CharacterModel then
		return self.targetColor
	end
	if PlayerObject and PlayerListRuntimeTable.IsPriorityPlayer(PlayerObject) then
		return self.priorityColor
	end
	if PlayerObject and PlayerListRuntimeTable.IsPlayerWhitelisted(PlayerObject) then
		return self.whitelistColor
	end
	return self.defaultColor
end

EspRuntimeTable.UpdateHighlight = function(self, DrawingSet, CharacterModel, AccentColor3)
	local HighlightObject = DrawingSet and DrawingSet.highlight or nil
	if not EspHighlightEnabledBoolean then
		if HighlightObject then
			HighlightObject.Enabled = false
		end
		return
	end
	if (not HighlightObject or not HighlightObject.Parent) and CharacterModel and CharacterModel.Parent then
		HighlightObject = self:CreateHighlight(CharacterModel)
		DrawingSet.highlight = HighlightObject
	end
	if not HighlightObject then
		return
	end
	local IsCurrentTargetBoolean = CharacterModel and CharacterModel == CurrentTargetCharacterModel
	HighlightObject.Adornee = CharacterModel
	HighlightObject.FillColor = AccentColor3
	HighlightObject.OutlineColor = AccentColor3:Lerp(Color3.fromRGB(255, 255, 255), 0.35)
	HighlightObject.FillTransparency = IsCurrentTargetBoolean
		and (self.highlightTargetFillTransparency or 0.72)
		or (self.highlightFillTransparency or 0.84)
	HighlightObject.OutlineTransparency = IsCurrentTargetBoolean
		and (self.highlightTargetOutlineTransparency or 0.02)
		or (self.highlightOutlineTransparency or 0.08)
	HighlightObject.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	HighlightObject.Enabled = true
end

EspRuntimeTable.GetHealthColor = function(self, HealthRatioNumber)
	local RatioNumber = math.clamp(tonumber(HealthRatioNumber) or 0, 0, 1)
	return Color3.fromRGB(
		math.floor(255 * (1 - RatioNumber) + 0.5),
		math.floor(255 * RatioNumber + 0.5),
		70
	)
end

EspRuntimeTable.GetDisplayName = function(self, PlayerObject, CharacterModel)
	if PlayerObject then
		return PlayerListRuntimeTable.GetDisplayName(PlayerObject)
	end
	return GetCharacterIdentityString(CharacterModel) or "Unknown"
end

EspRuntimeTable.GetHealthInfo = function(self, CharacterModel)
	local Humanoid = GetCharacterHumanoid(CharacterModel)
	if not Humanoid then
		return 0, 100, 0
	end
	local HealthNumber = tonumber(Humanoid.Health) or 0
	local MaxHealthNumber = tonumber(Humanoid.MaxHealth) or 0
	if MaxHealthNumber <= 0 then
		MaxHealthNumber = HealthNumber > 0 and HealthNumber or 100
	end
	return HealthNumber, MaxHealthNumber, math.clamp(HealthNumber / MaxHealthNumber, 0, 1)
end

EspRuntimeTable.GetOrCreateDrawings = function(self, CharacterModel)
	local DrawingSet = self.drawingsByCharacter[CharacterModel]
	if DrawingSet then
		return DrawingSet
	end
	DrawingSet = {
		highlight = nil,
		skeletonLines = {},
		nameText = self:CreateText(13),
		infoText = self:CreateText(12),
		healthBarOutline = self:CreateSquare(false),
		healthBarFill = self:CreateSquare(true),
		projectedPoints = {},
		projectedVisibleFlags = {},
		rigCache = nil,
		lastUpdateTime = 0,
		lastVisible = false,
		lastSeenFrame = 0,
	}
	for LineIndex = 1, self.maxSkeletonLineCount do
		DrawingSet.skeletonLines[LineIndex] = self:CreateLine(self.skeletonThickness)
	end
	self.drawingsByCharacter[CharacterModel] = DrawingSet
	return DrawingSet
end

EspRuntimeTable.HideDrawingSet = function(self, DrawingSet)
	if not DrawingSet then
		return
	end
	DrawingSet.lastVisible = false
	for _, Line in ipairs(DrawingSet.skeletonLines or {}) do
		Line.Visible = false
	end
	if DrawingSet.nameText then
		DrawingSet.nameText.Visible = false
	end
	if DrawingSet.infoText then
		DrawingSet.infoText.Visible = false
	end
	if DrawingSet.healthBarOutline then
		DrawingSet.healthBarOutline.Visible = false
	end
	if DrawingSet.healthBarFill then
		DrawingSet.healthBarFill.Visible = false
	end
	if DrawingSet.highlight then
		DrawingSet.highlight.Enabled = false
	end
end

EspRuntimeTable.HideAll = function(self)
	for _, DrawingSet in pairs(self.drawingsByCharacter) do
		self:HideDrawingSet(DrawingSet)
	end
end

EspRuntimeTable.ClearHighlights = function(self)
	for _, DrawingSet in pairs(self.drawingsByCharacter) do
		if DrawingSet.highlight then
			self:RemoveDrawingObject(DrawingSet.highlight)
			DrawingSet.highlight = nil
		end
	end
end

EspRuntimeTable.HideSkeletons = function(self)
	for _, DrawingSet in pairs(self.drawingsByCharacter) do
		for _, Line in ipairs(DrawingSet.skeletonLines or {}) do
			Line.Visible = false
		end
	end
end

EspRuntimeTable.RemoveCharacterDrawings = function(self, CharacterModel)
	local DrawingSet = self.drawingsByCharacter[CharacterModel]
	if not DrawingSet then
		return
	end
	for _, DrawingObject in ipairs(DrawingSet.skeletonLines or {}) do
		self:RemoveDrawingObject(DrawingObject)
	end
	self:RemoveDrawingObject(DrawingSet.nameText)
	self:RemoveDrawingObject(DrawingSet.infoText)
	self:RemoveDrawingObject(DrawingSet.healthBarOutline)
	self:RemoveDrawingObject(DrawingSet.healthBarFill)
	self:RemoveDrawingObject(DrawingSet.highlight)
	self.drawingsByCharacter[CharacterModel] = nil
end

EspRuntimeTable.GetCharacterEntries = function(self, LocalCharacterModel, TeamCheckEnabledBoolean, LocalTeamObject)
	local CacheKeyString = tostring(LocalCharacterModel) .. "|" .. tostring(TeamCheckEnabledBoolean) .. "|" .. tostring(LocalTeamObject)
	local NowNumber = tick()
	if self.entryCacheKey == CacheKeyString
		and (NowNumber - self.entryCacheTime) < self.entryCacheDuration then
		return self.entryCacheTable
	end

	local CharacterEntries = {}
	local SeenCharacterModels = {}

	local function AddCharacterEntry(PlayerObject, CharacterModel)
		if not CharacterModel
			or not CharacterModel.Parent
			or not IsHumanoidCharacterModel(CharacterModel)
			or not GetCharacterRootPart(CharacterModel)
			or IsLocalControlledCharacterModel(CharacterModel, LocalCharacterModel)
			or SeenCharacterModels[CharacterModel] then
			return
		end
		if IsCustomCharacterGameBoolean and not PlayerObject then
			return
		end
		if TeamCheckEnabledBoolean and PlayerObject and LocalTeamObject and PlayerObject.Team == LocalTeamObject then
			return
		end
		SeenCharacterModels[CharacterModel] = true
		CharacterEntries[#CharacterEntries + 1] = {
			player = PlayerObject,
			character = CharacterModel,
		}
	end

	if IsCustomCharacterGameBoolean then
		for _, CharacterModel in ipairs(GetCharacterModelsFromCharactersFolder()) do
			AddCharacterEntry(FindPlayerForCharacterModel(CharacterModel), CharacterModel)
		end
	else
		for _, PlayerObject in ipairs(Players.GetPlayers(Players)) do
			if PlayerObject ~= LocalPlayer then
				AddCharacterEntry(PlayerObject, ResolveCharacterModelForPlayer(PlayerObject))
			end
		end
	end

	self.entryCacheTable = CharacterEntries
	self.entryCacheKey = CacheKeyString
	self.entryCacheTime = NowNumber
	return CharacterEntries
end

EspRuntimeTable.GetRigParts = function(self, DrawingSet, CharacterModel)
	local ProfileTable = self:ResolveRigProfile(CharacterModel)
	local ChildCountNumber = #CharacterModel.GetChildren(CharacterModel)
	local NowNumber = tick()
	local RigCacheTable = DrawingSet.rigCache
	if RigCacheTable
		and RigCacheTable.profile == ProfileTable
		and RigCacheTable.childCount == ChildCountNumber
		and (NowNumber - RigCacheTable.time) < self.rigCacheDuration then
		return ProfileTable, RigCacheTable.parts
	end

	local PartsTable = {}
	for _, PointDefinitionTable in ipairs(ProfileTable.pointDefinitions) do
		PartsTable[PointDefinitionTable.key] = self:ResolvePartFromNames(CharacterModel, PointDefinitionTable.names)
	end

	DrawingSet.rigCache = {
		profile = ProfileTable,
		parts = PartsTable,
		childCount = ChildCountNumber,
		time = NowNumber,
	}
	return ProfileTable, PartsTable
end

EspRuntimeTable.ProjectRigPoints = function(self, DrawingSet, ProfileTable, PartsTable)
	local ProjectedPointsTable = ClearMutableTable(DrawingSet.projectedPoints or {})
	local VisibleFlagsTable = ClearMutableTable(DrawingSet.projectedVisibleFlags or {})
	DrawingSet.projectedPoints = ProjectedPointsTable
	DrawingSet.projectedVisibleFlags = VisibleFlagsTable

	local AnyOnScreenBoolean = false
	local MinXNumber = math.huge
	local MinYNumber = math.huge
	local MaxXNumber = -math.huge
	local MaxYNumber = -math.huge

	for _, PointDefinitionTable in ipairs(ProfileTable.pointDefinitions) do
		local PartInstance = PartsTable[PointDefinitionTable.key]
		if PartInstance and PartInstance.Parent then
			local WorldPointVector3 = PartInstance.Position
			if typeof(PointDefinitionTable.offset) == "Vector3" then
				local PartSizeVector3 = PartInstance.Size
				local OffsetVector3 = PointDefinitionTable.offset
				WorldPointVector3 = PartInstance.CFrame * Vector3.new(
					PartSizeVector3.X * OffsetVector3.X,
					PartSizeVector3.Y * OffsetVector3.Y,
					PartSizeVector3.Z * OffsetVector3.Z
				)
			end
			local ScreenPointVector3, OnScreenBoolean = Camera.WorldToViewportPoint(Camera, WorldPointVector3)
			if ScreenPointVector3.Z > 0 then
				local ScreenPointVector2 = Vector2.new(ScreenPointVector3.X, ScreenPointVector3.Y)
				ProjectedPointsTable[PointDefinitionTable.key] = ScreenPointVector2
				VisibleFlagsTable[PointDefinitionTable.key] = OnScreenBoolean
				if OnScreenBoolean then
					AnyOnScreenBoolean = true
					MinXNumber = math.min(MinXNumber, ScreenPointVector2.X)
					MinYNumber = math.min(MinYNumber, ScreenPointVector2.Y)
					MaxXNumber = math.max(MaxXNumber, ScreenPointVector2.X)
					MaxYNumber = math.max(MaxYNumber, ScreenPointVector2.Y)
				end
			end
		end
	end

	return ProjectedPointsTable, VisibleFlagsTable, AnyOnScreenBoolean, MinXNumber, MinYNumber, MaxXNumber, MaxYNumber
end

EspRuntimeTable.UpdateSkeleton = function(self, DrawingSet, ProfileTable, ProjectedPointsTable, VisibleFlagsTable, AccentColor3)
	for LineIndex = 1, self.maxSkeletonLineCount do
		local Line = DrawingSet.skeletonLines[LineIndex]
		local ConnectionTable = ProfileTable.connections[LineIndex]
		if not EspSkeletonEnabledBoolean or not ConnectionTable then
			Line.Visible = false
			continue
		end

		local StartPointVector2 = ProjectedPointsTable[ConnectionTable[1]]
		local EndPointVector2 = ProjectedPointsTable[ConnectionTable[2]]
		local StartVisibleBoolean = VisibleFlagsTable[ConnectionTable[1]] == true
		local EndVisibleBoolean = VisibleFlagsTable[ConnectionTable[2]] == true
		if not StartPointVector2 or not EndPointVector2 or not (StartVisibleBoolean or EndVisibleBoolean) then
			Line.Visible = false
			continue
		end

		Line.From = StartPointVector2
		Line.To = EndPointVector2
		Line.Color = AccentColor3
		Line.Visible = true
	end
end

EspRuntimeTable.UpdateOverlay = function(self, DrawingSet, CharacterModel, PlayerObject, ProjectedPointsTable, VisibleFlagsTable, MinXNumber, MinYNumber, MaxXNumber, MaxYNumber, DistanceNumber, AccentColor3)
	local HealthNumber, MaxHealthNumber, HealthRatioNumber = self:GetHealthInfo(CharacterModel)
	local HeaderPointVector2 = ProjectedPointsTable.head
		or ProjectedPointsTable.neck
		or ProjectedPointsTable.torso
		or ProjectedPointsTable.pelvis
	local HeaderVisibleBoolean = VisibleFlagsTable.head == true
		or VisibleFlagsTable.neck == true
		or VisibleFlagsTable.torso == true
		or VisibleFlagsTable.pelvis == true
	local CenterXNumber = HeaderPointVector2 and HeaderPointVector2.X or ((MinXNumber + MaxXNumber) * 0.5)
	local NameYNumber = HeaderPointVector2 and (HeaderPointVector2.Y - 18) or (MinYNumber - 16)
	if not HeaderVisibleBoolean then
		NameYNumber = MinYNumber - 16
	end

	DrawingSet.nameText.Text = self:GetDisplayName(PlayerObject, CharacterModel)
	DrawingSet.nameText.Position = Vector2.new(math.floor(CenterXNumber + 0.5), math.floor(NameYNumber + 0.5))
	DrawingSet.nameText.Color = AccentColor3
	DrawingSet.nameText.Visible = true

	DrawingSet.infoText.Text = tostring(math.floor(DistanceNumber + 0.5)) .. " studs | " .. tostring(math.floor(HealthNumber + 0.5)) .. "/" .. tostring(math.floor(MaxHealthNumber + 0.5)) .. " HP"
	DrawingSet.infoText.Position = Vector2.new(math.floor(((MinXNumber + MaxXNumber) * 0.5) + 0.5), math.floor(MaxYNumber + 4 + 0.5))
	DrawingSet.infoText.Color = self.infoColor
	DrawingSet.infoText.Visible = true

	local HealthBarHeightNumber = math.max(8, math.floor(MaxYNumber - MinYNumber + 0.5))
	local HealthBarXNumber = math.floor(MinXNumber - 7.5)
	local HealthBarYNumber = math.floor(MinYNumber + 0.5)
	local FilledHeightNumber = math.clamp(math.floor(HealthBarHeightNumber * HealthRatioNumber + 0.5), 0, HealthBarHeightNumber)

	DrawingSet.healthBarOutline.Position = Vector2.new(HealthBarXNumber, HealthBarYNumber)
	DrawingSet.healthBarOutline.Size = Vector2.new(4, HealthBarHeightNumber)
	DrawingSet.healthBarOutline.Color = Color3.fromRGB(12, 12, 12)
	DrawingSet.healthBarOutline.Visible = true

	DrawingSet.healthBarFill.Position = Vector2.new(HealthBarXNumber + 1, HealthBarYNumber + (HealthBarHeightNumber - FilledHeightNumber) + 1)
	DrawingSet.healthBarFill.Size = Vector2.new(2, math.max(0, FilledHeightNumber - 2))
	DrawingSet.healthBarFill.Color = self:GetHealthColor(HealthRatioNumber)
	DrawingSet.healthBarFill.Visible = FilledHeightNumber > 1
end

EspRuntimeTable.UpdateCharacter = function(self, CharacterModel, PlayerObject)
	local DrawingSet = self:GetOrCreateDrawings(CharacterModel)
	local NowNumber = tick()
	local AnchorPartInstance = GetCharacterRootPart(CharacterModel)
		or GetCharacterTorsoLikePart(CharacterModel)
		or GetCharacterHeadPart(CharacterModel)
	if not AnchorPartInstance or not AnchorPartInstance.Parent then
		self:HideDrawingSet(DrawingSet)
		DrawingSet.lastUpdateTime = NowNumber
		return false
	end

	local DistanceOriginVector3 = CurrentVisibilityOriginVector3 or Camera.CFrame.Position
	local DistanceNumber = (AnchorPartInstance.Position - DistanceOriginVector3).Magnitude
	if DistanceNumber > MaxDistanceNumber then
		self:HideDrawingSet(DrawingSet)
		DrawingSet.lastUpdateTime = NowNumber
		return false
	end
	local AnchorScreenPointVector3, AnchorOnScreenBoolean = Camera.WorldToViewportPoint(Camera, AnchorPartInstance.Position)
	if AnchorScreenPointVector3.Z <= 0 then
		self:HideDrawingSet(DrawingSet)
		DrawingSet.lastUpdateTime = NowNumber
		return false
	end
	if not AnchorOnScreenBoolean then
		local ViewportSizeVector2 = Camera.ViewportSize
		local CullMarginNumber = self.offscreenCullMargin or 140
		if AnchorScreenPointVector3.X < -CullMarginNumber
			or AnchorScreenPointVector3.X > (ViewportSizeVector2.X + CullMarginNumber)
			or AnchorScreenPointVector3.Y < -CullMarginNumber
			or AnchorScreenPointVector3.Y > (ViewportSizeVector2.Y + CullMarginNumber) then
			self:HideDrawingSet(DrawingSet)
			DrawingSet.lastUpdateTime = NowNumber
			return false
		end
	end

	local ProfileTable, PartsTable = self:GetRigParts(DrawingSet, CharacterModel)
	local ProjectedPointsTable, VisibleFlagsTable, AnyOnScreenBoolean, MinXNumber, MinYNumber, MaxXNumber, MaxYNumber = self:ProjectRigPoints(DrawingSet, ProfileTable, PartsTable)
	if not AnyOnScreenBoolean or MinXNumber == math.huge or MinYNumber == math.huge then
		self:HideDrawingSet(DrawingSet)
		DrawingSet.lastUpdateTime = NowNumber
		return false
	end

	local AccentColor3 = self:GetAccentColor(PlayerObject, CharacterModel)
	self:UpdateHighlight(DrawingSet, CharacterModel, AccentColor3)
	self:UpdateSkeleton(DrawingSet, ProfileTable, ProjectedPointsTable, VisibleFlagsTable, AccentColor3)
	self:UpdateOverlay(DrawingSet, CharacterModel, PlayerObject, ProjectedPointsTable, VisibleFlagsTable, MinXNumber, MinYNumber, MaxXNumber, MaxYNumber, DistanceNumber, AccentColor3)
	DrawingSet.lastVisible = true
	DrawingSet.lastUpdateTime = NowNumber
	DrawingSet.lastSeenFrame = CurrentFrameSequenceNumber
	return true
end

EspRuntimeTable.Update = function(self, LocalCharacterModel, TeamCheckEnabledBoolean, LocalTeamObject)
	if not EspEnabledBoolean or not Camera then
		self:HideAll()
		return
	end

	for CharacterModel in pairs(self.drawingsByCharacter) do
		if not CharacterModel or not CharacterModel.Parent then
			self:RemoveCharacterDrawings(CharacterModel)
		end
	end

	local CharacterEntries = self:GetCharacterEntries(LocalCharacterModel, TeamCheckEnabledBoolean, LocalTeamObject)
	for _, EntryTable in ipairs(CharacterEntries) do
		if IsCharacterAlive(EntryTable.character) then
			self:UpdateCharacter(EntryTable.character, EntryTable.player)
		else
			self:HideDrawingSet(self.drawingsByCharacter[EntryTable.character])
		end
	end

	for _, DrawingSet in pairs(self.drawingsByCharacter) do
		if DrawingSet.lastSeenFrame ~= CurrentFrameSequenceNumber then
			self:HideDrawingSet(DrawingSet)
		end
	end
end

function GetProjectileArcVisibleTargetData(PartInstance, CharacterModel)
	local WeaponBallisticsProfileTable = CurrentWeaponBallisticsProfileTable
	if not ShouldUseProjectileArcVisibilityProfile(WeaponBallisticsProfileTable) then
		return nil
	end
	if not PartInstance or not PartInstance.Parent or not CharacterModel or not CharacterModel.Parent then
		return nil
	end

	local LocalCharacterModel = ResolveCharacterModelForPlayer(LocalPlayer)
	if not LocalCharacterModel or not LocalCharacterModel.Parent then
		return nil
	end

	local TargetPointVector3, PreferredTargetPartInstance = ResolveProjectileBaseTargetPointVector3(
		CharacterModel,
		PartInstance,
		PartInstance.Position,
		WeaponBallisticsProfileTable
	)
	if typeof(TargetPointVector3) ~= "Vector3" then
		return nil
	end
	if IsTargetPointBlockedByMetalShield(TargetPointVector3, CharacterModel) then
		return nil
	end

	local EffectivePartInstance = PreferredTargetPartInstance or PartInstance
	local AimSolutionTable = ResolveProjectileAimSolutionTable(
		LocalCharacterModel,
		CharacterModel,
		EffectivePartInstance,
		TargetPointVector3,
		WeaponBallisticsProfileTable,
		true
	)
	if not AimSolutionTable then
		return nil
	end

	return {
		point = AimSolutionTable.targetPoint or TargetPointVector3,
		cubeCFrame = EffectivePartInstance.CFrame,
		cubeSize = EffectivePartInstance.Size,
		part = EffectivePartInstance,
	}
end

function GetSkyVisibleTargetData(PartInstance, CharacterModel)
	if not CanUseSkyVisibilityCheck() then
		return nil
	end
	if not PartInstance or not PartInstance.Parent or not CharacterModel or not CharacterModel.Parent then
		return nil
	end

	local LocalCharacterModel = CurrentFrameLocalCharacterModel
	if not CurrentFrameLocalCharacterReadyBoolean or not LocalCharacterModel or not LocalCharacterModel.Parent then
		return nil
	end

	local EquippedTool = ShieldModeRuntimeTable.GetEquippedTool and ShieldModeRuntimeTable.GetEquippedTool(LocalCharacterModel) or nil
	local TargetPointVector3 = PartInstance.Position
	local SkyAimSolutionTable = ResolveSkyAimSolution(
		LocalCharacterModel,
		nil,
		EquippedTool,
		TargetPointVector3,
		CharacterModel,
		PartInstance,
		true,
		3
	)
	if not SkyAimSolutionTable or (SkyAimSolutionTable.priority or -1) < 3 then
		return nil
	end

	return {
		point = TargetPointVector3,
		cubeCFrame = PartInstance.CFrame,
		cubeSize = PartInstance.Size,
		part = PartInstance,
	}
end

function ShieldModeRuntimeTable.ResolveVisibleSurfacePointForPart(PartInstance, CharacterModel, MouseLocationVector2, SubdivisionNumber, UseNearFacesOnlyBoolean)
	SubdivisionNumber = math.max(tonumber(SubdivisionNumber) or 1, 1)

	local PartSize = PartInstance.Size
	local HalfSize = PartSize * 0.5
	local StepSize = Vector3.new(PartSize.X / SubdivisionNumber, PartSize.Y / SubdivisionNumber, PartSize.Z / SubdivisionNumber)
	local HalfStep = StepSize * 0.5
	local BestPointVector3 = nil
	local BestCubeCFrame = nil
	local BestCubeSize = nil
	local BestDistanceNumber = math.huge
	local Rotation = PartInstance.CFrame - PartInstance.CFrame.Position
	local ThicknessNumber = math.min(StepSize.X, StepSize.Y, StepSize.Z)

	local function EvaluateSurfacePoint(LocalPoint, LocalCenter, CellSize)
		local TargetPointVector3 = PartInstance.CFrame:PointToWorldSpace(LocalPoint)
		local ScreenPositionVector3, OnScreenBoolean = Camera.WorldToViewportPoint(Camera, TargetPointVector3)
		if not OnScreenBoolean then
			return
		end
		local ScreenPositionVector2 = Vector2.new(ScreenPositionVector3.X, ScreenPositionVector3.Y)
		local ScreenDistanceNumber = (ScreenPositionVector2 - MouseLocationVector2).Magnitude
		if ScreenDistanceNumber >= BestDistanceNumber then
			return
		end
		if not IsVisible(TargetPointVector3, CharacterModel, PartInstance) then
			return
		end
		BestDistanceNumber = ScreenDistanceNumber
		BestPointVector3 = TargetPointVector3
		BestCubeCFrame = CFrame.new(PartInstance.CFrame:PointToWorldSpace(LocalCenter)) * Rotation
		BestCubeSize = CellSize
	end

	local function EvaluateAxisFace(AxisString, AxisSignNumber)
		if AxisString == "X" then
			local FaceOffset = AxisSignNumber * HalfSize.X
			local CenterOffset = AxisSignNumber * (HalfSize.X - ThicknessNumber / 2)
			for YIndex = 0, SubdivisionNumber - 1 do
				local YOffset = -HalfSize.Y + HalfStep.Y + StepSize.Y * YIndex
				for ZIndex = 0, SubdivisionNumber - 1 do
					local ZOffset = -HalfSize.Z + HalfStep.Z + StepSize.Z * ZIndex
					EvaluateSurfacePoint(
						Vector3.new(FaceOffset, YOffset, ZOffset),
						Vector3.new(CenterOffset, YOffset, ZOffset),
						Vector3.new(ThicknessNumber, StepSize.Y, StepSize.Z)
					)
				end
			end
			return
		end

		if AxisString == "Y" then
			local FaceOffset = AxisSignNumber * HalfSize.Y
			local CenterOffset = AxisSignNumber * (HalfSize.Y - ThicknessNumber / 2)
			for XIndex = 0, SubdivisionNumber - 1 do
				local XOffset = -HalfSize.X + HalfStep.X + StepSize.X * XIndex
				for ZIndex = 0, SubdivisionNumber - 1 do
					local ZOffset = -HalfSize.Z + HalfStep.Z + StepSize.Z * ZIndex
					EvaluateSurfacePoint(
						Vector3.new(XOffset, FaceOffset, ZOffset),
						Vector3.new(XOffset, CenterOffset, ZOffset),
						Vector3.new(StepSize.X, ThicknessNumber, StepSize.Z)
					)
				end
			end
			return
		end

		local FaceOffset = AxisSignNumber * HalfSize.Z
		local CenterOffset = AxisSignNumber * (HalfSize.Z - ThicknessNumber / 2)
		for XIndex = 0, SubdivisionNumber - 1 do
			local XOffset = -HalfSize.X + HalfStep.X + StepSize.X * XIndex
			for YIndex = 0, SubdivisionNumber - 1 do
				local YOffset = -HalfSize.Y + HalfStep.Y + StepSize.Y * YIndex
				EvaluateSurfacePoint(
					Vector3.new(XOffset, YOffset, FaceOffset),
					Vector3.new(XOffset, YOffset, CenterOffset),
					Vector3.new(StepSize.X, StepSize.Y, ThicknessNumber)
				)
			end
		end
	end

	if UseNearFacesOnlyBoolean then
		local LocalOriginVector3 = PartInstance.CFrame:PointToObjectSpace(CurrentVisibilityOriginVector3 or Camera.CFrame.Position)
		EvaluateAxisFace("X", LocalOriginVector3.X >= 0 and 1 or -1)
		EvaluateAxisFace("Y", LocalOriginVector3.Y >= 0 and 1 or -1)
		EvaluateAxisFace("Z", LocalOriginVector3.Z >= 0 and 1 or -1)
	else
		EvaluateAxisFace("X", 1)
		EvaluateAxisFace("X", -1)
		EvaluateAxisFace("Y", 1)
		EvaluateAxisFace("Y", -1)
		EvaluateAxisFace("Z", 1)
		EvaluateAxisFace("Z", -1)
	end

	if not BestPointVector3 then
		return nil
	end

	return {
		point = BestPointVector3,
		cubeCFrame = BestCubeCFrame,
		cubeSize = BestCubeSize,
	}
end

function ShieldModeRuntimeTable.GetJailbirdVisiblePointForPart(PartInstance, CharacterModel, MouseLocationVector2)
	local CenterPointVector3 = PartInstance.Position
	if IsVisible(CenterPointVector3, CharacterModel, PartInstance) then
		return {
			point = CenterPointVector3,
			cubeCFrame = PartInstance.CFrame,
			cubeSize = PartInstance.Size,
		}
	end

	local ProjectileArcVisibleTargetData = GetProjectileArcVisibleTargetData(PartInstance, CharacterModel)
	if ProjectileArcVisibleTargetData then
		return ProjectileArcVisibleTargetData
	end

	return ShieldModeRuntimeTable.ResolveVisibleSurfacePointForPart(
		PartInstance,
		CharacterModel,
		MouseLocationVector2,
		3,
		true
	)
end

function GetVisiblePointForPart(PartInstance, CharacterModel, MouseLocationVector2)
	if not IsEffectiveTargetSegmentationEnabled() then
		if IsJailbirdPlaceBoolean then
			return ShieldModeRuntimeTable.GetJailbirdVisiblePointForPart(PartInstance, CharacterModel, MouseLocationVector2)
		end
		local CenterPointVector3 = PartInstance.Position
		if IsVisible(CenterPointVector3, CharacterModel, PartInstance) then
			return {
				point = CenterPointVector3,
				cubeCFrame = PartInstance.CFrame,
				cubeSize = PartInstance.Size,
			}
		end
		local ProjectileArcVisibleTargetData = GetProjectileArcVisibleTargetData(PartInstance, CharacterModel)
		if ProjectileArcVisibleTargetData then
			return ProjectileArcVisibleTargetData
		end
		if IsBloodZonePlaceBoolean then
			return GetSkyVisibleTargetData(PartInstance, CharacterModel)
		end
		return nil
	end

	local CenterPointVector3 = PartInstance.Position
	if IsVisible(CenterPointVector3, CharacterModel, PartInstance) then
		return {
			point = CenterPointVector3,
			cubeCFrame = PartInstance.CFrame,
			cubeSize = PartInstance.Size,
		}
	end

	local ProjectileArcVisibleTargetData = GetProjectileArcVisibleTargetData(PartInstance, CharacterModel)
	if ProjectileArcVisibleTargetData then
		return ProjectileArcVisibleTargetData
	end

	local VisibleTargetData = ShieldModeRuntimeTable.ResolveVisibleSurfacePointForPart(
		PartInstance,
		CharacterModel,
		MouseLocationVector2,
		VisibleCheckSubdivisionsNumber
	)
	if VisibleTargetData then
		return VisibleTargetData
	end

	if IsBloodZonePlaceBoolean then
		return GetSkyVisibleTargetData(PartInstance, CharacterModel)
	end
	return nil
end

function ShieldModeRuntimeTable.RejectTargetDataForPart(ReasonKey, DebugKey, CharacterModel, PartInstance, MessageString)
	RecordRejectReason(ReasonKey)
	if DebugModeEnabledBoolean then
		DebugLog(DebugKey, "Rejected " .. GetTargetIdentity(nil, CharacterModel, PartInstance) .. " because " .. MessageString, false)
	end
	return nil
end

function ShieldModeRuntimeTable.ClampPointToPart(TargetPointVector3, ClampPartInstance)
	local HalfSize = ClampPartInstance.Size * 0.5
	local Inset = math.min(0.05, math.min(HalfSize.X, HalfSize.Y, HalfSize.Z) * 0.1)
	local LocalPointVector3 = ClampPartInstance.CFrame:PointToObjectSpace(TargetPointVector3)
	local ClampedLocalVector3 = Vector3.new(
		math.clamp(LocalPointVector3.X, -HalfSize.X + Inset, HalfSize.X - Inset),
		math.clamp(LocalPointVector3.Y, -HalfSize.Y + Inset, HalfSize.Y - Inset),
		math.clamp(LocalPointVector3.Z, -HalfSize.Z + Inset, HalfSize.Z - Inset)
	)
	return ClampPartInstance.CFrame:PointToWorldSpace(ClampedLocalVector3)
end

function ShieldModeRuntimeTable.ResolveEffectiveTargetGeometryForPart(PartInstance, CharacterModel, MouseLocationVector2)
	local TargetPointVector3 = PartInstance.Position
	local CubeCFrame = PartInstance.CFrame
	local CubeSize = PartInstance.Size
	local EffectivePartInstance = PartInstance

	if not IsEffectiveVisibleCheckEnabled() then
		return TargetPointVector3, CubeCFrame, CubeSize, EffectivePartInstance
	end

	local CachedVisibleTargetData = FrameVisiblePointCacheTable[PartInstance]
	local VisibleTargetData = CachedVisibleTargetData
	if CachedVisibleTargetData == nil then
		VisibleTargetData = GetVisiblePointForPart(PartInstance, CharacterModel, MouseLocationVector2)
		FrameVisiblePointCacheTable[PartInstance] = VisibleTargetData or false
	elseif CachedVisibleTargetData == false then
		VisibleTargetData = nil
	end
	if not VisibleTargetData then
		return ShieldModeRuntimeTable.RejectTargetDataForPart(
			"visible",
			"reject-visible",
			CharacterModel,
			PartInstance,
			"visible check found no visible point"
		)
	end

	TargetPointVector3 = VisibleTargetData.point
	CubeCFrame = VisibleTargetData.cubeCFrame
	CubeSize = VisibleTargetData.cubeSize
	if VisibleTargetData.part and VisibleTargetData.part.Parent then
		EffectivePartInstance = VisibleTargetData.part
	end

	return TargetPointVector3, CubeCFrame, CubeSize, EffectivePartInstance
end

function ShieldModeRuntimeTable.BuildTargetDataForResolvedPoint(PartInstance, EffectivePartInstance, CharacterModel, MouseLocationVector2, IgnoreOffscreenBoolean, IgnoreFovForThisTargetBoolean, WorldDistanceNumber, TargetPointVector3, CubeCFrame, CubeSize)
	TargetPointVector3 = ShieldModeRuntimeTable.ClampPointToPart(TargetPointVector3, EffectivePartInstance)
	local LocalTargetPointVector3 = EffectivePartInstance.CFrame:PointToObjectSpace(TargetPointVector3)
	local ScreenPositionVector3, OnScreenBoolean = Camera.WorldToViewportPoint(Camera, TargetPointVector3)
	if not OnScreenBoolean and not IgnoreOffscreenBoolean then
		return ShieldModeRuntimeTable.RejectTargetDataForPart(
			"point_offscreen",
			"reject-point-offscreen",
			CharacterModel,
			PartInstance,
			"the final target point is off-screen"
		)
	end

	local ScreenPositionVector2 = nil
	local ScreenDistanceNumber = WorldDistanceNumber
	if OnScreenBoolean then
		ScreenPositionVector2 = Vector2.new(ScreenPositionVector3.X, ScreenPositionVector3.Y)
		ScreenDistanceNumber = (ScreenPositionVector2 - MouseLocationVector2).Magnitude
	end

	if not IgnoreFovForThisTargetBoolean and ScreenPositionVector2 and not IsPointInCircle(ScreenPositionVector2, MouseLocationVector2, FovCircle.Radius) then
		return ShieldModeRuntimeTable.RejectTargetDataForPart(
			"point_fov",
			"reject-point-fov",
			CharacterModel,
			PartInstance,
			"the final target point is outside the FOV circle"
		)
	end

	local SortDistanceNumber = ScreenDistanceNumber
	if IsSillyModeBehaviorActive() then
		local SortOriginVector3 = CurrentVisibilityOriginVector3 or Camera.CFrame.Position
		local SortReferencePartInstance = GetCharacterRootPart(CharacterModel) or PartInstance
		SortDistanceNumber = (SortReferencePartInstance.Position - SortOriginVector3).Magnitude
	end

	return {
		part = EffectivePartInstance,
		character = CharacterModel,
		point = TargetPointVector3,
		localPoint = LocalTargetPointVector3,
		cubeCFrame = CubeCFrame,
		cubeSize = CubeSize,
		screen = ScreenPositionVector2,
		screenDistance = ScreenDistanceNumber,
		sortDistance = SortDistanceNumber,
	}
end

function ShieldModeRuntimeTable.ComputeTargetDataForPart(PartInstance, CharacterModel, MouseLocationVector2, IgnoreFovBoolean)
	if not IsCharacterAlive(CharacterModel) then
		return ShieldModeRuntimeTable.RejectTargetDataForPart("dead", "reject-dead", CharacterModel, PartInstance, "the character is not alive")
	end

	local WorldDistanceNumber = (PartInstance.Position - Camera.CFrame.Position).Magnitude
	if WorldDistanceNumber > MaxDistanceNumber then
		return ShieldModeRuntimeTable.RejectTargetDataForPart(
			"distance",
			"reject-distance",
			CharacterModel,
			PartInstance,
			"distance " .. string.format("%.1f", WorldDistanceNumber) .. " is over max " .. tostring(MaxDistanceNumber)
		)
	end

	local IgnoreOffscreenBoolean = ShouldIgnoreOffscreenChecks()
	local IgnoreFovForThisTargetBoolean = ShouldIgnoreFovChecks(IgnoreFovBoolean)
	local ScreenPositionVector3, OnScreenBoolean = Camera.WorldToViewportPoint(Camera, PartInstance.Position)
	local ScreenDistanceNumber = WorldDistanceNumber

	if not OnScreenBoolean and not IgnoreOffscreenBoolean then
		return ShieldModeRuntimeTable.RejectTargetDataForPart("offscreen", "reject-offscreen", CharacterModel, PartInstance, "the part is off-screen")
	end

	if OnScreenBoolean then
		local ScreenPositionVector2 = Vector2.new(ScreenPositionVector3.X, ScreenPositionVector3.Y)
		ScreenDistanceNumber = (ScreenPositionVector2 - MouseLocationVector2).Magnitude
		if not IgnoreFovForThisTargetBoolean and ScreenDistanceNumber > FovCircle.Radius then
			return ShieldModeRuntimeTable.RejectTargetDataForPart(
				"fov",
				"reject-fov",
				CharacterModel,
				PartInstance,
				"screen distance " .. string.format("%.1f", ScreenDistanceNumber) .. " is outside FOV " .. tostring(FovCircle.Radius)
			)
		end
	end

	local TargetPointVector3, CubeCFrame, CubeSize, EffectivePartInstance = ShieldModeRuntimeTable.ResolveEffectiveTargetGeometryForPart(
		PartInstance,
		CharacterModel,
		MouseLocationVector2
	)
	if not TargetPointVector3 then
		return nil
	end

	return ShieldModeRuntimeTable.BuildTargetDataForResolvedPoint(
		PartInstance,
		EffectivePartInstance,
		CharacterModel,
		MouseLocationVector2,
		IgnoreOffscreenBoolean,
		IgnoreFovForThisTargetBoolean,
		WorldDistanceNumber,
		TargetPointVector3,
		CubeCFrame,
		CubeSize
	)
end

function ShieldModeRuntimeTable.GetTargetDataForPart(PartInstance, CharacterModel, MouseLocationVector2, IgnoreFovBoolean)
	if not PartInstance then
		return nil
	end

	local CacheTable = IgnoreFovBoolean and FrameTargetDataCacheTable.ignoreFov or FrameTargetDataCacheTable.normal
	local CachedValue = CacheTable[PartInstance]
	if CachedValue ~= nil then
		return CachedValue or nil
	end

	local TargetData = ShieldModeRuntimeTable.ComputeTargetDataForPart(PartInstance, CharacterModel, MouseLocationVector2, IgnoreFovBoolean)
	CacheTable[PartInstance] = TargetData or false
	return TargetData
end

function ShieldModeRuntimeTable.GetBestTargetForCharacter(CharacterModel, MouseLocationVector2)
	local ClosestDistanceNumber = math.huge
	local ClosestTargetData = nil

	local ClosestHeadDistanceNumber = math.huge
	local ClosestHeadTargetData = nil

	for _, PartInstance in ipairs(GetTargetableParts(CharacterModel)) do
		local TargetData = ShieldModeRuntimeTable.GetTargetDataForPart(PartInstance, CharacterModel, MouseLocationVector2)
		if not TargetData then
			continue
		end

		local IsHeadBoolean = IsHeadLikeTargetPart(PartInstance)
		local TargetSortDistanceNumber = GetTargetSortDistance(TargetData)
		if IsHeadBoolean and TargetSortDistanceNumber < ClosestHeadDistanceNumber then
			ClosestHeadDistanceNumber = TargetSortDistanceNumber
			ClosestHeadTargetData = TargetData
		end

		if TargetSortDistanceNumber < ClosestDistanceNumber then
			ClosestDistanceNumber = TargetSortDistanceNumber
			ClosestTargetData = TargetData
		end
	end

	if IsEffectiveHeadshotPriorityEnabled() and ClosestHeadTargetData then
		return ClosestHeadTargetData
	end

	return ClosestTargetData
end

function ShieldModeRuntimeTable.CreateTargetSelectionSlot()
	return {
		distance = math.huge,
	}
end

function ShieldModeRuntimeTable.UpdateTargetSelectionSlot(SelectionSlotTable, TargetData, PlayerObject, DistanceNumber)
	if not SelectionSlotTable or not TargetData or DistanceNumber >= SelectionSlotTable.distance then
		return
	end

	SelectionSlotTable.distance = DistanceNumber
	SelectionSlotTable.screen = TargetData.screen
	SelectionSlotTable.part = TargetData.part
	SelectionSlotTable.character = TargetData.character
	SelectionSlotTable.player = PlayerObject
	SelectionSlotTable.point = TargetData.point
	SelectionSlotTable.localPoint = TargetData.localPoint
	SelectionSlotTable.cubeCFrame = TargetData.cubeCFrame
	SelectionSlotTable.cubeSize = TargetData.cubeSize
end

function ShieldModeRuntimeTable.ReadTargetSelectionSlot(SelectionSlotTable, IsAimingThreatBoolean)
	if not SelectionSlotTable or not SelectionSlotTable.part then
		return nil
	end

	return {
		distance = SelectionSlotTable.distance,
		screen = SelectionSlotTable.screen,
		part = SelectionSlotTable.part,
		character = SelectionSlotTable.character,
		player = SelectionSlotTable.player,
		point = SelectionSlotTable.point,
		localPoint = SelectionSlotTable.localPoint,
		cubeCFrame = SelectionSlotTable.cubeCFrame,
		cubeSize = SelectionSlotTable.cubeSize,
		isAimingThreat = IsAimingThreatBoolean == true,
	}
end

function ShieldModeRuntimeTable.BuildFallbackIndicatorData(TargetData, PlayerObject)
	if not TargetData then
		return nil
	end

	return {
		distance = TargetData.screenDistance,
		screen = TargetData.screen,
		part = TargetData.part,
		character = TargetData.character,
		player = PlayerObject,
		point = TargetData.point,
		localPoint = TargetData.localPoint,
		cubeCFrame = TargetData.cubeCFrame,
		cubeSize = TargetData.cubeSize,
	}
end

function ShieldModeRuntimeTable.RunTargetSearch(LocalCharacterModel, MouseLocationVector2, TeamCheckEnabledBoolean, LocalTeamObject, ShowTargetLineBoolean)
	local SearchResultTable = {
		candidate = nil,
		fallbackIndicator = nil,
		liveCharacterCount = 0,
		totalTargetablePartCount = 0,
		preferredAimingThreatCharacter = nil,
		preferredAimingThreatScore = nil,
	}

	local ClosestSelectionSlotTable = ShieldModeRuntimeTable.CreateTargetSelectionSlot()
	local ClosestHeadSelectionSlotTable = ShieldModeRuntimeTable.CreateTargetSelectionSlot()
	local ClosestPrioritySelectionSlotTable = ShieldModeRuntimeTable.CreateTargetSelectionSlot()
	local ClosestPriorityHeadSelectionSlotTable = ShieldModeRuntimeTable.CreateTargetSelectionSlot()
	local ClosestAimingThreatSelectionSlotTable = ShieldModeRuntimeTable.CreateTargetSelectionSlot()
	local ClosestAimingThreatHeadSelectionSlotTable = ShieldModeRuntimeTable.CreateTargetSelectionSlot()

	if IsSillyModeBehaviorActive() and ShieldModeRuntimeTable.ResolveAimingThreatData then
		local PreferredAimingThreatData = ShieldModeRuntimeTable.ResolveAimingThreatData(LocalCharacterModel)
		if PreferredAimingThreatData and PreferredAimingThreatData.character then
			SearchResultTable.preferredAimingThreatCharacter = PreferredAimingThreatData.character
			SearchResultTable.preferredAimingThreatScore = PreferredAimingThreatData.score
		end
	end

	local CharacterEntries = GetSearchableCharacterEntries(LocalCharacterModel, TeamCheckEnabledBoolean, LocalTeamObject)
	for _, CharacterEntry in ipairs(CharacterEntries) do
		local PlayerObject = CharacterEntry.player
		local CharacterModel = CharacterEntry.character
		if not IsCharacterAlive(CharacterModel) then
			continue
		end
		SearchResultTable.liveCharacterCount = SearchResultTable.liveCharacterCount + 1

		local TargetableParts = GetTargetableParts(CharacterModel)
		SearchResultTable.totalTargetablePartCount = SearchResultTable.totalTargetablePartCount + #TargetableParts
		if #TargetableParts == 0 then
			if DebugModeEnabledBoolean then
				DebugLog("no-parts-" .. CharacterModel.Name, "Found no targetable parts for " .. CharacterModel.Name, false)
			end
		end

		for _, PartInstance in ipairs(TargetableParts) do
			local TargetData = ShieldModeRuntimeTable.GetTargetDataForPart(PartInstance, CharacterModel, MouseLocationVector2)
			local FallbackTargetData = nil
			if not TargetData and ShowTargetLineBoolean then
				FallbackTargetData = ShieldModeRuntimeTable.GetTargetDataForPart(PartInstance, CharacterModel, MouseLocationVector2, true)
			end

			if FallbackTargetData then
				local FallbackDistanceNumber = FallbackTargetData.screenDistance or math.huge
				local CurrentFallbackDistanceNumber = SearchResultTable.fallbackIndicator and SearchResultTable.fallbackIndicator.distance or math.huge
				if FallbackDistanceNumber < CurrentFallbackDistanceNumber then
					SearchResultTable.fallbackIndicator = ShieldModeRuntimeTable.BuildFallbackIndicatorData(FallbackTargetData, PlayerObject)
				end
			end

			if not TargetData then
				continue
			end

			local IsHeadBoolean = IsHeadLikeTargetPart(PartInstance)
			local TargetSortDistanceNumber = GetTargetSortDistance(TargetData)
			local PriorityPlayerBoolean = PlayerListRuntimeTable.IsPriorityPlayer(PlayerObject)
			local AimingThreatCharacterBoolean = SearchResultTable.preferredAimingThreatCharacter ~= nil
				and CharacterModel == SearchResultTable.preferredAimingThreatCharacter

			if AimingThreatCharacterBoolean then
				if IsHeadBoolean then
					ShieldModeRuntimeTable.UpdateTargetSelectionSlot(ClosestAimingThreatHeadSelectionSlotTable, TargetData, PlayerObject, TargetSortDistanceNumber)
				else
					ShieldModeRuntimeTable.UpdateTargetSelectionSlot(ClosestAimingThreatSelectionSlotTable, TargetData, PlayerObject, TargetSortDistanceNumber)
				end
			end

			if IsHeadBoolean then
				if PriorityPlayerBoolean then
					ShieldModeRuntimeTable.UpdateTargetSelectionSlot(ClosestPriorityHeadSelectionSlotTable, TargetData, PlayerObject, TargetSortDistanceNumber)
				else
					ShieldModeRuntimeTable.UpdateTargetSelectionSlot(ClosestHeadSelectionSlotTable, TargetData, PlayerObject, TargetSortDistanceNumber)
				end
			end

			if PriorityPlayerBoolean then
				ShieldModeRuntimeTable.UpdateTargetSelectionSlot(ClosestPrioritySelectionSlotTable, TargetData, PlayerObject, TargetSortDistanceNumber)
			else
				ShieldModeRuntimeTable.UpdateTargetSelectionSlot(ClosestSelectionSlotTable, TargetData, PlayerObject, TargetSortDistanceNumber)
			end
		end
	end

	if not IsSillyModeBehaviorActive() then
		if IsEffectiveHeadshotPriorityEnabled() then
			SearchResultTable.candidate = ShieldModeRuntimeTable.ReadTargetSelectionSlot(ClosestHeadSelectionSlotTable, false)
		end
		if not SearchResultTable.candidate then
			SearchResultTable.candidate = ShieldModeRuntimeTable.ReadTargetSelectionSlot(ClosestSelectionSlotTable, false)
		end
		return SearchResultTable
	end

	if IsEffectiveHeadshotPriorityEnabled() then
		SearchResultTable.candidate = ShieldModeRuntimeTable.ReadTargetSelectionSlot(ClosestAimingThreatHeadSelectionSlotTable, true)
	end
	if not SearchResultTable.candidate then
		SearchResultTable.candidate = ShieldModeRuntimeTable.ReadTargetSelectionSlot(ClosestAimingThreatSelectionSlotTable, true)
	end
	if not SearchResultTable.candidate and IsEffectiveHeadshotPriorityEnabled() then
		SearchResultTable.candidate = ShieldModeRuntimeTable.ReadTargetSelectionSlot(ClosestPriorityHeadSelectionSlotTable, false)
	end
	if not SearchResultTable.candidate then
		SearchResultTable.candidate = ShieldModeRuntimeTable.ReadTargetSelectionSlot(ClosestPrioritySelectionSlotTable, false)
	end
	if not SearchResultTable.candidate and IsEffectiveHeadshotPriorityEnabled() then
		SearchResultTable.candidate = ShieldModeRuntimeTable.ReadTargetSelectionSlot(ClosestHeadSelectionSlotTable, false)
	end
	if not SearchResultTable.candidate then
		SearchResultTable.candidate = ShieldModeRuntimeTable.ReadTargetSelectionSlot(ClosestSelectionSlotTable, false)
	end

	return SearchResultTable
end

function ShieldModeRuntimeTable.IsLockKeyHeld()
	if IsSillyModeBehaviorActive() then
		return true
	end

	local LockKeyModeString = GetCurrentLockKeyMode()
	if LockKeyModeString == "Always" then
		return true
	elseif LockKeyModeString == "E" then
		return UserInputService.IsKeyDown(UserInputService, Enum.KeyCode.E)
	else
		return UserInputService.IsMouseButtonPressed(UserInputService, Enum.UserInputType.MouseButton2)
	end
end

function ShieldModeRuntimeTable.ShouldRedirectTowardCurrentTarget(LocalCharacterModel)
	if not LocalCharacterModel
		or not IsLocalCharacterReadyForAimbot(LocalCharacterModel)
		or not CurrentTargetPartInstance
		or not CurrentTargetCharacterModel
		or not CurrentTargetPartInstance.Parent
		or not IsCharacterAlive(CurrentTargetCharacterModel) then
		return false
	end

	if AimbotRequireRmbBoolean and not ShieldModeRuntimeTable.IsLockKeyHeld() then
		return false
	end

	return true
end

function ShieldModeRuntimeTable.IsHookOnlyMethodEnabled()
	return IsEffectiveHookMethodEnabled() and not IsEffectiveCameraMethodEnabled()
end

function ShieldModeRuntimeTable.GetFireGunMuzzleRedirect(ActiveFiringLocalGunTable, TargetPositionVector3, FallbackOriginVector3, DirectionMagnitudeNumber)
	if type(ActiveFiringLocalGunTable) ~= "table"
		or typeof(TargetPositionVector3) ~= "Vector3"
		or typeof(FallbackOriginVector3) ~= "Vector3"
		or type(DirectionMagnitudeNumber) ~= "number"
		or DirectionMagnitudeNumber <= 0.001 then
		return nil, nil
	end

	local MuzzleOriginVector3 = GetLocalGunTipWorldPosition(ActiveFiringLocalGunTable) or FallbackOriginVector3
	local RedirectDirectionVector3 = TargetPositionVector3 - MuzzleOriginVector3
	if RedirectDirectionVector3.Magnitude <= 0.001 then
		return nil, nil
	end

	local WeaponBallisticsProfileTable = CurrentWeaponBallisticsProfileTable
		or ShieldModeRuntimeTable.ResolveCurrentWeaponBallisticsProfile(ActiveFiringLocalGunTable.CharacterModel)
	local RedirectDistanceNumber = ShieldModeRuntimeTable.GetShotgunRedirectDistance
		and ShieldModeRuntimeTable.GetShotgunRedirectDistance(
			WeaponBallisticsProfileTable,
			MuzzleOriginVector3,
			TargetPositionVector3,
			DirectionMagnitudeNumber
		)
		or DirectionMagnitudeNumber
	return MuzzleOriginVector3, RedirectDirectionVector3.Unit * RedirectDistanceNumber
end

function ShieldModeRuntimeTable.ShouldSkipBloodZoneProjectileRaycastRedirect(LocalCharacterModel, RaycastParamsObject)
	if not IsBloodZonePlaceBoolean or not RaycastParamsObject then
		return false
	end

	local WeaponBallisticsProfileTable = CurrentWeaponBallisticsProfileTable
		or ShieldModeRuntimeTable.ResolveCurrentWeaponBallisticsProfile(LocalCharacterModel)
	if not ShieldModeRuntimeTable.IsProjectileWeaponProfile(WeaponBallisticsProfileTable) then
		return false
	end

	local ActiveLocalGunTable = WeaponBallisticsProfileTable and WeaponBallisticsProfileTable.localGun or nil
	if type(ActiveLocalGunTable) ~= "table" then
		ActiveLocalGunTable = ShieldModeRuntimeTable.ResolveCurrentLocalGun(LocalCharacterModel)
	end

	local ProjectileRaycastParamsObject = ActiveLocalGunTable and ActiveLocalGunTable.RayParams or nil
	return ProjectileRaycastParamsObject ~= nil and RaycastParamsObject == ProjectileRaycastParamsObject
end


function ClearMutableTable(TableObject)
	if type(TableObject) ~= "table" then
		return {}
	end

	if type(table.clear) == "function" then
		table.clear(TableObject)
	else
		for Key in pairs(TableObject) do
			TableObject[Key] = nil
		end
	end

	return TableObject
end

ShieldModeRuntimeTable.oldNamecall = hookmetamethod(game, "__namecall", function(Self, ...)
	local Method = getnamecallmethod()
	local IsWorkspaceRaycastMethodBoolean = Method == "Raycast" and Self == WorkspaceService
	local IsLegacyRayMethodBoolean = Method == "FindPartOnRayWithIgnoreList" or Method == "FindPartOnRay"
	if InternalAimbotRaycastBypassDepth > 0
		and (IsWorkspaceRaycastMethodBoolean or IsLegacyRayMethodBoolean) then
		return ShieldModeRuntimeTable.oldNamecall(Self, ...)
	end

	if not IsWorkspaceRaycastMethodBoolean and not IsLegacyRayMethodBoolean then
		return ShieldModeRuntimeTable.oldNamecall(Self, ...)
	end

	if not IsEffectiveHookMethodEnabled()
		or not CurrentTargetPartInstance
		or not CurrentTargetCharacterModel
		or not CurrentTargetPartInstance.Parent then
		return ShieldModeRuntimeTable.oldNamecall(Self, ...)
	end

	local LocalCharacterModel = CurrentFrameLocalCharacterModel
	local LocalCharacterReadyBoolean = CurrentFrameLocalCharacterReadyBoolean
	if not LocalCharacterReadyBoolean or not LocalCharacterModel or not LocalCharacterModel.Parent then
		LocalCharacterModel = ResolveCharacterModelForPlayer(LocalPlayer)
		LocalCharacterReadyBoolean = IsLocalCharacterReadyForAimbot(LocalCharacterModel)
		if not LocalCharacterReadyBoolean then
			return ShieldModeRuntimeTable.oldNamecall(Self, ...)
		end
	end

	local ShouldRedirect = true
	if AimbotRequireRmbBoolean then
		ShouldRedirect = ShieldModeRuntimeTable.IsLockKeyHeld()
	end
	if ShouldRedirect then
		ShouldRedirect = ShouldApplyNormalHookHitChance()
	end
	if not ShouldRedirect then
		return ShieldModeRuntimeTable.oldNamecall(Self, ...)
	end

	local Args = { ... }
	if IsWorkspaceRaycastMethodBoolean then
		local Origin = Args[1]
		local Direction = Args[2]
		local RaycastParamsObject = Args[3]

		if typeof(Origin) == "Vector3"
			and typeof(Direction) == "Vector3"
			and Direction.Magnitude > 0.001 then
			local TargetPosition = GetCurrentEffectiveAimPointVector3() or CurrentTargetPartInstance.Position
			local ActiveFiringLocalGunTable = ShieldModeRuntimeTable.activeFiringLocalGun
			if IsBloodZonePlaceBoolean
				and type(ActiveFiringLocalGunTable) == "table"
				and RaycastParamsObject == ActiveFiringLocalGunTable.CheckParams then
				local RedirectOriginVector3, RedirectDirectionVector3 = ShieldModeRuntimeTable.GetFireGunMuzzleRedirect(
					ActiveFiringLocalGunTable,
					TargetPosition,
					Origin,
					Direction.Magnitude
				)
				if RedirectOriginVector3 and RedirectDirectionVector3 then
					Args[1] = RedirectOriginVector3
					Args[2] = RedirectDirectionVector3
				end
			elseif ShieldModeRuntimeTable.ShouldSkipBloodZoneProjectileRaycastRedirect(LocalCharacterModel, RaycastParamsObject) then
				return ShieldModeRuntimeTable.oldNamecall(Self, ...)
			else
				local RedirectDistanceNumber = Direction.Magnitude
				if IsBloodZonePlaceBoolean and ShieldModeRuntimeTable.GetShotgunRedirectDistance then
					local WeaponBallisticsProfileTable = CurrentWeaponBallisticsProfileTable
						or ShieldModeRuntimeTable.ResolveCurrentWeaponBallisticsProfile(LocalCharacterModel)
					RedirectDistanceNumber = ShieldModeRuntimeTable.GetShotgunRedirectDistance(
						WeaponBallisticsProfileTable,
						Origin,
						TargetPosition,
						Direction.Magnitude
					)
				end
				Args[2] = (TargetPosition - Origin).Unit * RedirectDistanceNumber
			end
		end

		return ShieldModeRuntimeTable.oldNamecall(Self, unpack(Args))
	end

	local RayObject = Args[1]
	if RayObject then
		local TargetPosition = GetCurrentEffectiveAimPointVector3() or CurrentTargetPartInstance.Position
		local RedirectDistanceNumber = RayObject.Direction.Magnitude
		if IsBloodZonePlaceBoolean and ShieldModeRuntimeTable.GetShotgunRedirectDistance then
			local WeaponBallisticsProfileTable = CurrentWeaponBallisticsProfileTable
				or ShieldModeRuntimeTable.ResolveCurrentWeaponBallisticsProfile(LocalCharacterModel)
			RedirectDistanceNumber = ShieldModeRuntimeTable.GetShotgunRedirectDistance(
				WeaponBallisticsProfileTable,
				RayObject.Origin,
				TargetPosition,
				RayObject.Direction.Magnitude
			)
		end
		local NewDirection = (TargetPosition - RayObject.Origin).Unit * RedirectDistanceNumber
		Args[1] = Ray.new(RayObject.Origin, NewDirection)
	end

	return ShieldModeRuntimeTable.oldNamecall(Self, unpack(Args))
end)

RunService.RenderStepped.Connect(RunService.RenderStepped, function()
	CurrentFrameSequenceNumber = (tonumber(CurrentFrameSequenceNumber) or 0) + 1
	local FrameNowNumber = tick()
	local MouseLocationVector2 = UserInputService.GetMouseLocation(UserInputService)
	local MouseOverPartInstance = MouseObject.Target
	FrameTargetDataCacheTable.normal = ClearMutableTable(FrameTargetDataCacheTable.normal)
	FrameTargetDataCacheTable.ignoreFov = ClearMutableTable(FrameTargetDataCacheTable.ignoreFov)
	FrameVisiblePointCacheTable = ClearMutableTable(FrameVisiblePointCacheTable)
	FrameCharacterAliveCacheTable = ClearMutableTable(FrameCharacterAliveCacheTable)
	FrameCharacterVelocityCacheTable = ClearMutableTable(FrameCharacterVelocityCacheTable)
	CurrentWeaponBallisticsProfileTable = nil
	CurrentFrameLocalCharacterModel = nil
	CurrentFrameLocalCharacterReadyBoolean = false
	ShieldModeRuntimeTable.shotSkyAimDataCache = nil
	FovCircle.Position = MouseLocationVector2
	if not UseHookMethodBoolean or IsSillyModeBehaviorActive() or not CurrentTargetPartInstance then
		ResetNormalHookHitChanceDecision()
	end
	if CurrentTargetPartInstance and (not CurrentTargetPartInstance.Parent or not IsCharacterAlive(CurrentTargetCharacterModel)) then
		CurrentTargetPartInstance = nil
		CurrentTargetCharacterModel = nil
		CurrentTargetPlayerObject = nil
		CurrentTargetPointVector3 = nil
		CurrentTargetAimPointVector3 = nil
		CurrentTargetLocalPointVector3 = nil
		CurrentTargetCubeCFrame = nil
		CurrentTargetCubeSize = nil
	end

	local LocalCharacterModel = ResolveCharacterModelForPlayer(LocalPlayer)
	if LocalCharacterModel ~= LastRaycastCharacterModel then
		if LocalCharacterModel then
			VisibilityRaycastParams.FilterDescendantsInstances = { LocalCharacterModel }
		else
			VisibilityRaycastParams.FilterDescendantsInstances = {}
		end
		LastRaycastCharacterModel = LocalCharacterModel
	end

	local LocalCharacterReadyBoolean = IsLocalCharacterReadyForAimbot(LocalCharacterModel)
	CurrentFrameLocalCharacterModel = LocalCharacterModel
	CurrentFrameLocalCharacterReadyBoolean = LocalCharacterReadyBoolean
	if UseProjectilePredictionBoolean and LocalCharacterReadyBoolean then
		CurrentWeaponBallisticsProfileTable = ShieldModeRuntimeTable.ResolveCurrentWeaponBallisticsProfile(LocalCharacterModel)
	else
		CurrentWeaponBallisticsProfileTable = nil
	end
	local ShouldActivateSillyModeBoolean = IsBloodZonePlaceBoolean
		and IsSillyModeEnabled()
		and LocalCharacterReadyBoolean
		and HasEquippedTool(LocalCharacterModel)
	local PlayerListRefreshIntervalNumber = LocalCharacterReadyBoolean and PlayerListRuntimeTable.refreshInterval or PlayerListMenuRefreshIntervalNumber
	if (FrameNowNumber - PlayerListRuntimeTable.lastRefreshTime) >= PlayerListRefreshIntervalNumber then
		PlayerListRuntimeTable.RefreshUi(false)
	end
	if IsBloodZonePlaceBoolean then
		if LocalCharacterReadyBoolean then
			ShieldModeRuntimeTable.EnsureLocalGunHooks()
			ShieldModeRuntimeTable.EnsureCursorHooks()
		end

		if SillyModeRuntimeActiveBoolean ~= ShouldActivateSillyModeBoolean then
			SillyModeRuntimeActiveBoolean = ShouldActivateSillyModeBoolean
			if SillyModeRuntimeActiveBoolean then
				ShieldModeRuntimeTable.EnsureLocalCharacterHooks()
			end
			RefreshBloodZoneBehaviorButtons()
		end

		if not IsEffectiveShieldModeEnabled() then
			ShieldModeRuntimeTable.ResetState()
		end
	end

	if not LocalCharacterReadyBoolean then
		if IsBloodZonePlaceBoolean then
			ShieldModeRuntimeTable.ResetState()
		end
		CurrentTargetPartInstance = nil
		CurrentTargetCharacterModel = nil
		CurrentTargetPlayerObject = nil
		CurrentTargetPointVector3 = nil
		CurrentTargetAimPointVector3 = nil
		CurrentTargetLocalPointVector3 = nil
		CurrentTargetCubeCFrame = nil
		CurrentTargetCubeSize = nil
		CurrentVisibilityOriginVector3 = nil
		LastFallbackIndicatorPartInstance = nil
		LastFallbackIndicatorCharacterModel = nil
		LastFallbackIndicatorPlayerObject = nil
		FovCircle.Visible = false
		TargetLine.Visible = false
		SetTargetCubeVisible(false)
		EspRuntimeTable:HideAll()
		return
	end

	FovCircle.Visible = ShowFovCircleBoolean and not IsSillyModeBehaviorActive()
	CurrentVisibilityOriginVector3 = GetCurrentGunVisibilityOrigin(LocalCharacterModel)
	if not CurrentVisibilityOriginVector3 then
		local VisibilityOriginPartInstance = GetCharacterHeadPart(LocalCharacterModel) or GetCharacterRootPart(LocalCharacterModel)
		if VisibilityOriginPartInstance then
			CurrentVisibilityOriginVector3 = VisibilityOriginPartInstance.Position
		else
			CurrentVisibilityOriginVector3 = Camera.CFrame.Position
		end
	end
	local TeamCheckEnabledBoolean = false
	local LocalTeamObject = nil

	if not IsCustomCharacterGameBoolean then
		if LocalPlayer.Team ~= nil then
			TeamCheckEnabledBoolean = true
			LocalTeamObject = LocalPlayer.Team
		end
	end

	local FinalTargetPartInstance = nil
	local FinalTargetCharacterModel = nil
	local FinalTargetPlayerObject = nil
	local FinalTargetScreenPositionVector2 = nil
	local FinalTargetPointVector3 = nil
	local FinalTargetLocalPointVector3 = nil
	local FinalTargetCubeCFrame = nil
	local FinalTargetCubeSize = nil
	local CurrentTargetValidBoolean = false
	local CurrentTargetDistanceNumber = nil
	local IndicatorScreenPositionVector2 = nil
	local IndicatorPointVector3 = nil
	local IndicatorCubeCFrame = nil
	local IndicatorCubeSize = nil
	local IndicatorPartInstance = nil
	local IndicatorCharacterModel = nil
	local ShouldSearchForNewTargetBoolean = true
	local TargetSearchResultTable = nil
	local CandidateData = nil
	local FallbackIndicatorData = nil

	if CurrentTargetPartInstance
		and CurrentTargetCharacterModel
		and CurrentTargetCharacterModel.Parent
		and not PlayerListRuntimeTable.IsPlayerWhitelisted(CurrentTargetPlayerObject) then
		if IsCharacterAlive(CurrentTargetCharacterModel) then
			local TargetData = ShieldModeRuntimeTable.GetTargetDataForPart(CurrentTargetPartInstance, CurrentTargetCharacterModel, MouseLocationVector2, false)
			if TargetData then
				CurrentTargetValidBoolean = true
				CurrentTargetDistanceNumber = GetTargetSortDistance(TargetData)
				local BestTargetData = ShieldModeRuntimeTable.GetBestTargetForCharacter(CurrentTargetCharacterModel, MouseLocationVector2)
				if BestTargetData and GetTargetSortDistance(BestTargetData) < (CurrentTargetDistanceNumber - RetargetMinImprovementNumber) then
					FinalTargetPartInstance = BestTargetData.part
					FinalTargetCharacterModel = BestTargetData.character
					FinalTargetPlayerObject = CurrentTargetPlayerObject
					FinalTargetScreenPositionVector2 = BestTargetData.screen
					FinalTargetPointVector3 = BestTargetData.point
					FinalTargetLocalPointVector3 = BestTargetData.localPoint
					FinalTargetCubeCFrame = BestTargetData.cubeCFrame
					FinalTargetCubeSize = BestTargetData.cubeSize
					IndicatorScreenPositionVector2 = BestTargetData.screen
					IndicatorPointVector3 = BestTargetData.point
					IndicatorCubeCFrame = BestTargetData.cubeCFrame
					IndicatorCubeSize = BestTargetData.cubeSize
					IndicatorPartInstance = BestTargetData.part
					IndicatorCharacterModel = BestTargetData.character
				else
					FinalTargetPartInstance = TargetData.part
					FinalTargetCharacterModel = TargetData.character
					FinalTargetPlayerObject = CurrentTargetPlayerObject
					FinalTargetScreenPositionVector2 = TargetData.screen
					FinalTargetPointVector3 = TargetData.point
					FinalTargetLocalPointVector3 = TargetData.localPoint
					FinalTargetCubeCFrame = TargetData.cubeCFrame
					FinalTargetCubeSize = TargetData.cubeSize
					IndicatorScreenPositionVector2 = TargetData.screen
					IndicatorPointVector3 = TargetData.point
					IndicatorCubeCFrame = TargetData.cubeCFrame
					IndicatorCubeSize = TargetData.cubeSize
					IndicatorPartInstance = TargetData.part
					IndicatorCharacterModel = TargetData.character
				end
			end
		end
	end

	local StickyAimHoldingBoolean = false
	if CurrentTargetValidBoolean and IsStickyAimActive() then
		StickyAimHoldingBoolean = not AimbotRequireRmbBoolean or ShieldModeRuntimeTable.IsLockKeyHeld()
	end
	if StickyAimHoldingBoolean then
		ShouldSearchForNewTargetBoolean = false
	end

	local NowNumber = tick()
	local AllowTargetSearchBoolean = ShouldSearchForNewTargetBoolean and (NowNumber - LastTargetSearchTimeNumber >= TargetSearchIntervalNumber)
	if AllowTargetSearchBoolean then
		LastTargetSearchTimeNumber = NowNumber
		ResetRejectCounts()
	end

	if AllowTargetSearchBoolean then
		TargetSearchResultTable = ShieldModeRuntimeTable.RunTargetSearch(LocalCharacterModel, MouseLocationVector2, TeamCheckEnabledBoolean, LocalTeamObject, ShowTargetLineBoolean)
		CandidateData = TargetSearchResultTable.candidate
		FallbackIndicatorData = TargetSearchResultTable.fallbackIndicator

		if CandidateData then
			local CandidateIdentityString = GetTargetIdentity(CandidateData.player, CandidateData.character, CandidateData.part)
			local CandidateThreatSuffixString = CandidateData.isAimingThreat and " threat" or ""
			UpdateDebugStatus("candidate=" .. CandidateIdentityString .. CandidateThreatSuffixString .. " dist=" .. string.format("%.1f", CandidateData.distance or -1))
			if DebugModeEnabledBoolean then
				DebugLog("candidate-found", "Found candidate " .. CandidateIdentityString .. " at target distance " .. string.format("%.1f", CandidateData.distance or -1) .. " | threat=" .. tostring(CandidateData.isAimingThreat) .. " | vis=" .. tostring(IsEffectiveVisibleCheckEnabled()), false)
			end
		else
			UpdateDebugStatus("no candidate | vis=" .. tostring(IsEffectiveVisibleCheckEnabled()) .. " line=" .. tostring(ShowTargetLineBoolean) .. " maxDist=" .. tostring(MaxDistanceNumber) .. " live=" .. tostring(TargetSearchResultTable.liveCharacterCount) .. " parts=" .. tostring(TargetSearchResultTable.totalTargetablePartCount))
			if DebugModeEnabledBoolean then
				DebugLog("candidate-missing", "Target search found no candidate. Mouse target=" .. SafeDebugName(MouseOverPartInstance) .. " | vis=" .. tostring(IsEffectiveVisibleCheckEnabled()) .. " | line=" .. tostring(ShowTargetLineBoolean) .. " | maxDist=" .. tostring(MaxDistanceNumber) .. " | live=" .. tostring(TargetSearchResultTable.liveCharacterCount) .. " | parts=" .. tostring(TargetSearchResultTable.totalTargetablePartCount) .. " | preferredThreat=" .. GetCharacterModelDebugName(TargetSearchResultTable.preferredAimingThreatCharacter) .. " | threatScore=" .. string.format("%.1f", TargetSearchResultTable.preferredAimingThreatScore or -1) .. " | rejects=" .. GetRejectCountsSummary(), false)
			end
		end

		if not CandidateData and FallbackIndicatorData and FallbackIndicatorData.part and FallbackIndicatorData.screen then
			local FallbackIdentityString = GetTargetIdentity(FallbackIndicatorData.player, FallbackIndicatorData.character, FallbackIndicatorData.part)
			if DebugModeEnabledBoolean then
				DebugLog("indicator-fallback", "Using off-FOV indicator fallback for " .. FallbackIdentityString .. " at screen distance " .. string.format("%.1f", FallbackIndicatorData.distance or -1), false)
			end
		end
	end

	if AllowTargetSearchBoolean then
		if FallbackIndicatorData and FallbackIndicatorData.part and FallbackIndicatorData.character then
			LastFallbackIndicatorPartInstance = FallbackIndicatorData.part
			LastFallbackIndicatorCharacterModel = FallbackIndicatorData.character
			LastFallbackIndicatorPlayerObject = FallbackIndicatorData.player
		elseif not CandidateData and not CurrentTargetValidBoolean then
			LastFallbackIndicatorPartInstance = nil
			LastFallbackIndicatorCharacterModel = nil
			LastFallbackIndicatorPlayerObject = nil
		end
	end

	if not FallbackIndicatorData and LastFallbackIndicatorPartInstance and LastFallbackIndicatorCharacterModel then
		if LastFallbackIndicatorPartInstance.Parent and IsCharacterAlive(LastFallbackIndicatorCharacterModel) then
			local PersistedFallbackTargetData = ShieldModeRuntimeTable.GetTargetDataForPart(LastFallbackIndicatorPartInstance, LastFallbackIndicatorCharacterModel, MouseLocationVector2, true)
			if PersistedFallbackTargetData then
				FallbackIndicatorData = ShieldModeRuntimeTable.BuildFallbackIndicatorData(PersistedFallbackTargetData, LastFallbackIndicatorPlayerObject)
			else
				LastFallbackIndicatorPartInstance = nil
				LastFallbackIndicatorCharacterModel = nil
				LastFallbackIndicatorPlayerObject = nil
			end
		else
			LastFallbackIndicatorPartInstance = nil
			LastFallbackIndicatorCharacterModel = nil
			LastFallbackIndicatorPlayerObject = nil
		end
	end

	if AllowTargetSearchBoolean then
		if not CurrentTargetValidBoolean and CandidateData then
			FinalTargetPartInstance = CandidateData.part
			FinalTargetCharacterModel = CandidateData.character
			FinalTargetPlayerObject = CandidateData.player
			FinalTargetScreenPositionVector2 = CandidateData.screen
			FinalTargetPointVector3 = CandidateData.point
			FinalTargetLocalPointVector3 = CandidateData.localPoint
			FinalTargetCubeCFrame = CandidateData.cubeCFrame
			FinalTargetCubeSize = CandidateData.cubeSize
		elseif CurrentTargetValidBoolean and CandidateData and CandidateData.distance then
			if not IsSillyModeBehaviorActive() then
				if CandidateData.distance < (CurrentTargetDistanceNumber - RetargetMinImprovementNumber) then
					FinalTargetPartInstance = CandidateData.part
					FinalTargetCharacterModel = CandidateData.character
					FinalTargetPlayerObject = CandidateData.player
					FinalTargetScreenPositionVector2 = CandidateData.screen
					FinalTargetPointVector3 = CandidateData.point
					FinalTargetLocalPointVector3 = CandidateData.localPoint
					FinalTargetCubeCFrame = CandidateData.cubeCFrame
					FinalTargetCubeSize = CandidateData.cubeSize
				end
			else
				local CandidatePriorityBoolean = PlayerListRuntimeTable.IsPriorityPlayer(CandidateData.player)
				local CurrentPriorityBoolean = PlayerListRuntimeTable.IsPriorityPlayer(CurrentTargetPlayerObject)
				local PreferredAimingThreatCharacterModel = TargetSearchResultTable and TargetSearchResultTable.preferredAimingThreatCharacter or nil
				local CurrentTargetIsAimingThreatBoolean = PreferredAimingThreatCharacterModel ~= nil
					and CurrentTargetCharacterModel == PreferredAimingThreatCharacterModel
				if CandidateData.isAimingThreat and not CurrentTargetIsAimingThreatBoolean then
					FinalTargetPartInstance = CandidateData.part
					FinalTargetCharacterModel = CandidateData.character
					FinalTargetPlayerObject = CandidateData.player
					FinalTargetScreenPositionVector2 = CandidateData.screen
					FinalTargetPointVector3 = CandidateData.point
					FinalTargetLocalPointVector3 = CandidateData.localPoint
					FinalTargetCubeCFrame = CandidateData.cubeCFrame
					FinalTargetCubeSize = CandidateData.cubeSize
				elseif CurrentTargetIsAimingThreatBoolean and not CandidateData.isAimingThreat then
				elseif CandidatePriorityBoolean and not CurrentPriorityBoolean then
					FinalTargetPartInstance = CandidateData.part
					FinalTargetCharacterModel = CandidateData.character
					FinalTargetPlayerObject = CandidateData.player
					FinalTargetScreenPositionVector2 = CandidateData.screen
					FinalTargetPointVector3 = CandidateData.point
					FinalTargetLocalPointVector3 = CandidateData.localPoint
					FinalTargetCubeCFrame = CandidateData.cubeCFrame
					FinalTargetCubeSize = CandidateData.cubeSize
				elseif not CurrentPriorityBoolean or CandidatePriorityBoolean then
					if CandidateData.distance < (CurrentTargetDistanceNumber - RetargetMinImprovementNumber) then
						FinalTargetPartInstance = CandidateData.part
						FinalTargetCharacterModel = CandidateData.character
						FinalTargetPlayerObject = CandidateData.player
						FinalTargetScreenPositionVector2 = CandidateData.screen
						FinalTargetPointVector3 = CandidateData.point
						FinalTargetLocalPointVector3 = CandidateData.localPoint
						FinalTargetCubeCFrame = CandidateData.cubeCFrame
						FinalTargetCubeSize = CandidateData.cubeSize
					end
				end
			end
		end
	end

	if not CurrentTargetValidBoolean and not FinalTargetPartInstance then
		if DebugModeEnabledBoolean then
			DebugLog("target-cleared", "Clearing current target because no valid target or candidate exists", false)
		end
		ResetNormalHookHitChanceDecision()
		CurrentTargetPartInstance = nil
		CurrentTargetCharacterModel = nil
		CurrentTargetPlayerObject = nil
		CurrentTargetPointVector3 = nil
		CurrentTargetAimPointVector3 = nil
		CurrentTargetLocalPointVector3 = nil
		CurrentTargetCubeCFrame = nil
		CurrentTargetCubeSize = nil
	end

	if FinalTargetPartInstance and (FinalTargetScreenPositionVector2 or IsSillyModeBehaviorActive()) then
		local NewTargetPointVector3 = FinalTargetPointVector3 or FinalTargetPartInstance.Position
		local NewTargetAimPointVector3 = ResolveTargetAimPointVector3(
			LocalCharacterModel,
			FinalTargetCharacterModel,
			FinalTargetPartInstance,
			NewTargetPointVector3
		) or NewTargetPointVector3
		if CurrentTargetPartInstance ~= FinalTargetPartInstance
			or CurrentTargetPointVector3 ~= NewTargetPointVector3
			or CurrentTargetLocalPointVector3 ~= FinalTargetLocalPointVector3 then
			local FinalIdentityString = GetTargetIdentity(FinalTargetPlayerObject, FinalTargetCharacterModel, FinalTargetPartInstance)
			UpdateDebugStatus("locked=" .. FinalIdentityString)
			local LockedDistanceNumber = CandidateData and CandidateData.distance or CurrentTargetDistanceNumber or 0
			if FinalTargetScreenPositionVector2 then
				LockedDistanceNumber = (FinalTargetScreenPositionVector2 - MouseLocationVector2).Magnitude
			end
			if DebugModeEnabledBoolean then
				DebugLog("target-locked", "Locked target " .. FinalIdentityString .. " | target distance=" .. string.format("%.1f", LockedDistanceNumber), true)
			end
			ResetNormalHookHitChanceDecision()
			CurrentTargetPartInstance = FinalTargetPartInstance
			CurrentTargetCharacterModel = FinalTargetCharacterModel
			CurrentTargetPlayerObject = FinalTargetPlayerObject
			CurrentTargetPointVector3 = NewTargetPointVector3
			CurrentTargetLocalPointVector3 = FinalTargetLocalPointVector3
			CurrentTargetCubeCFrame = FinalTargetCubeCFrame
			CurrentTargetCubeSize = FinalTargetCubeSize
		end
		CurrentTargetAimPointVector3 = NewTargetAimPointVector3
	end

	if not IndicatorScreenPositionVector2 and CandidateData and CandidateData.screen and CandidateData.point then
		IndicatorScreenPositionVector2 = CandidateData.screen
		IndicatorPointVector3 = CandidateData.point
		IndicatorCubeCFrame = CandidateData.cubeCFrame
		IndicatorCubeSize = CandidateData.cubeSize
		IndicatorPartInstance = CandidateData.part
		IndicatorCharacterModel = CandidateData.character
	end

	if not IndicatorScreenPositionVector2 and FallbackIndicatorData and FallbackIndicatorData.screen and FallbackIndicatorData.point then
		IndicatorScreenPositionVector2 = FallbackIndicatorData.screen
		IndicatorPointVector3 = FallbackIndicatorData.point
		IndicatorCubeCFrame = FallbackIndicatorData.cubeCFrame
		IndicatorCubeSize = FallbackIndicatorData.cubeSize
		IndicatorPartInstance = FallbackIndicatorData.part
		IndicatorCharacterModel = FallbackIndicatorData.character
	end

	local HasValidIndicatorTargetBoolean = CurrentTargetPartInstance
		and CurrentTargetCharacterModel
		and CurrentTargetPartInstance.Parent
		and IndicatorCharacterModel == CurrentTargetCharacterModel
		and IsCharacterAlive(CurrentTargetCharacterModel)

	if HasValidIndicatorTargetBoolean and IndicatorScreenPositionVector2 and IndicatorPointVector3 and IndicatorPartInstance and ShowTargetLineBoolean then
		TargetLine.From = MouseLocationVector2
		TargetLine.To = IndicatorScreenPositionVector2
		TargetLine.Visible = true
		local IndicatorIdentityString = GetTargetIdentity(CurrentTargetPlayerObject, IndicatorCharacterModel, IndicatorPartInstance)
		UpdateDebugStatus("line draw=" .. IndicatorIdentityString)
		if DebugModeEnabledBoolean then
			DebugLog("line-drawing", "Drawing target line to " .. IndicatorIdentityString .. " at " .. tostring(IndicatorScreenPositionVector2), false)
		end
		local CubeCFrame = IndicatorCubeCFrame or IndicatorPartInstance.CFrame
		local CubeSize = IndicatorCubeSize or GetCubeSize(IndicatorPartInstance)
		UpdateTargetCube(CubeCFrame, CubeSize, IndicatorPointVector3)
	else
		TargetLine.Visible = false
		SetTargetCubeVisible(false)
		local HiddenReasonParts = {}
		if not HasValidIndicatorTargetBoolean then
			table.insert(HiddenReasonParts, "no valid target")
		end
		if not ShowTargetLineBoolean then
			table.insert(HiddenReasonParts, "toggle off")
		end
		if not IndicatorScreenPositionVector2 then
			table.insert(HiddenReasonParts, "no screen point")
		end
		if not IndicatorPointVector3 then
			table.insert(HiddenReasonParts, "no world point")
		end
		if not IndicatorPartInstance then
			table.insert(HiddenReasonParts, "no part")
		end
		local HiddenReasonString = table.concat(HiddenReasonParts, ", ")
		UpdateDebugStatus("line hidden=" .. HiddenReasonString)
		if DebugModeEnabledBoolean then
			DebugLog("line-hidden", "Target line hidden because " .. HiddenReasonString .. " | current=" .. SafeDebugName(CurrentTargetPartInstance) .. " | mouse target=" .. SafeDebugName(MouseOverPartInstance), false)
		end
	end

	EspRuntimeTable:Update(LocalCharacterModel, TeamCheckEnabledBoolean, LocalTeamObject)

	if CurrentTargetPartInstance and IsCharacterAlive(CurrentTargetCharacterModel) then
		local TargetPositionVector3 = GetCurrentEffectiveAimPointVector3()
			or GetCurrentTrackedTargetPointVector3()
			or CurrentTargetPartInstance.Position

		local ShouldAimbotBoolean = true
		if AimbotRequireRmbBoolean then
			ShouldAimbotBoolean = ShieldModeRuntimeTable.IsLockKeyHeld()
		end

		if ShouldAimbotBoolean and IsEffectiveCameraMethodEnabled() then
			local CameraPositionVector3 = Camera.CFrame.Position
			local DirectionVector3 = (TargetPositionVector3 - CameraPositionVector3).Unit
			local CurrentLookVector = Camera.CFrame.LookVector
			local SmoothedLookVector = CurrentLookVector:Lerp(DirectionVector3, AimbotSmoothingNumber)
			Camera.CFrame = CFrame.new(CameraPositionVector3, CameraPositionVector3 + SmoothedLookVector)
		end

		local ScopeAllowedBoolean = true
		if UseCustomScopeCheckBoolean then
			local PlayerGui = LocalPlayer.FindFirstChild(LocalPlayer, "PlayerGui")
			local MainUI = PlayerGui and PlayerGui.FindFirstChild(PlayerGui, "MainUI")
			local ScopeObject = MainUI and MainUI.FindFirstChild(MainUI, "Scope")
			ScopeAllowedBoolean = ScopeObject and ScopeObject.Visible or false
		end

		local AutoFireScopeAllowedBoolean = ScopeAllowedBoolean or ShieldModeRuntimeTable.IsHookOnlyMethodEnabled()

		local IsTypingBoolean = IsTypingInTextBox()
		local MouseOverAimbotUiBoolean = IsMouseOverAimbotUi(MouseLocationVector2)
		local ShouldAutoFireBoolean = IsEffectiveAutoFireEnabled()
			and not IsTypingBoolean
			and not MouseOverAimbotUiBoolean
			and ShouldAimbotBoolean
			and CurrentTargetCharacterModel
			and AutoFireScopeAllowedBoolean
		local ShouldAutoFireCurrentTargetBoolean = false
		if ShouldAutoFireBoolean then
			if ShieldModeRuntimeTable.IsHookOnlyMethodEnabled() then
				ShouldAutoFireCurrentTargetBoolean = true
			elseif MouseObject.Target and MouseObject.Target.IsDescendantOf(MouseObject.Target, CurrentTargetCharacterModel) then
				ShouldAutoFireCurrentTargetBoolean = true
			end
		end

		local ShieldModeUsableBoolean = false
		local ShieldModeShotContextTable = nil
		if IsBloodZonePlaceBoolean then
			ShieldModeUsableBoolean, ShieldModeShotContextTable = ShieldModeRuntimeTable.UpdateCombatState(LocalCharacterModel, ShouldAutoFireBoolean and ShouldAutoFireCurrentTargetBoolean)
		end
		if ShieldModeUsableBoolean then
			if ShieldModeShotContextTable then
				SendAimbotMouseClick(MouseLocationVector2)
				ShieldModeRuntimeTable.FinalizeShot(ShieldModeShotContextTable)
			end
		elseif ShouldAutoFireBoolean and ShouldAutoFireCurrentTargetBoolean then
			local NowNumber = tick()
			if NowNumber - LastAutoFireTimeNumber >= AutoFireCooldownNumber then
				LastAutoFireTimeNumber = NowNumber
				SendAimbotMouseClick(MouseLocationVector2)
			end
		end
	elseif IsBloodZonePlaceBoolean and IsEffectiveShieldModeEnabled() then
		ShieldModeRuntimeTable.UpdateCombatState(LocalCharacterModel, false)
	end
end)
