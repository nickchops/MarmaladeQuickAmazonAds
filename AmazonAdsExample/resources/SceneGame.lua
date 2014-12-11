
dofile("helpers/BackButton.lua")

sceneGame = director:createScene()
sceneGame.name = "game"

function sceneGame:setUp(event)
    virtualResolution:applyToScene(self)
    
    system:addEventListener({"suspend", "resume", "update"}, self)
    
    director:createLabel({x=appWidth/2, y=appHeight/2, hAlignment="center", vAlignment="bottom", text="Turns out this game is\njust a lot of adverts!", color=color.white, xScale=2, yScale=2})
    
    backButtonHelper:add({listener=self.quit, xCentre=appWidth/2, yCentre=200, btnWidth=appWidth/2,
                btnTexture="textures/bigwhitebutton.png", pulse=true, activateOnRelease=true, animatePress=true,
                deviceKeyOnly=false, drawArrowOnBtn=true, arrowThickness=5})
end

function sceneGame:exitPostTransition(event)
    backButtonHelper:remove()
    destroyNodesInTree(self, false)
    
    self:releaseResources()
    collectgarbage("collect")
    director:cleanupTextures()
end

sceneGame:addEventListener({"setUp", "exitPostTransition"}, sceneGame)

-------------------------------------------------------------

function sceneGame.quit()
    system:removeEventListener({"suspend", "resume", "update", "touch"}, sceneGame)
    pauseNodesInTree(sceneGame)
    backButtonHelper:disable()
    director:moveToScene(sceneMainMenu, {transitionType="slideInL", transitionTime=0.8})
end

---- Pause/resume logic/anims on app suspend/resume ---------------------------

function sceneGame:suspend(event)
    if not pauseflag then
        system:pauseTimers()
        pauseNodesInTree(self)
    end
end

function sceneGame:resume(event)
    pauseflag = true
end
