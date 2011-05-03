# file:: quit.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

class Quit < Command
    def initialize(char)
        super(char,'quit','quit','Quit the Game.')
    end
    def execute(args)
        # do I need to "retrieve" the action?
        self.character.do_action(Action.new(:leave,self.character))
    end
end
