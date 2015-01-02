
require("helpers/Utility")
require("helpers/NodeUtility")

sceneMainMenu = director:createScene()
sceneMainMenu.name = "menu"

useQuitButton =  device:getInfo("platform") ~= "IPHONE"

local btnW = 500
local btnHScale = 0.4 

local adIds = {top=-1, bottom=-1, interstitial=-1}
local firstAdShow = {top=false, bottom=false}
local gotInterstitial = false

--------------------------------------------------------

function sceneMainMenu:setUp(event)
    
    system:addEventListener({"suspend", "resume", "update"}, self)
    virtualResolution:applyToScene(self)

    -- background
    self.background = director:createSprite(0, 0, "textures/sky.png")
    self.background.defaultScale = appHeight/self.background.h
    self.background.xScale = self.background.defaultScale
    self.background.yScale = self.background.defaultScale

    -- title
    self.mainMenu = director:createNode({x=appWidth/2,y=appHeight-170})
    local titleOutline = director:createLines({x=0, y=0,
            coords={-240,-50, -240,50, 240,50, 240,-50, -240,-50},
            strokeWidth=4, strokeColor=color.white, alpha=0})
    self.mainMenu:addChild(titleOutline)
    local titleText = director:createLabel({x=-214, y=-15, w=400, h=100,
            hAlignment="left", vAlignment="bottom", text="Amazon Mobile Ads: The Game!", color=color.white, xScale=1.2, yScale=1.2})
    self.mainMenu:addChild(titleText)
    
    self.mainMenu.adLabel = director:createLabel({x=20, y=150, w=appWidth-20, h=50,
            hAlignment="left", vAlignment="bottom", text="Ad IDs loaded:", color=color.black})
    
    self.mainMenu.adLoadLabel = director:createLabel({x=20, y=110, w=appWidth-20, h=50,
            hAlignment="left", vAlignment="bottom", text="Interstitial ad: not loaded", color=color.black})


    -- buttons
    self.btns = {}
    local btnY = -150
    sceneMainMenu:addButton("start", "Start Game", btnY, touchStart, 20)

    btnY = btnY - 100
    sceneMainMenu:addButton("topBanner", "show new top banner", btnY, touchTop, 20)

    btnY = btnY - 100
    sceneMainMenu:addButton("bottomBanner", "show new bottom banner", btnY, touchBottom, 20)
    
    btnY = btnY - 100
    sceneMainMenu:addButton("interstitial", "load new interstitial", btnY, touchInterstitial, 20)

    if useQuitButton then
        btnY = btnY - 100
        sceneMainMenu:addButton("quit", "Quit", btnY, touchQuit, 20)
    end

    enableMainMenu()
    
    if not adsRunning and amazonAds.isAvailable() then
        adsRunning = amazonAds.init("d61638a732ea4f459ea445797d546518", "5b1b1bf93f0644af9caaffc58fd467dc")
    end
    
    --load ads immediately for performance but dont show yet
    if adsRunning then
        firstAdShow = {top=false, bottom=false}
        self.prepareAd("top", false)
        self.prepareAd("bottom", false)
        
        system:addEventListener("amazonAds", adsListener)
        self.prepareAd("interstitial")
    else
        self.mainMenu.adLabel.text = "Ads not available"
    end
end

--adType here can be "top", "bottom" or "interstitial"
--interstitial ads can't be shown immediately
function sceneMainMenu.prepareAd(adType, show)
    if adIds[adType] ~= -1 then
        amazonAds.destroyAd(adIds[adType])
        adIds[adType] = -1
    end
        
    adIds[adType] = amazonAds.prepareAd()
    
    if adType == "interstitial" then
        gotInterstitial = false --reset
        amazonAds.loadInterstitialAd(adIds[adType])
        sceneMainMenu.mainMenu.adLoadLabel.text = "Interstitial ad: loading..."
    else
        amazonAds.prepareAdLayout(adIds[adType], adType, "auto")
        amazonAds.loadAd(adIds[adType], show)
    end
end

function sceneMainMenu:exitPreTransition(event)
    system:removeEventListener({"suspend", "resume", "update"}, self)
end

function sceneMainMenu:exitPostTransition(event)
    destroyNodesInTree(self, false)
    self.mainMenu = nil
    self.btns = nil
    self.background = nil

    self:releaseResources()
    collectgarbage("collect")
    director:cleanupTextures()
end

sceneMainMenu:addEventListener({"setUp", "exitPreTransition", "exitPostTransition"}, sceneMainMenu)


---- Button helpers -----------------------------------------------------------

function sceneMainMenu:addButton(name, text, btnY, touchListener, textX)
    self.btns[name] = director:createSprite({x=0, y=btnY, xAnchor=0.5, yAnchor=0.5, source="textures/bigwhitebutton.png"})

    local btnScale = btnW/self.btns.start.w
    local btnH = self.btns.start.h * btnScale * btnHScale

    self.btns[name].xScale = btnScale
    self.btns[name].yScale = btnScale * btnHScale
    self.btns[name].defaultScale = btnScale
    self.mainMenu:addChild(self.btns[name])
    self.btns[name].label = director:createLabel({x=textX, y=30, w=btnW, h=btnH, hAlignment="left", vAlignment="bottom", text=text, color=color.black, xScale=1.2, yScale=1.2/btnHScale})
    self.btns[name]:addChild(self.btns[name].label)

    self.btns[name].touch = touchListener
end

function enableMainMenu(target)
    for k,v in pairs(sceneMainMenu.btns) do
        v:addEventListener("touch", v)
    end
end

function disableMainMenu(target)
    for k,v in pairs(sceneMainMenu.btns) do
        v:removeEventListener("touch", v)
    end
end

function destroyAds()
    gotInterstitial = false
    for k,v in pairs(adIds) do
        if v ~= -1 then
            amazonAds.destroyAd(v)
        end
        adIds[k] = -1
    end
end

function startGame()
    destroyAds()
    director:moveToScene(sceneGame, {transitionType="slideInR", transitionTime=0.8})
end

---- Pause/resume logic/anims on app suspend/resume ---------------------------

function sceneMainMenu:suspend(event)
    if not pauseflag then
        system:pauseTimers()
        pauseNodesInTree(self)
        saveUserData()
    end
end

function sceneMainMenu:resume(event)
    pauseflag = true
end

function sceneMainMenu:update(event)
    if pauseflag then
        pauseflag = false
        system:resumeTimers()
        resumeNodesInTree(self)
    end
    
    self.mainMenu.adLabel.text = "Ad IDs loaded: top=" .. adIds.top .. " btm=" .. adIds.bottom .. " inter=" .. adIds.interstitial
end

---- Button handlers ----------------------------------------------------------

function touchStart(self, event)
    if event.phase == "ended" then
        disableMainMenu()
        
        local startNow = true
        
        if gotInterstitial then
            if amazonAds.showAd(adIds.interstitial) then
                startNow = false
            end
        end
        
        if startNow then
            startGame()
        end
    end
end

function touchTop(self, event)
    if event.phase == "ended" then
        if not firstAdShow.top then --since we already loaded at startup
            firstAdShow.top = true 
            amazonAds.showAd(adIds.top)
        else
            --request and show a new ad
            sceneMainMenu.prepareAd("top", true)
        end
    end
end

function touchBottom(self, event)
    if adsRunning and event.phase == "ended" then
        if not firstAdShow.bottom then
            firstAdShow.bottom = true 
            amazonAds.showAd(adIds.bottom)
        else
            sceneMainMenu.prepareAd("bottom", true)
        end
    end
end

function touchInterstitial(self, event)
    if adsRunning and event.phase == "ended" then
        sceneMainMenu.prepareAd("interstitial")
    end
end

function adsListener(event)
    print("adsListener")
    
    --NB: - "dismissed" events happen for banners on distruction too!
    --    - Can't use [if event.adType == "interstitial" then] to check type
    --      as there is a known bug in s3eAmazonAds that type is always 1!
    if event.adId == adIds["interstitial"] then
        if event.type == "loaded" then
            gotInterstitial = true
            dbg.print("interstitial ad loaded")
            sceneMainMenu.mainMenu.adLoadLabel.text = "Interstitial loaded: will display on game start"
        elseif event.type == "action" then
            if gotInterstitial and event.actionType == "dismissed" then
                startGame()
            end
        end
    end
    
    if event.type == "error" then
        dbg.print("Error loading ad (#".. event.adId .. "): " .. event.error)
    end
end

function touchQuit(self, event)
    if event.phase == "ended" then
        destroyAds()
        shutDownApp()
    end
end
