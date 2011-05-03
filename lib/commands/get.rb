# file:: get.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

class Get < Command
    def initialize(char)
        super(char,'get','get [quantity] <item>',
        'Attempt to pickup an item.')
    end
    def execute(args)
        raise UsageException if args.empty?

        quantity = args.shift.to_i if args[0] =~ /(\d)/
        item = args.join(' ')

        # seek
        self.character.room.items.each do |i|
            if i.named?(item) then
                $game.do_action(Action.new(:attemptgetitem,self.character,
                {:item => i, :quantity => quantity||=1}))
                return
            end
        end
        inform("You don't see #{item} here.")
    end
end

class Drop < Command
    def initialize(char)
        super(char,'drop','drop [quantity] <item>',
        'Attempt to drop an item.')
    end
    def execute(args)
        raise UsageException if args.empty?

        quantity = args.shift.to_i if args[0] =~ /(\d)/
        item = args.join(' ')

        # seek
        self.character.items.each do |i|
            if i.named?(item) then
                $game.do_action(Action.new(:attemptdropitem,self.character,
                {:item => i, :quantity => quantity||=1}))
                return
            end
        end
        inform("You don't have #{item}.")
    end
end
