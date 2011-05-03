# file:: admincommands.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

class SpawnItem < Command
    RANK = 2 # ADMIN or something
    def initialize(char)
        super(char,'spawnitem','spawnitem <item template id>',
        'Spawn a new item in your inventory.')
    end
    def execute(args)
        raise UsageException if args.empty?
        template = args.join
        case template
        when /\d/
            tid = template.to_i
        when /\w/
            if tmpl = $item_db.find_template(template) then
                tid = tmpl.oid
            else
                inform("Template: #{template} not found.")
                return
            end
        end
        $game.do_action(Action.new(:spawnitem,self.character,
        { :item => tid, :where => self.character }))
        inform("Spawned #{tid} in your inventory.")
    end
end

class DeleteItem < Command
    RANK = 2
    def initialize(char)
        super(char,'deleteitem','deleteitem <item>',
        'Delete an item from current room.')
    end
    def execute(args)
        raise UsageException if args.empty?
        itm = args.join
        item = self.character.room.items.find{|i| i.named?(itm)}
        return unless item
        $game.do_action(Action.new(:deleteitem,self.character,
        { :item => item}))
        inform("Deleted #{item}.")
    end
end

class SpawnCharacter < Command
    RANK = 2 # ADMIN or something
    def initialize(char)
        super(char,'spawnchar','spawnchar <char template id>',
        'Spawn a character in your room.')
    end
    def execute(args)
        raise UsageException if args.empty?
        template = args.join
        case template
        when /\d/
            tid = template.to_i
        when /\w/
            if tmpl = $character_db.find_template(template) then
                tid = tmpl.oid
            else
                inform("Template: #{template} not found.")
                return
            end
        end
        $game.do_action(Action.new(:spawncharacter,self.character,
        { :character => tid, :where => self.character.room }))
        inform("Spawned #{tid} in #{self.character.room}.")
    end
end

class ModLogic < Command
    def initialize(char,cmd,usage,desc)
        super(char,cmd,usage,desc)
    end
    def execute(args)
        raise UsageException if args.empty? or args.size < 3
        logic,who,type,where=args
        where||='room'

        entity = find_entity(self.character,
            where,Object.const_get(type)){|ent| ent.named?(who)}

        if (not entity or entity.empty?) then
            msg = "#{who} not found"
        elsif entity.length > 1
            msg = "#{who} is ambiguous"
        else
            entity = entity[0]
=begin
            begin
                if logic = $logic_db.generate(logic,entity) then
                    yield entity,logic
                    msg = "Success"
                else
                    msg = "logic \"#{logic}\" not found"
                end
            rescue Exception => e
                # incase I want to have init throw a TypeException
                msg = "Error: #{e}"
            end
=end
            msg = yield entity,logic
        end
        self.inform(msg)
    end
end

class AddLogic < ModLogic
    RANK = 2 # ADMIN or something
    def initialize(char)
        super(char,'addlogic',"addlogic <logicname> <name> \
<type=Character|Item|Room|Region|Portal> [where=self|room|region]",
        'Add a logic module to an entity')
    end
    def execute(args)
        super {|entity,logicname|
            begin
                if logic = $logic_db.generate(logicname,entity) then
                    entity.add_logic(logic)
                    "Success"
                else
                    "logic \"#{logic}\" not found"
                end
            rescue Exception => e
                # incase I want to have init throw a TypeException
                "Error: #{e}"
            end
        }
    end
end

class DelLogic < ModLogic
    RANK = 2 # ADMIN or something
    def initialize(char)
        super(char,'dellogic',"dellogic <logicname> <name> \
<type=Character|Item|Room|Region> [where=self|room|region]",
        'Delete a logic module from an entity')
    end
    def execute(args)
        super {|entity,logicname|
            begin
                if logic = entity.find_logic_by_name(logicname) then
                    entity.del_logic(logic)
                    "Success"
                else
                    "logic \"#{logic}\" not found"
                end
            rescue Exception => e
                # incase I want to have init throw a TypeException
                "Error: #{e}"
            end
        }
    end
end

class Save < Command
    RANK = 2 # ADMIN or something
    def initialize(char)
        super(char,'save','save [database]',
        'Save a particular database or all (default).')
    end
    def execute(args)
        if not args or args.empty? then
            msg = "Saved Game"
            $game.save_all
        else
            case args[0]
            when /region/i
                if region = $region_db.find{|r| r.named?(args[1]) if r} then
                    $region_db.save_region(region)
                    msg = "Saved Region #{region}"
                else
                    msg = "Region #{args[1]} not found"
                end
            when /player/i
                $character_db.save_players
                msg = "Saved Players"
            else
                msg = "Save What?"
            end
        end
        self.inform(msg)
    end
end

class Reload < Command
    RANK = 2 # ADMIN or something
    def initialize(char)
        super(char,'reload','reload <database>',
        'Reload a particular database.')
    end
    def execute(args)
        raise UsageException if not args or args.empty?
        case args[0]
        when /region/i
            if region = $region_db.find{|r| r.named?(args[1]) if r} then
                msg = "(Did not) Loaded Region #{region}"
            else
                msg = "Region #{args[1]} not found"
            end
        when /character/i
            $character_db.load_templates
            msg = "Loaded Character Templates"
        when /item/i
            $item_db.load_templates
            msg = "Loaded Item Templates"
        when /logic/i
            $logic_db.load_all
            msg = "Loaded Logic"
        when /command/i
            $command_db.load_all
            # reassign all commands
            $character_db.each do |char|
                $command_db.give_commands(char) if char.player?
            end
            msg = "Loaded Commands"
        end
        self.inform(msg)
    end
end

class Visual < Command
    RANK = 1 # GOD
    def initialize(char)
        super(char,'visual','visual <vision>',
        'Show some text in a room.')
    end

    def execute(args)
        raise UsageException if not args or args.empty?
        $game.do_action(Action.new(:vision,self.character.room,
        { :sight => args.join(' ')+EOL}))
    end
end

class Analyze < Command
    RANK = 2
    def initialize(char)
        super(char,'analyze',
        'analyze <type=Character|Item|Room|Region|Portal> <entity>',
        'Show in-depth information about an entity.')
    end
    def execute(args)
        raise UsageException if not args or args.empty?
        type = args.shift
        who = args.join(' ')
        
        entity = find_entity(self.character,'region',
            Object.const_get(type)){|e| e.named?(who)}

        if (not entity or entity.empty?) then
            msg = "#{who} not found"
        elsif entity.length > 1
            msg = "#{who} is ambiguous"
        else
            entity = entity[0]
            msg = "
--------------------------------------------------------------------------------
 #{BOLD}#{entity} - Status#{RESET}
--------------------------------------------------------------------------------
 #{BOLD}Attributes#{RESET}
"
entity.attributes.each do |k,v|
    msg += " #{k} => #{v}#{EOL}"
end
            msg +="
 #{BOLD}Logic#{RESET}
"
entity.instance_variable_get("@logic").each do |l|
    msg += " #{l.to_s+EOL}"
end
    msg += "
--------------------------------------------------------------------------------
"
        end
        self.inform(msg)
    end
end

# Additional Commands:
=begin
add/del command
emulate
exec code
teleport
destroy item/char
=end
