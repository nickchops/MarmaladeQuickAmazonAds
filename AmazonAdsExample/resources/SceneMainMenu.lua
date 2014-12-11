
require("helpers/Utility")
require("helpers/NodeUtility")

-- These are user space coords for screen edges that will inc letterbox areas
-- that VirtualResolution has created
menuScreenMinX = appWidth/2 - screenWidth/2
menuScreenMaxX = appWidth/2 + screenWidth/2
menuScreenMinY = appHeight/2 - screenHeight/2
menuScreenMaxY = appHeight/2 + screenHeight/2

sceneMainMenu = director:createScene()
sceneMainMenu.name = "menu"

useQuitButton =  device:getInfo("platform") ~= "IPHONE"

local btnW = 500
local btnHScale = 0.4 

local adId = -1
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
    self.mainMenu = director:createNode({x=appWidth/2,y=appHeight-200})
    self.mainMenu.titleOutline = director:createLines({x=0, y=0, coords={-240,-50, -240,50, 240,50, 240,-50, -240,-50},
            strokeWidth=4, strokeColor=color.white, alpha=0})
    self.mainMenu:addChild(self.mainMenu.titleOutline)
    self.mainMenu.titleText = director:createLabel({x=-210, y=-15, w=400, h=100,
            hAlignment="left", vAlignment="bottom", text="Amazon Mobile Ads: The Game", color=color.white, xScale=1.2, yScale=1.2})
    self.mainMenu:addChild(self.mainMenu.titleText)

    -- buttons
    self.btns = {}
    local btnY = -170
    sceneMainMenu:addButton("start", "Start Game", btnY, touchStart, 20)

    btnY = btnY - 100
    sceneMainMenu:addButton("topBanner", "load new top banner", btnY, touchTop, 20)

    btnY = btnY - 100
    sceneMainMenu:addButton("bottomBanner", "load new bottom banner", btnY, touchBottom, 20)
    
    btnY = btnY - 100
    sceneMainMenu:addButton("interstitial", "display interstitial ad", btnY, touchBottom, 20)

    if useQuitButton then
        btnY = btnY - 100
        sceneMainMenu:addButton("quit", "Quit", btnY, touchQuit, 20)
    end

    enableMainMenu()
    
    -- initialise and request an ad ID to use
    if amazonAds.isAvailable() then
        if amazonAds.init("d61638a732ea4f459ea445797d546518", "5b1b1bf93f0644af9caaffc58fd467dc") then
            adId = amazonAds.prepareAd()
        end
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
    self.btns[name] = director:createSprite({x=0, y=btnY, xAnchor=0.5, yAnchor=0.5, source="textures/bigwhitebutton.png"}) --color=btnCol

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
end

---- Button handlers ----------------------------------------------------------

function touchStart(self, event)
    if event.phase == "ended" then
        disableMainMenu()
        director:moveToScene(sceneGame, {transitionType="slideInR", transitionTime=0.8})
    end
end

function touchTop(self, event)
    if event.phase == "ended" then
        amazonAds.prepareAdLayout(adId, "top", "auto")
        amazonAds.loadAd(adId)
    end
end

function touchBottom(self, event)
    if event.phase == "ended" then
        amazonAds.prepareAdLayout(adId, "bottom", "auto")
        amazonAds.loadAd(adId)
    end
end

function touchInterstitial(self, event)
    if event.phase == "ended" then
        amazonAds.loadInterstitialAd(adId)
        amazonAds.showAd(adId)
    end
end

function touchQuit(self, event)
    if event.phase == "ended" then
        shutDownApp()
    end
end
