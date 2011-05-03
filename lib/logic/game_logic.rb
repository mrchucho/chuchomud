# file:: game_logic.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

require 'character'
require 'item'
require 'room'

require 'telnet_commands'

# -----------------------------------------------------------------------------
# This file is for Game ENGINE logic, not "game-wide" logic.
# -----------------------------------------------------------------------------
class TelnetReporter
    # --- hacks to make this imitate a Logic
    def stacking_rule
        :replaceable
    end
    def entity
        @player
    end
    # ---
    def initialize(player,conn)
        @player = player#.oid
        @connection = conn
    end
    def do_action(action)
        result = true
        case action.type
        when :announce
            @connection.display(action.data[:msg])
        when :say
            speaker = (action.performer==@player) ? 'You say' :
                "#{BOLD+action.performer.name+RESET} says"
            @connection.display(
                "#{speaker} \"#{action.data[:msg]}\"")
        when :see
            see(action.data[:target])
        when :sound
            @connection.display(action.data[:sound])
        when :vision
            @connection.display(action.data[:sight].gsub(@player.name,'You'))
        when :hangup
            @connection.close
            @connection.clear_handlers
        when :enterroom
            enter_room(action.performer,action.data[:room],action.data[:portal])
        when :leaveroom
            leave_room(action.performer,action.data[:room],action.data[:portal])
        when :enterrealm
            @connection.display(
            "#{action.performer.name} enters the realm.")
        when :leaverealm
            @connection.display(
            "#{action.performer.name} has left the realm.")
        when :leave
            @connection.remove_handler
        when :error
            @connection.display(action.data[:msg])
        else
            # $stderr.puts("Unknown #{@action}")
            # should only return false if *can't*
            #result = false
        end
        result
    end

    def see(what)
        case what
        when Character,Item,Portal
            @connection.display(
            "You see #{(what.description) ? what.description : what.name}.")
        when Room
            # if @player.verbose? then
                @connection.display(
"#{BOLD+what.name+RESET}

#{what.description}

#{what.characters.join(', ')+((what.characters.size>1)?' are':' is')} here.

#{('You see: '+what.items.join(', ')) if not what.items.empty?}

Exits:
")
            what.portals.each do |portal|
                portal.entries.find_all{|entry| \
                entry.start_room==what}.each do |entry|
                    @connection.display(
                    "#{entry.name} - #{portal.name}")
                end
            end
            # end
        end
    end

    def enter_room(char,room,portal)
        if char.oid==@player.oid  then
            $game.do_action(Action.new(:attemptlook,@player))
            return
        end
        if portal then
            @connection.display(
            "#{char} enters from #{portal}.")
        else 
            @connection.display(
            "#{char} appears from nowhere!")
        end
    end

    def leave_room(char,room,portal)
        return if char.oid==@player.oid
        if portal then
            @connection.display(
            "#{char} leaves through #{portal}.")
        else
            @connection.display(
            "#{char} vanishes...")
        end
    end

    def to_s
        "Telnet Reporter"
    end
end

