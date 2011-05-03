# file:: go.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

class Go < Command
    def initialize(char)
        super(char,'go','go <exit>',
        'Leave the current room through <exit>.')
    end
    def execute(args)
        raise UsageException if args.empty?
        room = self.character.room
        room.portals.each do |portal|
            if exit = portal.entries.find{|e|e.named?(args.join(' ')) \
                and e.start_room==room} then
                $game.do_action(Action.new(:attemptenterportal,self.character,
                {:room => exit.end_room, :portal => portal}))
                return
            end
        end
        inform("You cannot go that way.")
    end
end
