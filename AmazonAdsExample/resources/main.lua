
require("helpers/Utility")
require("helpers/VirtualResolution")

--require("mobdebug").start() -- Uncomment for ZeroBrain IDE debuger support

pauseflag = false

appWidth = 640
appHeight = 960
virtualResolution:initialise{userSpaceW=appWidth, userSpaceH=appHeight}
screenWidth = virtualResolution:winToUserSize(director.displayWidth)
screenHeight = virtualResolution:winToUserSize(director.displayHeight)

adsRunning = false

dofile("SceneMainMenu.lua")
dofile("SceneGame.lua")

director:moveToScene(sceneMainMenu)

function shutDownApp()
    if adsRunning == false then
        amazonAds.terminate()
    end
    system:quit()
end
