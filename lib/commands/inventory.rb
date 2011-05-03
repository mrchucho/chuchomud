# file:: inventory.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

class Inventory < Command
    def initialize(char)
        super(char,'inv','inv',
        'Print Inventory')
    end
    def execute(args)
        msg = "
--------------------------------------------------------------------------------
 #{BOLD}Your Inventory#{RESET}
--------------------------------------------------------------------------------
"
self.character.items.each do |item|
    msg += "#{item.name+EOL}"
end
    msg += "
--------------------------------------------------------------------------------
"
        self.inform(msg)
    end
end
