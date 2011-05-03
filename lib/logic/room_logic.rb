# file:: room_logic.rb
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
require 'room'

class WindyRoom < Logic
    invoked_by :enterroom,:canleaveroom
    applicable_to Room
    saveable

    def do_logic
        case @action
        when :enterroom
            # ####################################
            # should the performer be 'self' ??
            # ####################################
            a=Action.new(:sound,self.entity,{:sound => "The wind blows..."})
            $game.add_timed_action(a,5*1_000, :relative => true)
        when :canleaveroom
            player = @performer
            # ####################################
            # should the performer be 'self' ??
            # ####################################
            player.do_action(Action.new(:vision,player,
                {:sight => "A strong wind rattles the door..."}))
        end
        true
    end
end

class DarkRoom < Logic
    invoked_by :canlook,:canleaveroom
    applicable_to Room
    saveable

    def do_logic
        rez = case @action
        when :canlook
            inform(@performer,
                "It's too dark!") unless cansee?(@performer)
            cansee?(@performer)
        when :canleaveroom
            if Dice.% < 10
                inform(@performer,"You fumble around in the dark.")
                false
            else
                true
            end
        end
        rez
    end

private
    def cansee?(char)
        $stdout.puts("Can #{char} see? #{self.entity.is?(:illuminated)}")
        char.has?(:darkvision) or self.entity.is?(:illuminated)
    end
end

# probably want a "locked" door: canenter based on attr :locked 
# and "protected": canenter based on performer having "key"
class Locked < Logic
    invoked_by :canenterportal
    applicable_to Portal
    saveable

    def do_logic
        @performer.items.each do |item|
            return true if item.is?(:key) and item[:portalid] == self.entity.oid
        end
        inform(@performer,"#{self.entity} is locked.")
        false
    end
end
