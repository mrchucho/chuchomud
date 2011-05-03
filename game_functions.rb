# file:: game_functions.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

# This module holds all of the "engine" code that is separate from the plumbing
# code (responsible for "running" the game"
module GameFunctions
    # Parse user input and do one of the following:
    # 1. if the input is /  then repeat the last command
    # 1. if the input is '  then treat as "say"
    # 1. if the input is me then treat as "emote"
    # Then strip off the leading slash, split the args and remember the command
    # [+char+]  Character performing the action
    # [+cmd_str+]   The user input
    def do_command(char,cmd_str)
        case cmd_str
        when /^\/(\s)*$/
            cmd_str = char.last_command 
        when /^'/
            cmd_str.insert(0,'say ').sub!(/'/,'')
        when /^me/
            cmd_str.sub!(/me/,'emote')
        end

        char.last_command=cmd_str

        cmd = cmd_str.split[0]
        args = cmd_str.split[1..-1]
        if command = char.find_command(cmd.sub(/^\//,'')) then
            begin
                command.execute(args)
            rescue UsageException
                char.do_action(Action.new(:error,char,
                    {:msg => "Usage: #{command.usage}"}))
            rescue => e
                $stderr.puts("#{command.name} failed to execute: #{e}")
            end
        else
            char.do_action(Action.new(:error,char,
                {:msg => "Unrecognized command: #{cmd}"}))
        end
    end

    # Manage a player's "login". Add the character to the region and room and
    # send "enter" messages.
    # [+char+]  Character performing the action
    def login(char)
        char.logged_in=true

        region = char.region
        room = char.room

        region.add_character(char)
        room.add_character(char)
        @players << char

        @players.each do |p|
            p.do_action(Action.new(:enterrealm,char))
        end
        enterreg = Action.new(:enterregion,char)
        region.do_action(enterreg)
        char.do_action(enterreg)

        enterroom = Action.new(:enterroom,char,{:room => room})
        ([room]+room.characters+room.items+char.items).each do |r|
            r.do_action(enterroom) if r
        end
    end

    # Manage's a player's "logout". Send "leave" messages, kill all
    # associated timers and write the player to the database.
    # [+char+]  Character performing the action
    def logout(char)
        region = char.region
        room = char.room

        enterroom = Action.new(:leaveroom,char,{:room => room})
        ([room]+room.characters+room.items+char.items).each do |r|
            r.do_action(enterroom)
        end

        enterreg = Action.new(:leaveregion,char)
        region.do_action(enterreg)
        char.do_action(enterreg)

        @players.each do |p|
            p.do_action(Action.new(:leaverealm,char)) # unless p==char
        end

        region.del_character(char)
        room.del_character(char)

        # #####################################################
        # Clear all the timed actions associated with Character
        # #####################################################
        char.kill_all_timers

        @players.delete(char)

        char.logged_in=false
        
        $character_db.save_player(char)
    end

    # The game mechanic for speech
    # [+char+]  Character performing the action
    # [+msg+]   What the character is attempting to say
    # == Messages
    # [cansay]  Query
    # [say]     The actual speech
    def say(char,msg)
        room = char.room
        region = char.region

        act = Action.new(:cansay,char,{:msg => msg})
        if char.do_action(act) and
            (room.do_action(act) if room) and
            (region.do_action(act) if region) then
            says = Action.new(:say,char,{:msg => msg})
            $log.debug("#{char}'s (#{char.object_id}) room, #{room}, has #{room.characters.size} occupants")
            room.characters.each do |c|
                c.do_action(says) # if c.valid?
            end
            room.do_action(says)
            region.do_action(says)
        end
    end

    # The game mechanic for looking at an object.
    # [+char+]  Character performing the action
    # [+target+]   What the character is attempting to look at
    # == Messages
    # [canlook] Query
    # [see]     What the player sees
    # [announce] If the player looks at another player, inform them
    # [error]   Error
    def look(char,target)
        room = char.room
        region = char.region

        act = Action.new(:canlook,char,{:target => target})
        if char.do_action(act) and
            (room.do_action(act) if room) and
            (region.do_action(act) if region) then

            if (not target) or target.empty? then
                what = room
            else
                what = (room.characters+room.items+room.portals).find do |e|
                    e.named?(target)
                end
            end
            if what then
                char.do_action(Action.new(:see,char,{:target => what}))
                if what.kind_of?(Character) then
                    what.do_action(Action.new(:announce,what,
                    {:msg => "#{char.name} looks at you."}))
                end 
            else
                char.do_action(Action.new(:error,char,
                {:msg => "You don't see any #{target} here."}))
            end
        end
    end

    # The game mechanic for using a Usable Item
    # [+char+]  Character performing the action
    # [+item+]  The Item the character is attempting to use
    # == Messages
    # [canuseitem]  Query
    # [useitem]     Tell the item to do whatever it does
    # [itemused]    After the item has done its thing, send a message
    def use_item(char,item)
        room = char.room
        region = char.region
        canuse = Action.new(:canuseitem,char,{:item => item})
        if char.do_action(canuse) and
            item.do_action(canuse) and
            room.do_action(canuse) and
            region.do_action(canuse) then

            item.do_action(Action.new(:useitem,char,
                                      {:item => item}))
            $log.info("#{char} uses #{item}")
            itemused = Action.new(:itemused,char,
                                      {:item => item})
            ([char]+[item]).each{|e| e.do_action(itemused)}
        end
    end

    # The game mechanic for getting an item from someone or something, with an
    # option quantity.
    # [+char+]  Character performing the action
    # [+item+]  The Item the character is attempting to get
    # [+quantity+] The quantity of Item the character is getting, usually
    # defaulted to 1 by the Get command.
    # == Messages
    # [cangetitem]  Query
    # [getitem]     Take the item from someone/thing and give it to the player
    def get_item(char,item,quantity)
        room = char.room
        region = char.region

        # stability checks - print error messages
        return if char.room!=item.room or (not item.region or item.region.oid==0)
        return if item.many? and quantity < 1
        return if item.many? and quantity > item.quantity

        can = Action.new(:cangetitem,char,
            {:item => item, :quantity => quantity})
        if item.do_action(can) and
            room.do_action(can) and
            region.do_action(can) and
            char.do_action(can) then

            if (item.many? and quantity != item.quantity) and
                item.quantity - quantity > 0 then
                    newitem = $item_db.generate_copy(item)
                    newitem.quantity = item.quantity - quantity
                    item.quantity = quantity
                    room.add_item(newitem)
                    region.add_item(newitem)
                    $log.debug("Created remainder: #{newitem.inspect}")
            end

            room.del_item(item)
            region.del_item(item)
           
            item.character=char
            nowhere = Entity.new
            nowhere.oid = 0
            item.room=nowhere
            item.region=nowhere
            char.add_item(item)

            # notify
            did = Action.new(:getitem,char,can.data) # is this OK?
            room.do_action(did)
            item.do_action(did)
            room.characters.each do |c|
                c.do_action(did)
            end
            room.items.each do |i|
                i.do_action(did)
            end
            join_quantities(char,item)
        end
    end

    # The game mechanic for giving an item to someone or something. "Dropping"
    # an item is handled by _giving_ it to the current room.
    # In order to give an item to another player, the receiving player needs to
    # have Receiving[CanReceive.html] on.
    # [+from+]  The "giver"
    # [+to+]  The "receiver"
    # [+item+] What is being given...
    # [+quantity+]  ... and how many. Usually defaulted to 1 by the Give
    # command.
    # == Messages
    # [candropitem] Query if item can be given away
    # [canreceiveitem] Query if receiver can receive
    # [giveitem] Transfer the item from one entity to another
    def give_item(from,to,item,quantity)
        return unless (from.room == to or from.room = to.room)
        return unless item.character == from
        return if item.character!=from
        return if item.many? and quantity < 1
        return if item.many? and item.quantity < quantity

        candrop = Action.new(:candropitem,from,{:item => item,
            :quantity => quantity})
        canreceive = Action.new(:canreceiveitem,from,{:to => to,
            :item => item, :quantity => quantity})

        if item.do_action(candrop) and
            from.do_action(candrop) and
            item.do_action(canreceive) and
            to.do_action(canreceive) then

            if (item.many? and quantity != item.quantity) and
                item.quantity - quantity > 0 then
                    newitem = $item_db.generate_copy(item)
                    newitem.quantity = item.quantity - quantity
                    item.quantity = quantity
                    from.add_item(newitem)
                    $log.debug("Created remainder: #{newitem.inspect}")
            end

            from.del_item(item)
            case to
            when Character
                item.character = to
            when Room
                item.region = to.region
                item.room = to
                item.clear_char
                to.region.add_item(item)
            when Region
                item.region = to
                item.clear_char
            end
            to.add_item(item)

            gave = Action.new(:giveitem,from,
                {:to => to, :item => item, :quantity => quantity})
            ([from.room]+from.room.characters+from.room.items).each do |e|
                e.do_action(gave)
            end
            join_quantities(to,item)
        end
    end


    # This is the general game mechanic for movement. An entity is transported
    # from one place to another. 
    #
    # Locations are defined in a hierarchy where a Room
    # exists in a Region. Rooms are linked by a Portal
    # which can, in turn, link Regions.
    # 
    # If movement results in the changing of the character's Region, perform the
    # appropriate queries and actions, otherwise ignore.
    #
    # [+char+] The Character performing the action
    # [+room+] The character's destination, we already know the start
    # (char.room)
    # [+portal+] Movement is *generally* through a portal, except in cases of
    # teleportation, GMing, etc.
    # == Messages
    # [canleaveregion] Query
    # [canenterregion] Query
    # [canleaveroom] Query
    # [canenterroom] Query
    # [canenterportal] Query
    # [leaveregion] Leave the region
    # [leaveroom] Leave the room
    # [enterportal] Enter the portal
    # [enterregion] Arrive in the new region
    # [enterroom] Arrive in the new room
    def transport(char,room,portal=nil)
        oldroom = char.room
        oldregion = oldroom.region
        newregion = room.region

        changed_regions = oldregion.oid!=newregion.oid
        # ----------------------------------------
        # Verify: aka "Integrity Checking"
        # ----------------------------------------
        # none

        # ----------------------------------------
        # Query: aka "Ask Permission"
        # ----------------------------------------
        # query if it is possible
        if changed_regions then 
            canleaveregion = Action.new(:canleaveregion,char,
                {:region =>oldregion})
            canenterregion = Action.new(:canenterregion,char,
                {:region =>newregion})

            return unless oldregion.do_action(canleaveregion)
            return unless newregion.do_action(canenterregion)
            return unless char.do_action(canleaveregion)
            return unless char.do_action(canenterregion)
        end

        canleaveroom = Action.new(:canleaveroom,char,
            {:room => oldroom})
        canenterroom = Action.new(:canenterroom,char,
            {:room => room})
        return unless oldroom.do_action(canleaveroom)
        return unless room.do_action(canenterroom)
        return unless char.do_action(canleaveroom)
        return unless portal.do_action(
            Action.new(:canenterportal,char)) if portal
        return unless char.do_action(canenterroom)

        # ----------------------------------------
        # Perform: aka "Physical Movement"
        # ----------------------------------------
        # made it this far, do it
        if changed_regions then
            oldregion.delete_character(char)
            char._region= region
            newregion.add_character(char)
        end
        oldroom.del_character(char)
        char.room = room
        room.add_character(char)

        # ----------------------------------------
        # Notify Affected: aka "Notifications"
        # ----------------------------------------
        # notify those involved
        # how would this work with observable?
        # could I say char, action is :moved, notify observers?
        if changed_regions then
            leaveregion = Action.new(:leaveregion,char,
                {:region => oldregion})
            oldregion.do_action(leaveregion)
            char.do_action(leaveregion)
        end

        ([oldroom]+oldroom.characters+oldroom.items+[char]+char.items).each do |o|
            o.do_action(Action.new(:leaveroom,char,
                {:room => oldroom, :portal => portal}))
        end
        
        if portal then
            enterportal = Action.new(:enterportal,char,{:portal => portal})
            portal.do_action(enterportal)
            char.do_action(enterportal)
        end

        if changed_regions then
            enterregion = Action.new(:enterregion,char,
                {:region => region})
            oldregion.do_action(enterregion)
            char.do_action(enterregion)
        end

        ([room]+room.characters+room.items+char.items).each do |r|
            r.do_action(Action.new(:enterroom,char,
                {:room => room, :portal => portal})) if r
        end
        # etc. etc.

        # couldn't the Perform/Notify section be combined into
        # a single notification?
=begin
        changed
        notify_observers(Action.new(:charactermoved,
            {:character => char,:from => oldroom, :to => newroom }))

        # I could pass in :fromregion, :toregion
        # OR
        # create a different event
        # notify_observers(Action.new(:charactermovedregions,...
=end
        # ----------------------------------------
        # Cleanup
        # ----------------------------------------
    end

    # Creates an Item from an ItemTemplate in a Room or on a Character (i.e. in
    # his or her inventory).
    # [+tid+] Item Template ID
    # [+where+] Room or Character in/on which the item should spawn
    def spawn_item(tid,where)
        item = $item_db.generate(tid)
        inform = []
        case where
        when Character
            item.character=where
        when Room
            item.region=where.region
            item.room=where
            item.clear_char
            where.region.add_item(item)
            inform << where.region
        end
        where.add_item(item)
        inform << where

        spawn = Action.new(:spawnitem,item)
        inform.each do |who|
            who.do_action(spawn)
        end
    end

    # Creates a Character from a CharacterTemplate in a Room
    # [+tid+] Character Template ID
    # [+where+] Room in which the Character should spawn
    def spawn_char(tid,where)
        char = $character_db.generate(tid)
        $log.debug("spawned #{char.inspect}")
        char.room=where
        char.region=where.region
        where.add_character(char)
        where.region.add_character(char)

        spawn = Action.new(:spawnchar,char)
        where.do_action(spawn)
        where.region.do_action(spawn)
    end

    # Utility function for handling quantities of items. For example, if a
    # character only picked up 1 coin, but already had 9 in his or her
    # inventory. This works, too, when quantity items are dropped.
    # [+entity+]    The entity picking up the quantity of item
    # [+item+] The item being picked-up or dropped (i.e. joined)
    def join_quantities(entity,item)
        return unless item.many?
        dups = entity.items.find_all do |i|
            i.template_id==item.template_id and i.oid!=item.oid
        end
        item.quantity = dups.inject(item.quantity){|sum,i| sum + i.quantity}
        dups.each{|d| delete_item(d)}
    end

    # Utility function for deleting an item from the game
    # [+item+] The Item to delete
    def delete_item(item)
        item.region.del_item(item) if item.region
        item.room.del_item(item) if item.room
        item.character.del_item(item) if item.character
        item.clear_timers
        $item_db.erase(item)
    end
end
