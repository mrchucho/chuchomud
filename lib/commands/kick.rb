# file:: kick.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

class Kick < Command
    RANK = 2 # ADMIN or something
    def initialize(char)
        super(char,'kick','kick <player>',
        'Kick a player.')
    end
    def execute(args)
    end
end
