Scriptname pDBEntranceQuestScript extends Quest  Conditional

Quest Property WICourier  Auto
Book Property DBEntranceLetter  Auto
int Property pSleepyTime  Auto Conditional
ObjectReference Property pPlayerShackMarker  Auto
ReferenceAlias Property pAstridAlias  Auto
int Property pPlayerSecondSleep  Auto Conditional
Idle Property WakeUp Auto
ImageSpaceModifier Property Woozy Auto

; When stage is set to 30, register for sleep via RegisterForSleep()

Event OnSleepStart(float afSleepStartTime, float afDesiredSleepEndTime)
; SCRAB EDIT ----------------------
	Actor Player = Game.GetPlayer()
	; Location PlayerLoc = Player.GetCurrentLocation()
	; 1. Check Location
	; Debug.Trace("Location = " + PlayerLoc)
	; If(PlayerLoc)
	; 	Keyword LocTypeInn = Game.GetForm(0x1CB87) as Keyword
	; 	Keyword LocTypeCity = Game.GetForm(0x13168) as Keyword
	; 	Keyword LocTypeTown = Game.GetForm(0x13166) as Keyword
	; 	Keyword LocTypePlayerHouse = Game.GetForm(0xFC1A3) as Keyword
	; 	; Debug.Trace("LocTypeInn = " + LocTypeInn + "LocTypeCity = " + LocTypeCity + "LocTypeTown = " + LocTypeTown + "LocTypePlayerHouse = " + LocTypePlayerHouse)
	; 	If(PlayerLoc.HasKeyword(LocTypeInn) || PlayerLoc.HasKeyword(LocTypeCity) || PlayerLoc.HasKeyword(LocTypeTown) || PlayerLoc.HasKeyword(LocTypePlayerHouse))
	;			If IsTimeRestricted()
	;				; Debug.Trace("Sleeping in a filtered Location mid day")
	;				return
  ; 		EndIf
	; 	EndIf
	; EndIf
	; ; 2. Location
	; If(!InNearbyHold())
	; 	return
	;	EndIf
; JCONTAINER CODE -----------------
	int config = JValue.ReadFromFile("Data\\SKSE\\RDBK\\Settings.json")
	If(!config)
		Debug.MessageBox("-- Realistic Dark Brotherhood Kidnapping --\nYou use the Config Version but JContainers is not installed OR \"Settings.json\" is not present in \"Data\\SKSE\\RDBK\\\"\n\nKidnappings will be disabled until this issue is resolved.")
		return
	EndIf
	If(JMap.getInt(config, "RestrictHolds", 0) && !InNearbyHold())
		return
	ElseIf(IsProtected(config))
		return
	EndIf
	; TODO: Validation stuff
	If(Player.IsInInterior())
		int interior = JMAp.getObj(config, "Interior", 0)
		If(!interior || !JMap.getInt(interior, "Enabled", 0))
			return
		ElseIf(!InReqLoc(interior))
			return
		ElseIf(JMap.getInt(interior, "RestrictTime", 0) && IsTimeRestricted())
			return
		EndIf
	Else
		int exterior = JMap.GetObj(config, "Exterior", 0)
		If(!exterior || !JMap.getInt(exterior, "Enabled", 0))
			return
		ElseIf(!Player.GetCurrentLocation() && !JMap.getInt(exterior, "Wilderness", 0))
			return
		ElseIf(JMap.getInt(exterior, "RestrictTime", 0) && IsTimeRestricted())
			return
		EndIf
	EndIf
; SCRAB EDIT END ------------------

; For the player sleeping, to move him to the shack to be forcegreeted by Astrid.
If pSleepyTime == 1
		Game.DisablePlayerControls(ablooking = true, abCamSwitch = true)
	  Game.ForceFirstPerson()
		Game.GetPlayer().MoveTo(pPlayerShackMarker)
		Woozy.Apply()
		Game.GetPlayer().PlayIdle(WakeUp)

		; JCONTAINER CODE PART 2 ----------
		GlobalVariable GameHour = Game.GetForm(0x38) as GlobalVariable
		ObjectReference chest = Game.GetForm(0xCE2A7) as ObjectReference
		float skiptime = JMap.GetFlt(config, "SkipTime", 0)
		If(skiptime)
			GameHour.Value += skiptime
		EndIf
		If(JMap.getObj(config, "StealInventory", 0))
			Player.RemoveAllItems(chest, true)
		EndIf
		; SCRAB EDIT END ------------------

		Utility.Wait (3)
		pSleepyTime = 3
endif



;Tempted in for future, when sleeping is working
;If the player is sleeping
	;play the sleeping/wake up animation
	;in previous block, set pSleepyTime to 2, and use 2 in this block to have the player play the wakeup animnation, then set to 3 to have Astrid forcegreet
;endif

; For the player sleeping the second time, and being greeted by Astrid (commented out because it's no longer used)

;If pPlayerSecondSleep == 0
	;If pSleepyTime >= 5
			;pSleepyTime = 6
			;pAstridAlias.GetReference().Moveto (Game.GetPlayer(), afXOffset = 60.0)
			;pPlayerSecondSleep = 1
	;endif
;endif
EndEvent

bool Function IsTimeRestricted()
	float gametime = Utility.GetCurrentGameTime()
	float hour = gametime - (gametime as int)
	; Debug.Trace("GameTime = " + gametime + " hour = " + hour)
	return hour < 0.92 && hour > 0.21 ; 0.92 ~ 22.00 // 0.21 ~ 5.00
EndFunction

bool Function InNearbyHold()
	Location HjaalmachHold = Game.GetForm(0x1676E) as Location
	Location PaleHold = Game.GetForm(0x1676D) as Location
	Location HaafingarHold = Game.GetForm(0x16770) as Location
	; Debug.Trace("[RDBK] HjaalmachHold = " + HjaalmachHold + "PaleHold = " + PaleHold + "HaafingarHold = " + HaafingarHold)
	return HjaalmachHold.IsLoaded() || PaleHold.IsLoaded() || HaafingarHold.IsLoaded()
EndFunction

bool Function InReqLoc(int interior)
	Location pLoc = Game.GetPlayer().GetCurrentLocation()
	If(pLoc)
		int kw = JMap.getObj(interior, "RequireKeywords", 0)
		If(kw)
			String[] keywordIDs = JArray.asStringArray(kw)
			int i = 0
			While(i < keywordIDs.length)
				Keyword k = Keyword.GetKeyword(keywordIDs[i])
				If(k && pLoc.HasKeyword(k))
					return true
				EndIf
				i += 1
			EndWhile
			return false
		EndIf
	EndIf
	return true
EndFunction

bool Function IsProtected(int config)
	int protecc = JMap.getObj(config, "AbductionProtection", 0)
	If(!protecc)
		return false
	EndIf
	Faction MarryFac = Game.GetForm(0xC6472) as Faction
	Faction HousecarlFac = Game.GetForm(0x5091C) as Faction
	int pFol = JMap.getInt(protecc, "Followers")
	int pHousecarl = JMap.getInt(protecc, "Housecarl")
	int pSpouse = JMap.getInt(protecc, "Spouse")
	int pOther = JMap.getInt(protecc, "Other")
	Cell c = Game.GetPlayer().GetParentCell()
	int n = c.GetNumRefs(62)
	Debug.Trace("[RDBK] Found " + n + " Actors in Cell")
	While(n > 0)
		n -= 1
		Actor ref = c.GetNthRef(n, 62) as Actor
		Debug.Trace("Checking " + ref)
		If(pFol && ref.IsPlayerTeammate())
			return true
		ElseIf(pHousecarl && ref.IsInFaction(HousecarlFac))
			return true
		ElseIf(pSpouse && ref.IsInFaction(MarryFac))
			return true
		ElseIf(pOther)
			return true
		EndIf
	EndWhile
	return false
EndFunction

DarkBrotherhood Property DarkBrotherhoodQuest  Auto

ReferenceAlias Property Captive1Alias  Auto

ReferenceAlias Property Captive2Alias  Auto

ReferenceAlias Property Captive3Alias  Auto

int Property AstridSleepGreet  Auto Conditional

int Property AstridMove  Auto Conditional



;USKP 2.0.4 - Bug #15052: Take care of setting Aventus up to move to Riften.
Faction Property CrimeFactionEastmarch  Auto
Faction Property CrimeFactionRift  Auto
Faction Property WindhelmAretinoResidenceFaction  Auto
Faction Property TownRiftenFaction  Auto
Faction Property TownWindhelmFaction  Auto
Actor Property AventusAretinoREF  Auto
Actor Property AngrenorREF  Auto
ObjectReference Property HonorhallGrelodSceneMarker Auto

Function MoveAventusOut()
	;Fix up Aventus Aretino so that he will switch factions properly at the end of DB01.
	AventusAretinoREF.RemoveFromFaction(CrimeFactionEastmarch)
	AventusAretinoREF.RemoveFromFaction(TownWindhelmFaction)
	AventusAretinoREF.RemoveFromFaction(WindhelmAretinoResidenceFaction)
	AventusAretinoREF.AddToFaction(CrimeFactionRift)
	AventusAretinoREF.AddToFaction(TownRiftenFaction)
	AventusAretinoREF.SetCrimeFaction(CrimeFactionRift)
	AventusAretinoREF.MoveTo(HonorhallGrelodSceneMarker)

	;Fix Angrenor so that he switched ownership factions and moves into Aventus' old house.
	AngrenorREF.AddToFaction(WindhelmAretinoResidenceFaction)
EndFunction
