# file:: say.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

class Say < Command
    def initialize(char)
        super(char,'say','say','Speak.')
    end
    def execute(args)
        # do I need to "retrieve" the action?
        $game.do_action(
            Action.new(:attemptsay,self.character,
            {:msg => args.join(' ')}))
    end
end

