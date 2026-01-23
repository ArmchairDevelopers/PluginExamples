-- TOOD: Embed this in the plugin system.

function registerVec()
    local globalVec = Vec3
    Vec3 = function(...)
        local args = {...}
        
        local obj = globalVec()
        if #args == 1 then
            obj.x = args[1]
            obj.y = args[1]
            obj.z = args[1]
        elseif #args == 3 then
            obj.x = args[1]
            obj.y = args[2]
            obj.z = args[3]
        end

        return obj
    end

    local vec3Meta = getmetatable(globalVec())

    vec3Meta.__add = function(self, other)
        if type(other) == "number" then
            return Vec3(self.x + other, self.y + other, self.z + other)
        elseif type(other) == "userdata" then
            return Vec3(self.x + other.x, self.y + other.y, self.z + other.z)
        end
        
        error("Invalid type for Vec3 addition " .. type(other))
    end

    vec3Meta.__sub = function(self, other)
        if type(other) == "number" then
            return Vec3(self.x - other, self.y - other, self.z - other)
        elseif type(other) == "userdata" then
            return Vec3(self.x - other.x, self.y - other.y, self.z - other.z)
        end
        
        error("Invalid type for Vec3 subtraction " .. type(other))
    end

    vec3Meta.__mul = function(self, other)
        if type(other) == "number" then
            return Vec3(self.x * other, self.y * other, self.z * other)
        elseif type(other) == "userdata" then
            return Vec3(self.x * other.x, self.y * other.y, self.z * other.z)
        end
        
        error("Invalid type for Vec3 multiplication " .. type(other))
    end

    vec3Meta.__div = function(self, other)
        if type(other) == "number" then
            return Vec3(self.x / other, self.y / other, self.z / other)
        elseif type(other) == "userdata" then
            return Vec3(self.x / other.x, self.y / other.y, self.z / other.z)
        end
        
        error("Invalid type for Vec3 division " .. type(other))
    end

    vec3Meta.__unm = function(self)
        return Vec3(-self.x, -self.y, -self.z)
    end

    vec3Meta.__eq = function(self, other)
        return self.x == other.x and self.y == other.y and self.z == other.z
    end
end

registerVec()
