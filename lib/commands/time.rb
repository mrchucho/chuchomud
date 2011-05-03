# file:: time.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

class GameTime < Command
    def initialize(char)
        super(char,'time','time',
        'Print the time... sorta...')
    end
    def execute(args)
        inform($game.instance_variable_get('@basic_timer').to_s)
    end
end
