# file:: action.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

# ------------------------------------------------------------------------------
# Actions: see TODO
# ------------------------------------------------------------------------------
require 'entity_container'

# Represents an event, query or the initiation of a command in the game.
class Action
    include HasEntity
    attr_accessor :type,:data

    # [+type+] Symbol identifying the action
    # [+performer+] Entity performing the action
    # [+data+] A free-form has containing information about the action
    def initialize(type,performer,data={})
        @type = type
        self.performer = performer
        @data = data
    end

    def performer=(p)
        self.entity = p
    end
    def performer
        self.entity
    end
=begin
    # for "routable" actions
    def route(target)
        case target
        when Character
            #
        when Item
            #
        when Room
            #
        when Portal
            #
        when Region
        end
    end
=end
    def to_s
        "#{@type} {" + 
        @data.collect{|k,v| ":#{k}=>#{v.to_s.sub(EOL,'')}"}.join(', ') +
        "}"
    end
end

# An action that goes into the Game's event queue for later processing.
class TimedAction
    include Comparable,Observable
    attr_accessor :when,:action,:valid

    def initialize(act,time)
        @when,@action,@valid = time,act,true
    end

    def <=>(ta)
        @when <=> ta.when
    end

    def valid?
        @valid
    end

    # Need to document
    def hook
        # hrm. switch on action-type
            # can this be done with 
            # action.data.values
                # hook if kind_of?LogicEntity
            #add_observers(necessary entity(ies))
        # add_observer(@action.performer)

        $evt_log.debug("Timed action,#{self}(#{@action}), hooking to #{@action.performer}")
        @action.performer.add_observer(self)

        case @action.type
        when :dellogic
            @action.data[:logic].add_observer(self)
        end
    end
    
    # Need to document
    def unhook
        $evt_log.debug("Timed action,#{self}(#{@action}), unhooking from #{@action.performer}")

        @valid = false
        $evt_log.debug("FOR SOME REASON PERFORMER IS ALREADY GONE") unless @action.performer
        @action.performer.delete_observer(self) if @action.performer
    end

    # called by entity when entity destroyed, i.e.
    # cancel this action
    def update(hooker)
        $evt_log.debug("Timed action,#{self}(#{@action}), cleared by #{hooker}")
        unhook
    end
end
