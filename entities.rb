# file:: entities.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.
require 'nameable'
# -----------------------------------------------------------------------
# Base Class
# -----------------------------------------------------------------------
class Entity
    include Comparable,Nameable

    attr_accessor :oid,:description

    def <=>(e)
        self.oid<=>e.oid
    end
    def to_s
        @name
    end
end
# -----------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------
def find_entity(on,where,klass,&compare)
        search = case where
        when /char/,/self/
            [on.items]
        when /room/
            [on.room,on.room.characters,on.room.items,on.room.portals]
        when /region/
            [on.region.characters,on.region.items,on.region.rooms,on.region.portals]
        when /world/
            [on.region]
        else
            []
        end

        search.flatten.find_all do |e|
            e.kind_of?(klass) and (compare.call(e))
        end
end
# -----------------------------------------------------------------------
# Basic Data Classes
# -----------------------------------------------------------------------
module HasRoom
    def room
        $room_db.get(@room) if defined?(@room)
    end
    def room=(r)
        @room=r.oid
    end
end
module HasRegion
    def region
        $region_db.get(@region) if defined?(@region)
    end
    def region=(r)
        @region=r.oid
    end
end
module HasTemplateID
    def template_id
        @template_id||=0
    end
    def template_id=(r)
        @template_id=r
    end
end
# -----------------------------------------------------------------------
# Basic Container Classes: these are all Sets
# -----------------------------------------------------------------------
module HasCharacters
    def add_character(c)
        # raise "Character #{c} does not exist!" unless $character_db.get(c.oid)
        @chars||=[]
        @chars |= [c.oid]
    end
    def del_character(c)
        @chars||=[]
        @chars.delete(c.oid)
    end
    def characters
        @chars||=[]
        @chars.collect{|c| $character_db.get(c)}.reject{|c| c==nil}
    end
end
module HasItems
    def add_item(c)
        # raise "Item #{c} does not exist!" unless $item_db.get(c.oid)
        @items||=[]
        @items |= [c.oid]
    end
    def del_item(c)
        @items||=[]
        @items.delete(c.oid)
    end
    def items
        @items||=[]
        @items.collect{|i| $item_db.get(i)}.reject{|i| i==nil}
    end
end
module HasRooms
    def add_room(r)
        # raise "Room #{r} does not exist!" unless $room_db.get(r.oid)
        @rooms||=[]
        @rooms |= [r.oid]
    end
    def del_room(r)
        @rooms||=[]
        @rooms.delete(r.oid)
    end
    def rooms
        @rooms||=[]
        @rooms.collect{|r| $room_db.get(r)}.reject{|r| r==nil}
    end
end
module HasPortals
    def add_portal(p)
        # raise "Portal #{p} does not exist!" unless $portal_db.get(p.oid)
        @portals||=[]
        @portals |= [p.oid]
    end
    def del_portal(p)
        @portals||=[]
        @portals.delete(p.oid)
    end
    def portals
        @portals||=[]
        @portals.collect{|p| $portal_db.get(p)}.reject{|p| p==nil}
    end
end
# -----------------------------------------------------------------------
# Complex Function Classes
# -----------------------------------------------------------------------
module DataEntity
    def [](k);@properties||={};@properties[k];end
    def []=(k,v);@properties||={};@properties[k]=v;end
    def include?(k);@properties||={};@properties.include?(k);end
    def has_key?(k);@properties||={};@properties.has_key?(k);end
    def delete(k);@properties||={};@properties.delete(k);end
    def del_attribute(k); self.delete(k);end

    def is?(k)
        self.has_key?(k) and self[k] != false
    end
    def has?(k);self.is?(k);end

    def attributes
        @properties||={}
    end
protected
    def attributes=(attr)
        @properties=attr
    end
end

class LogicEntity < Entity
    require 'observer'
    include Observable

    def loaded
        $log.info("loaded #{self}")
    end
    def saved
        $log.info("saved #{self}")
    end
    def add_logic(new_logic)
        @logic||=[]
        case new_logic.stacking_rule
        when :exclusive
            if find_logic_by_type(new_logic)
                #raise "#{new_logic} already exists and is not stackable"
                $log.error("#{new_logic} already exists and is not stackable")
            else
                @logic << new_logic
            end
        when :stackable
            @logic << new_logic
        when :replaceable
            del_logic(new_logic) if find_logic_by_type(new_logic) # er sumthin
            @logic << new_logic
        end
        new_logic.inform(self,new_logic.applied) if new_logic.respond_to?(:applied)
        new_logic.do_added if new_logic.respond_to?(:do_added)
    end
    def del_logic(logic)
        if logic.kind_of?(String) 
            raise "#{logic} is not a valid Logic object"
        else 
            if logic.respond_to?(:entity) and (logic.entity == self)
                logic.clear_timers if logic.respond_to?(:clear_timers)
                @logic.delete_if{|l| l.class==logic.class} # or (l.class.to_s.downcase==logic.downcase)}
                # (l.class.to_s.downcase==logic.downcase)}
                logic.do_removed if logic.respond_to?(:do_removed)
                logic.inform(self,logic.removed) if logic.respond_to?(:removed)
            else
                raise "#{logic} does not belong to this entity #{self}"
            end
        end
    end

    def find_logic_by_name(name)
        find_logic(name.downcase)
    end
    def find_logic_by_type(klass)
        find_logic(klass.class.to_s.downcase)
    end
    def do_action(action)
        @logic||=[]
        $evt_log.info("Entity(#{name}) wants to do => #{action}")
        @logic.each do |logic|
            begin
                # $evt_log.debug("Will #{logic} handle #{action}?")
                break if not logic.do_action(action)
            rescue => e
                $log.error("#{logic} threw exception #{e} while doing #{action}")
            end
        end
    end

    # could pass in "what" to notify
    # then observers could compare themselves
    # to "what" to determine if they need to invalidate
    def clear_timers 
        $evt_log.info("#{self} wants to clear (#{self.count_observers}) timers")
        changed
        notify_observers(self)
    end

    def kill_all_timers
        @logic||=[]
        @logic.each do |logic|
            $log.debug("clear #{logic} respond? #{logic.respond_to?(:clear_timers)}")
            logic.clear_timers if logic.respond_to?(:clear_timers)
        end
        # clear_timers
    end

    def logics
        @logic
    end
private
    def find_logic(logicname)
        @logic||=[]
        @logic.find{|logic|
            logic.class.to_s.downcase==logicname
        }
    end
end
