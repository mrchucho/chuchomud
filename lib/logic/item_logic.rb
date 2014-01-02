# file:: item_logic.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

require 'logic'
require 'item'

class Heavy < Logic
    invoked_by :cangetitem
    needs_data :item
    applicable_to Item
    # saveable

    def do_logic
        if @action== :cangetitem and @item == self.entity then
            if self.entity[:weight] and self.entity[:weight] >= 10 then
                show(@performer.room,
                    "#{@performer} tries in vain to get #{self.entity}.")
                return false
            end
        end
        true
    end
end

class Usable < Logic
    invoked_by :canuseitem, :useitem
    needs_data :item
    applicable_to Item
    saveable

    def do_logic
        r = case @action
        when :canuseitem
            self.respond_to?(:can_use) ? can_use : true
        when :useitem
            use
            true
        end
        r
    end
end

class LightSource < Usable
    def use
        @performer[:darkvision] = self.entity[:running]
    end
end

# probably wouldn't work to add an attribute to the 
# @entity, unless it overrode :dellogic message and
# removed that attribute
#
# but how else would you affect that attribute? i.e.
# how would you replenish the battery? I guess if you
# did "use battery on light" you could send some message
# to light? ...
class RequiresPower < Usable
    def do_init
        self.entity[:running] = false
        self.entity[:powerlevel] = 10
    end
    # can you turn it off or on?
    def can_use
        inform_owner(
        "#{self.entity} is out of power.") if self.entity[:powerlevel] <= 0
        self.entity[:running] or !self.entity[:running] and self.entity[:powerlevel] > 0
    end
    def use
        self.entity[:running] = !self.entity[:running]
        self.entity[:powerlevel] -= 1
        inform_owner(
            "You turn #{self.entity} #{self.entity[:running] ? 'on' : 'off'}.")
    end
private
    def inform_owner(msg)
        return unless self.entity.character
        inform(self.entity.character,msg)
    end
end

# should this be Usable ?
class AmbientLightSource < Logic
    invoked_by :itemused
    needs_data :item
    applicable_to Item
    saveable

    def do_logic
        owner = (self.entity.character) ?
            self.entity.character : self.entity.room
        if self.entity[:running] then
            # owner.add_existing_logic(ProvidesAmbientLight.new(owner))
            $game.do_action(Action.new(:addlogic,owner,
            {:logic => ProvidesAmbientLight.new(owner)}))
        else 
            $game.do_action(Action.new(:dellogic,owner,
            {:logic => ProvidesAmbientLight}))
        end
    end
end

class ProvidesAmbientLight < Logic
    invoked_by :enterroom,:leaveroom
    needs_data :room
    applicable_to Character,Item,Room,Region

    # on init, make room illuminated
    def do_init
        light[:illuminated] = true
    end
    def do_removed
        light.del_attribute(:illuminated)
    end
    def do_logic
        case @action
        when :enterroom
            @room[:illuminated] = true
        when :leaveroom
            @room.del_attribute(:illuminated)
        else 
            $log.error("Why did I get #{@action}?")
        end
        true
    end
private
    def light
        if self.entity.respond_to?(:room) then
            self.entity.room
        elsif self.entity.kind_of?(Room) then
            self.entity
        end
    end
end
