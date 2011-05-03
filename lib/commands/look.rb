# file:: look.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

class Look < Command
    def initialize(char)
        super(char,'look','look [object]',
        'Look at the room(default), or at an object within the room.')
    end
    def execute(args)
        $game.do_action(Action.new(:attemptlook,self.character,
            {:target => args.join(' ')}))
    end
end
