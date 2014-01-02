# file:: character_logic.rb
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
require 'character'
require 'item'
require 'room'
require 'dice'

class Encumbrance < Logic
    invoked_by :cangetitem,:canreceiveitem,:getitem,:dropitem,:giveitem
    needs_data :item,:quantity
    optionally :to
    applicable_to Character
    saveable

    def do_logic
        if not @item.has?(:weight) then
            $log.error("#{@item} doesn't have any weight!")
            return true
        end
        total = @item[:weight] * (@quantity||=1)
        case @action
        when :cangetitem,:canreceiveitem
            return allowable?(total)
        when :getitem
            puts("got item with weight #{total}")
            self.entity[:encumbrance] += total
        when :dropitem
            self.entity[:encumbrance] -= total
        when :giveitem
            self.entity[:encumbrance] -= total if self.entity == @performer
            self.entity[:encumbrance] += total if self.entity == @to 
        end
        true
    end
private
    def allowable?(total)
        self.entity[:encumbrance]+total < self.entity[:maxencumbrance]
    end
end

class CanReceive < Logic
    invoked_by :canreceiveitem
    needs_data :to
    applicable_to Character
    saveable

    def do_logic
        if @type==:canreceiveitem and not @to[:receive] then
            @performer.do_action(Action.new(:announce, self.entity,
            {:msg => "#{to} cannot receive items."}))
            return false
        end
        true
    end
end

class Tired < Logic
    invoked_by :cansay,:canlook
    applicable_to Character
    # saveable

    def do_logic
        result = true
        case @action
        when :cansay
            if Dice.% < 90 then
                inform(self.entity,"You are too tired!")
                result = false
            end
        when :canlook
            if Dice.% < 90 then
                inform(self.entity,"Oh no! Your lids have fallen shut! Zzzz.")
                result = false
            end
        end
        result
    end
end

class Clumsy < Logic
    invoked_by :canleaveroom
    applicable_to Character

    def do_logic
        result = true
        case @action
        when :canleaveroom
            if Dice.% < 90 then
                inform(self.entity,"LOL! You tripped!")
                result = false
            end
        end
        result
    end
end

class Talkative < Logic
    invoked_by :enterroom,:enterrealm,:leaveroom
    applicable_to Character, Item

    def do_logic
        return if @performer==self.entity
        case @action
        when :enterroom,:enterrealm
            say(self.entity,"Hey, #{@performer}, zup?")
            $game.add_timed_action(Action.new(:attemptsay,self.entity,
            { :msg => "Seriously, what IS UP?"}),5000,:relative => true)
        when :leaveroom
            say(self.entity,"Well, bye, #{@performer}...")
        end
        true
    end
end

=begin
class Manalicious < Logic
    invoked_by :enterroom,:see
    needs_data :target
    applicable_to Character,Item

    def do_logic
        case @action
        when :enterroom
            o = @performer
        when :see
            o = @target
        end
        if o and(o.include?(:mana) and o[:mana] >= 10) then
            @char.do_action(Action.new(:announce,self.entity,
            { :msg =>
            "The mana on #{BOLD+o.name+RESET} is positively glowing!"
            }))
        end
        true
    end
end
=end

# This is the beginning of an "effect" class!
class Poisoned < Logic
    invoked_by :poison,:enterrealm,:leaverealm,:logged_out
    applicable_to Character
    saveable

    # ends at freq * ((duration/freq) - elapsed)

    FREQUENCY_IN_SEC = 60
    DURATION_IN_SEC = 3*60

    def do_init
        @elapsed = 0
    end

    def do_added
        $evt_log.debug("#{self.entity} poisoned!")
        apply_poison
        send_poison_action
        @starts = $game.time
        @ends = $game.add_timed_action(Action.new(:dellogic,self.entity,{:logic=>self}),
            ends*1_000, :relative => true)
        # tell the player he's cured
        # $game.add_timed_action(Action.new(:announce,self,{:logic=>self}),
        # 5*60*1_000+1, :relative => true)
    end
            
    def do_logic
        case @action
        when :poison
            apply_poison
            send_poison_action
            @elapsed += 1
        when :enterrealm
            @left ||= 0
            puts("poisoned, enter left: #{Timer.digital(@left)}, next: #{Timer.digital(@next)}")
            send_poison_action(@next-@left)
            @ends = $game.add_timed_action(Action.new(:dellogic,self.entity,{:logic=>self}),
                ends*1_000, :relative => true)
        when :leaverealm
            @left = $game.time
            puts("poisoned, leave left: #{Timer.digital(@left)}")
        end
        true
    end
private
    def apply_poison
        self.entity[:life] -= 1
    end
    def send_poison_action(at=FREQUENCY_IN_SEC*1_000)
        @next = $game.add_timed_action(Action.new(:poison,self),
            at, :relative => true)
    end

    def ends
        FREQUENCY_IN_SEC * ((DURATION_IN_SEC/FREQUENCY_IN_SEC)-@elapsed)
    end
end


class Sick < Effect
    frequency_in_sec 60
    duration_in_sec  5*60
    delayed false
    applied_message "You suddenly feel ill"
    effect_message  "You vomit"
    removed_message "Your illness passes"

    def apply_effect
        self.entity[:life] -= 1
    end
end

class Wandering < Effect
    frequency_in_sec 60
    #duration_in_sec  5*60
    delayed false
    applied_message ""
    effect_message  ""
    removed_message ""

    def apply_effect
        return unless defined?(self.entity.room.portals)
        p = rand(self.entity.room.portals.size)
        portal = self.entity.room.portals[p] 
        dest = portal.entries.find do |e|
            e.start_room==self.entity.room
        end
        if dest then
            $game.do_action(Action.new(:attemptenterportal,self.entity,
            {:room => dest.end_room, :portal => portal}))
        end
    end
end

class VisualWatcher < Logic
    invoked_by :vision
    needs_data :sight
    applicable_to Character

    def do_logic
        if @sight =~ /[sS]neeze/ then
            say(self.entity,"Bless you!")
        end
        true
    end
end
