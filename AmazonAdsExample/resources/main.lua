
require("helpers/Utility")
require("helpers/VirtualResolution")

--require("mobdebug").start() -- Uncomment for ZeroBrain IDE debuger support

pauseflag = false

appWidth = 640
appHeight = 960
virtualResolution:initialise{userSpaceW=appWidth, userSpaceH=appHeight}
screenWidth = virtualResolution:winToUserSize(director.displayWidth)
screenHeight = virtualResolution:winToUserSize(director.displayHeight)

dofile("SceneMainMenu.lua")
dofile("SceneGame.lua")

director:moveToScene(sceneMainMenu)

function shutDownApp()
    system:quit()
end
function shutDownCleanup(event)
    audio:stopStream()
end
system:addEventListener("exit", shutDownCleanup)





adId = -1

-- End start button animation (starts the game)
function startGame(event)
    -- Switch to game scene
    switchToScene("game")
    -- Stop menu music
    audio:stopStream()
    -- Start game music
    audio:playStream("audio/in_game.mp3", true)
    -- Start new game
    game:newGame()
end

-- Play button touched event handler
function playButtonTouched(event)
    if (event.phase == "ended") then
        -- Animate the play button
    --  tween:to(playText, { rotation=360, time=0.5 } )
    --  tween:to(playText, { alpha=0.3, delay=0.25, time=0.5, easing=ease.expIn} )
    --  tween:to(playButton, { alpha=0.3, delay=0.25, time=0.5, easing=ease.expIn, onComplete=startGame } )
        amazonAds.showAd(adId)
    end
end

-- Create and initialise the main menu
function init()
    -- Create a scene to contain the main menu
    menuScene = director:createScene()

    -- Create menu background
    local background = director:createSprite(director.displayCenterX, director.displayCenterY, "textures/menu_bkg.jpg")
    background.xAnchor = 0.5
    background.yAnchor = 0.5
    -- Fit background to screen size
    local bg_width, bg_height = background:getAtlas():getTextureSize()
    background.xScale = director.displayWidth / bg_width
    background.yScale = director.displayHeight / bg_height

    -- Create Start Game button
    local y_pos = director.displayHeight / 3
    playButton = director:createSprite(director.displayCenterX, y_pos, "textures/info_panel.png")
    playButton.xAnchor = 0.5
    playButton.yAnchor = 0.5
    playButton.xScale = game.graphicsScale * 1.5
    playButton.yScale = game.graphicsScale * 1.5
    playButton:addEventListener("touch", playButtonTouched)
    -- Create Start Game button text
    playText = director:createSprite(director.displayCenterX, y_pos, "textures/play.png")
    playText.xAnchor = 0.5
    playText.yAnchor = 0.5
    playText.xScale = game.graphicsScale
    playText.yScale = game.graphicsScale

    -- Start menu music
    audio:playStream("audio/frontend.mp3", true)    

    dbg.print("XXXXXXXXXXXXX init")
    amazonAds.init("d61638a732ea4f459ea445797d546518", "5b1b1bf93f0644af9caaffc58fd467dc")
    dbg.print("XXXXXXXXXXXXX prepareAd")
    adId = amazonAds.prepareAd()
    dbg.print("XXXXXXXXXXXXX got adid: " .. adId)
    dbg.print("XXXXXXXXXXXXX prepareAdLayout")
    --amazonAds.prepareAdLayout(adId, "bottom", "auto")
    dbg.print("loadAd")
    amazonAds.loadInterstitialAd(adId)
    --amazonAds.loadAd(adId)

end

