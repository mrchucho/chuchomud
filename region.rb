# file:: region.rb
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

class Region < LogicEntity
    include DataEntity,HasCharacters,HasItems,HasRooms,HasPortals

    def disk_name
        # remove spaces from name
        self.name.gsub(/ /,'_') #
    end
end
