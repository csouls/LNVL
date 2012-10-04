--[[
--
-- This file implements scenes in LNVL.  Developers do all work with
-- scenes through Scene objects, a class that this file defines.
--
--]]

-- Create the LNVL.Scene class.
LNVL.Scene = {}
LNVL.Scene.__index = LNVL.Scene
setmetatable(LNVL.Scene, LNVL.Scene)

-- If the class name is used directly like a function then it acts as
-- a constructor that returns an LNVL.Scene object.  The argument is a
-- single table that contains the contents for the scene.
LNVL.Scene.__call =
    function (contents)
        local new_scene = {}
        new_scene.__index = LNVL.Scene
        setmetatable(new_scene, LNVL.Scene)

        new_scene.background_color = {255, 255, 255}

        return new_scene
    end

-- These are the default dimensions for a Scene.  These values will be
-- given as the values to arguments of the same name for functions
-- like love.graphics.rectangle().
LNVL.Scene.Dimensions = {
    Width = 600,
    Height = 240,
    X = 100,
    Y = 300,
}

-- This method draws the container or border of the scene.
function LNVL.Scene:drawContainer()
    love.graphics.setColor(self.background_color)
    love.graphics.rectangle("fill",
                            self.Dimensions.X,
                            self.Dimensions.Y,
                            self.Dimensions.Width,
                            self.Dimensions.Height)
end

-- This method draws the scene to the screen.
function LNVL.Scene:draw()
    self:drawContainer()
end