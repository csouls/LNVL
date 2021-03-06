--[[
--
-- This file implements an array class which is 'clamped' at its end
-- by the first nil value.  For example:
--
--     foo = LNVL.ClampedArray:new()
--     foo[1] = 10
--     foo[0] = 2
--     foo[2] = 4
--     foo[3] = nil
--
-- So the values of the 'foo' array are now '{ [1] = 10, [2] = 4 }'.
-- ClampedArrays do not allow indexes less than one; so the index zero
-- is discarded.  Their length also stops at the first nil value *if
-- and only if* there are no more nil values after that.  So here the
-- length of the ClampedArray is two, but if we added
--
--     foo[4] = 40
--
-- the length would become four, i.e. {10, 4, nil, 40}.
--
--]]

local ClampedArray = {}

-- The constructor, which can take an array of arguments, which we
-- assume are numbers but do not enforce.
function ClampedArray:new(values)
    local self = {}
    setmetatable(self, ClampedArray)

    -- __first_nil_index: This hidden property is an integer that
    -- indicates the first index in the array's contents that is nil
    -- and which has no non-nil elements after it.
    self.__first_nil_index = 1

    -- This loop fills the array with any values we may have received.
    for key,value in ipairs(values) do
        self[key] = value
        self.__first_nil_index = self.__first_nil_index + 1
    end

    return self
end

-- When we access an element of the array we make sure the key is
-- within the bounds:
--
--     [1, __first_nil_index)
--
-- If not then we return the value of the highest index not equated to
-- a nil value.  That is assuming the key is a number.  If the key is
-- not a number then we assume the user is accessing a property by
-- name and simply return that.
ClampedArray.__index = function (table, key)
    if type(key) == "number" then
        if key < 1 then
            key = 1
        elseif key >= table.__first_nil_index then
            key = table.__first_nil_index - 1
        end
    end

    return rawget(table, key)
end

-- The __newindex() metatable function takes care to properly update
-- the array's __first_nil_index property when the key is a number.
ClampedArray.__newindex = function (table, key, value)
    if type(key) == "number" then
        if value == nil and key < table.__first_nil_index then
            table.__first_nil_index = key
        elseif key > table.__first_nil_index then
            table.__first_nil_index = key
        end
    end

    rawset(table, key, value)
end

-- The __len() metatable function returns the length up to the first
-- nil array element.  That nil element is not included as part of the
-- length, e.g. the array {10, 20, nil} has a length of two.
ClampedArray.__len = function (table)
    return table.__first_nil_index
end

-- Return the class as a module.
return ClampedArray
