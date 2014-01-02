# file:: database.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

require 'yaml'

require 'character'
require 'item'
require 'region'
require 'room'
require 'portal'
require 'account'

class Database 
    include Enumerable

    def initialize(container)
        @container = container
    end

    def each
        @container.each do |e|
            yield e
        end
    end

    def find_name(name)
        find do |v|
            v.named?(name) if (v and v.respond_to?(:named?))
        end
    end
    def get(id)
        @container[id]
    end
    def size
        @container.size # ??
    end
    # ===============================
    # Load/Save to Filesystem
    # ===============================
    def load_entity(file)
        # add(YAML::load(file))
        entity = YAML::load(file)
        entity.loaded if entity and entity.respond_to?(:loaded)
        add(entity)
    end
    def load_directory(dir)
        Dir.glob(dir+File::SEPARATOR+'*.yaml') do |filename|
            load_file(filename)
            # or
            # yield load_file(filename)
        end
    end
    def load_file(filename)
        begin
            File.open(filename,'r') do |file|
                contents = YAML::load(file)
                if contents.respond_to?(:each) then
                    contents.each do |entity|
                        entity.loaded if entity and entity.respond_to?(:loaded)
                        add(entity)
                    end
                else
                    add(contents)
                end
            end
        rescue => e
            $stderr.puts("Error opening #{filename}: #{e}")
        end
    end
    def save_file(filename,entity)
        temp = "#{filename}.tmp"
        begin
            File.open(temp,'w') do |file|
                save_entity(file,entity)
            end
            File.rename(temp,filename)
        rescue => e
            $stderr.puts("Error saving #{filename}: #{e}; Saved temp file: #{temp}.")
        end
    end
private
    def save_entity(file,entity,remove_nulls=false)
        if entity.respond_to?(:each) and remove_nulls then
            entity.reject!{|ele| ele==nil}
        end
        # YAML::dump(entity,file)
        entity.saved if entity and entity.respond_to?(:saved)
        YAML::dump(entity,file)
    end
end

class VectorDatabase < Database
    def initialize
        super(Array.new)
    end
    def find_open_id
        if @container.empty? then
            0
        else
            @container[size-1].oid + 1
        end
    end
    def add(entity)
        entity.add if entity.respond_to?(:add)
        @container[entity.oid] = entity
    end
end

class MapDatabase < Database
    def initialize
        super(Hash.new)
    end
    def find_open_id
        if @container.empty? then
            1
        else
            @container.keys.max + 1
        end
    end
    def add(entity)
        entity.add if entity.respond_to?(:add)
        @container[entity.oid] = entity
    end
    def erase(id)
        @container.delete(id)
    end
=begin
    def each
        @container.each do |k,v|
            yield v
        end
    end 
    def load_file(filename)
        begin
            File.open(filename,'r') do |file|
                contents = YAML::load(file)
                contents.each do |oid,entity|
                    add(oid,entity)
                end
            end
        rescue => e
            $stderr.puts("Error opening #{filename}: #{e}")
        end
    end
=end
end

class TemplateInstanceDatabase
    include Enumerable

    def initialize
        @instances = MapDatabase.new()
        @templates = VectorDatabase.new()
    end
    def each
        @instances.each do |k,v|
            yield v
        end
    end
    def find_template(t)
        @templates.find{|e| e.named?(t) if e}
    end

    def get(id)
        @instances.get(id)
    end

    def erase(e)
        @instances.erase(e)
    end

    def valid?(entity)
        include?(entity)
    end

    def load_entity_template(file)
        @templates.load_entity(file)
    end
=begin
    def save_entity_template(file,entity)
        @templates.save_entity(file,entity)
    end
=end
    def load_entity(file)
        @instances.load_entity(file)
    end
    def get_template(id)
        @templates.get(id)
    end
    def generate(tmpl)
        id = @instances.find_open_id
        e = create(id) # instantiate a new object of type instance
        @instances.add(e)
        e.load_template(@templates.get(tmpl)) # copy over stuff from template
        e # id # I assume this ID matches the template just loaded
    end
    def generate_copy(entity)
        new = entity.dup
        new.oid = @instances.find_open_id
        @instances.add(new)
        new
    end
    def load_file(file)
        @instances.load_file(file)
    end
    def save_file(filename,entity)
        @instances.save_file(filename,entity)
    end
    def templates
        @templates
    end
end

class CharacterDatabase < TemplateInstanceDatabase
    CHAR_DIR = "#{ChuchoMUDConfig.instance.module_directory}/players".gsub!('/',File::SEPARATOR)
    CHAR_TEMPLATE_DIR = "#{ChuchoMUDConfig.instance.module_directory}/templates/characters".gsub!('/',File::SEPARATOR)

    def has_name?
    end
    def find_player(name,part=true)
        find do |e|
            e.named?(name)
        end
    end
    def save_player(char)
        begin
            $item_db.save_file(CHAR_DIR+File::SEPARATOR+"#{char.name.downcase}.items.yaml",
                char.items)
            save_file(
                 CHAR_DIR+File::SEPARATOR+"#{char.name.downcase}.yaml",char)
        rescue => e
            $stderr.puts("Error saving #{char.name.downcase}: #{e}")
        end
    end
    def save_players
        self.each do |char|
            save_player(char) if char.player?
        end
    end
    def load_players
        re = /\.items\./
        Dir.glob(CHAR_DIR+File::SEPARATOR+'*.yaml') do |filename|
            $item_db.load_file(filename) if re.match(filename)
        end
        Dir.glob(CHAR_DIR+File::SEPARATOR+'*.yaml') do |filename|
            @instances.load_file(filename) if not re.match(filename)
        end
    end
    def load_templates
        @templates.load_directory(CHAR_TEMPLATE_DIR)
    end
    def load_template(template)
        @templates.load_file(CHAR_TEMPLATE_DIR+File::SEPARATOR+"#{template}.yaml")
    end
    def load_player(player)
        $item_db.load_file(CHAR_DIR+File::SEPARATOR+"#{player.downcase}.items.yaml")
        @instances.load_file(CHAR_DIR+File::SEPARATOR+"#{player.downcase}.yaml")
    end

    def create(id)
        char = Character.new unless char = @instances.get(id)
        char.oid = id
        char
    end
end

class ItemDatabase < TemplateInstanceDatabase
    ITEM_TEMPLATE_DIR = "#{ChuchoMUDConfig.instance.module_directory}/templates/items".gsub!('/',File::SEPARATOR)
    def load_templates
        @templates.load_directory(ITEM_TEMPLATE_DIR)
    end
    def load_template(filename)
        @templates.load_file(ITEM_TEMPLATE_DIR+File::SEPARATOR+filename)
    end
    def create(id)
        item = Item.new unless item= @instances.get(id)
        item.oid = id
        item
    end
end

class RoomDatabase < VectorDatabase
end

class PortalDatabase < VectorDatabase
end

class RegionDatabase < VectorDatabase
    REGION_DIR = "#{ChuchoMUDConfig.instance.module_directory}/regions".gsub!('/',File::SEPARATOR)

    def load_all
        # each region is its own subdir
        Dir.glob(REGION_DIR+File::SEPARATOR+'*') do |dir|
            reg = dir[dir.rindex(File::SEPARATOR)+1..-1]
            Dir.glob(dir+File::SEPARATOR+reg+'.yaml') do |file|
                $stdout.puts("Loading #{file} from #{dir}")
                load_region(dir,file)
            end
        end
    end
    def load_region(dir,name)
        File.open(name,'r') do |file|
            load_entity(file)
        end
        # disk_name
        $room_db.load_file(dir+File::SEPARATOR+'rooms.yaml')
        $portal_db.load_file(dir+File::SEPARATOR+'portals.yaml')
        $character_db.load_file(dir+File::SEPARATOR+'characters.yaml')
        $item_db.load_file(dir+File::SEPARATOR+'items.yaml')
    end

    def save_region(region)
        rdir = REGION_DIR+File::SEPARATOR+region.disk_name

        save_file(rdir+File::SEPARATOR+"#{region.disk_name}.yaml",region)

        $room_db.save_file(rdir+File::SEPARATOR+'rooms.yaml',region.rooms)
        $portal_db.save_file(rdir+File::SEPARATOR+'portals.yaml',region.portals)
        $character_db.save_file(rdir+File::SEPARATOR+'characters.yaml',
            region.characters.select{|c| not c.player? })
        $item_db.save_file(rdir+File::SEPARATOR+'items.yaml',region.items)
    end
    def save_all
        @container.each do |region|
            save_region(region) if region
        end 
    end
end

require 'command'
class CommandDatabase
    # need to make this an array !!!
    COMMANDS_DIR = "lib/commands/".gsub!('/',File::SEPARATOR)
    def initialize
        $stdout.puts(" **** CommandDatabase needs to be load ALL ***** ")
	File.open(COMMANDS_DIR+'commands.yaml') do |file|
        	@sym_table = YAML::load(file)
	end
    end
    def load_all
        Dir.glob(COMMANDS_DIR+'*.rb') do |cmd|
            $stdout.puts("Loading Command #{cmd}")
            load(cmd)
        end
    end
    def generate(cmd,char)
        # $stdout.puts(@sym_table)
        inst = Object.const_get(@sym_table[cmd])
        if inst then
            inst.new(char) 
        end
    end
    def give_commands(char)
        @sym_table.keys.each do |name|
            inst = Object.const_get(@sym_table[name])
            if inst and not (inst.const_defined?('RANK') and
                inst::RANK > char.rank) then
                char.add_command(name)
            end
        end
    end
end

class LogicDatabase
    # ---- need to fix this =( ------
    LOGICS_DIR = 'lib/logic/'.gsub!('/',File::SEPARATOR)
    def initialize
    end
    def load_all
        Dir.glob(LOGICS_DIR+'*.rb') do |logic|
            $stdout.puts("Loading Logic #{logic}")
            load(logic)
        end
    end
    def generate(logic,entity)
        inst = Object.const_get(logic)
        inst.new(entity) if inst
    end
end

class AccountDatabase < VectorDatabase
    def load_all
        load_file(ChuchoMUDConfig.instance.module_directory.join("accounts.yaml"))
    end
    def save_all
        save_file(ChuchoMUDConfig.instance.module_directory.join('accounts.yaml'),@container)
    end
    def create(name,pass)
        oid = find_open_id
        acct = Account.new
        acct.oid,acct.name,acct.password=oid,name,pass
        acct.login_time = $game.time
        acct
    end
    def acceptable_name?(name)
        true
    end
end
