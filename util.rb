# file:: util.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

module PlayerInteractionUtils 
    # send a informational 'message' directly to 'recipient'
    def inform(recipient,message)
        recipient.do_action(
            Action.new(:announce,recipient,{:msg => message})
        ) if message and not message.empty?
    end
end

module CharacterInteractionUtils
    # have 'speaker' attempt to say 'message'
    def say(speaker,message)
        $game.do_action(
            Action.new(:attemptsay,speaker, { :msg => message })
        ) if message and not message.empty?
       
    end
end

module AreaInteractionUtils
    # show 'vision' in 'area' (e.g. Room, Region)
    def show(area,vision)
        $game.do_action(
            Action.new(:vision,area,{:sight => vision})
        ) if vision and not vision.empty?
    end
    
    def hear(area,sound)
        $game.do_action(
            Action.new(:sound,area,{:sound => sound})
        ) if sound and not sound.empty?
    end
end
