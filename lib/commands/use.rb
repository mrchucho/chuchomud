# file:: use.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

class Use < Command
    def initialize(char)
        super(char,'use','use <item>',
        'Attempt to use an item.')
    end
    def execute(args)
        raise UsageException if args.empty?

        item = args.join(' ')

        # seek
        self.character.items.each do |i|
            if i.named?(item) then
                $game.do_action(Action.new(:attemptuseitem,self.character,
                {:item => i}))
                return
            end
        end
        inform("You don't have #{item}.")
    end
end
