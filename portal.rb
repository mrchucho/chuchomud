# file:: portal.rb
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
require 'nameable'

class Portal < LogicEntity
    include DataEntity,HasRegion

    attr_accessor :entries

    def initialize
        @entries = []
    end

    def add
        self.region.add_portal(self) if self.region
        @entries.each do |p|
            p.start_room.add_portal(self)
        end
    end
    def remove
        self.region.del_portal(self) if self.region
        @entries.each do |p|
            p.start_room.del_portal(self)
        end
    end
end

class PortalEntry
    include Nameable
    def start_room=(room)
        @start = room.oid
    end
    def start_room
        $room_db.get(@start) if @start
    end
    def end_room=(room)
        @end = room.oid
    end
    def end_room
        $room_db.get(@end) if @end
    end
end
