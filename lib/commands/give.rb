# file:: give.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

class Give < Command
    def initialize(char)
        super(char,'give','give <character> [quantity] <item>',
        'Attempt to give an item to a character.')
    end
    def execute(args)
        raise UsageException if not args or (args.empty? or args.size < 2)

        to = args.shift
        quantity = (args[0] =~ /(\d)/) ? args.shift.to_i : 1
        item = args.join(' ')

        receiver = self.character.room.characters.find{|c| c.named?(to)}
        puts("looking for >#{item}<")
        theitem = self.character.items.find{|i| i.named?(item)}

        if receiver and theitem then 
                $game.do_action(Action.new(:attemptgiveitem,self.character,
                {:to => receiver, :item => theitem, :quantity => quantity}))
        end
        self.inform("You don't see #{to} here.") unless receiver
        self.inform("You don't see #{item} here.") unless theitem
    end
end

class Receive < Command
    def initialize(char)
        super(char,'receive','receive [on|off]',
        'Turn on/off or display item receiving.')
    end
    def execute(args)
        self.character[:receive] ||= false
        case args.join(' ')
        when /on/
            self.character[:receive] = true
        when /off/
            self.character[:receive] = false
        when /\w/
            raise UsageException
        end

        self.inform("Receive set to \"#{self.character[:receive]}\".")
    end
end
