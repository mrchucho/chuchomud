# file:: clear.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

class Clear < Command
    def initialize(char)
        super(char,'clear','clear',
        'Clear the screen.')
    end
    def execute(args)
        self.character.do_action(Action.new(:vision ,self.character,
            {:sight => CLEARSCREEN+EOL}))
    end
end
