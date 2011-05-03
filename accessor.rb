# file:: accessor.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

# maybe rename to something shorter... Acc
# e.g. Acc::character("foo")
# or could I put them in the corresponding class?
# e.g. Character::character("foo")
module Accessor
    def character(char)
        $character_db.find(char)
    end
    def item(item)
        $item_db.find(item)
    end
    # room
    # portal
    # region
end

