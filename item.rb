# file:: item.rb
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

class ItemTemplate < Entity
    include DataEntity
    attr_accessor :quantity,:logics,:many
end

class Item < LogicEntity
    include DataEntity,HasRoom,HasRegion,HasTemplateID

    attr_accessor :quantity,:many

    def initialize
        @quantity = 1
        @many = false
    end

    def many?
        @many
    end

    def description
        @description.sub(/#/,self.quantity.to_s)
    end

    def add
        if self.region then
            self.region.add_item(self)
            self.room.add_item(self)
        else
            self.character.add_item(self) if self.character
        end
    end
    def remove
        # return unless self.room
        if self.region then
            self.region.del_item(self)
            self.room.del_item(self)
        else
            self.character.del_item(self)
        end
    end

    def load_template(tmpl)
        self.template_id=tmpl.oid
        self.name=tmpl.name.dup if tmpl.name
        self.description=tmpl.description.dup if tmpl.description
        self.attributes=tmpl.attributes.dup
        self.many=tmpl.many
        self.quantity=tmpl.quantity
        tmpl.logics.each do |logic|
            self.add_logic($logic_db.generate(logic,self))
        end if tmpl.logics
    end

    # if a character "owns" this item
    def character=(char)
        @character = char.oid
    end
    def character
        $character_db.get(@character) if defined?(@character)
    end

    def clear_char
        @character = nil
    end
end
