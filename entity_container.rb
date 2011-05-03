require 'character'
require 'room'
require 'item'
require 'portal'
require 'region'

# Anything that has an entity associated with it. HasEntity
# generalizes the accessor, so that any type of entity (e.g. Character,
# Room, Item) can be used.
module HasEntity
    def entity
        db = case @entity_type
            when Character.to_s
                $character_db
            when Room.to_s
                $room_db
            when Item.to_s
                $item_db
            when Portal.to_s
                $portal_db
            when Region.to_s
                $region_db
            else
                $stderr.puts("@{entity_type} not found")
                nil
            end
        if @entity_logic!=nil then
            db.get(@entity_id).find_logic_by_name(@entity_logic)
        else
            db.get(@entity_id)
        end
    end
    def entity=(entity)
        if entity.kind_of?(Logic) then
            @entity_type = entity.entity.class.to_s
            @entity_id = entity.entity.oid
            @entity_logic = entity.class.to_s
        else
            @entity_type = entity.class.to_s
            @entity_id = entity.oid
            @entity_logic = nil
        end
    end
end
=begin
    def performer=(p)
        room.char,item,region,logic,logic_owner=nil
        case p.kind
        when Room
            room = p.oid
        when Character
            char = p.oid
        when Logic,Effect
            logic = p.name
            logic_owner = p.entity # owner
    end

    def performer
        if logic!=nil then
            logic_owner.find_logic_by_type(logic)
        else 
            [room,char,item,region].find {|e| e!=nil}
        end
    end
=end
