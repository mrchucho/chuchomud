# file:: room.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

require 'entities'

class Room < LogicEntity
    include DataEntity,HasRegion,HasCharacters,HasItems,HasPortals

    def add
        self.region.add_room(self) if self.region
    end
    def remove
        self.region.del_room(self) if self.region
    end

    def exits
        exits = []
        self.portals.each do |portal|
            exits << portal.entries
        end
        exits.flatten!.find_all{|e| e.start_room==self} 
    end
end
