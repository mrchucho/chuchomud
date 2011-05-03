# file:: character.rb
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

class CharacterTemplate < Entity
    include DataEntity
    attr_accessor :commands,:logics,:playable
    def playable?
        @playable||=false
    end
end

class Character < LogicEntity
    include DataEntity,HasRoom,HasRegion,HasTemplateID,HasItems

    attr_accessor :last_command,:quiet,:verbose,:account,:logged_in,
        :rank

    def initialize
        @account = nil
        @logged_in = false
        @quiet = false
        @verbose = true
        @commands = []
        @rank = 1
        super
    end

    def quiet?
        @quiet
    end
    def verbose?
        @verbose
    end
    def logged_in?
        @logged_in
    end

    def add
        self.region.add_character(self) if self.logged_in?
        self.room.add_character(self) if self.logged_in?
    end

    def remove
        self.region.del_character(self) if self.region
        self.room.del_character(self) if self.room
    end

    def load
        if not player? or logged_in? then
            remove
        end
        # load or maybe, yield
        if not player? or logged_in?
            add
        end
    end

    def load_template(template)
        self.template_id=template.oid
        self.name=template.name.dup
        self.description=template.description.dup
        self.attributes=template.attributes.dup
        self.commands=template.commands.dup if template.commands
        template.logics.each do |logic|
            self.add_logic($logic_db.generate(logic,self))
        end if template.logics
    end

    def find_command(cmd)
        cmd_name = @commands.find do |c|
            # c.name == cmd if c
            c == cmd if c
        end
        if cmd_name then
            $command_db.generate(cmd_name,self)
        end
    end

    def add_command(cmd)
        unless find_command(cmd)
            # c = $command_db.generate(cmd,self)
            # commands << c if c
            @commands << cmd if cmd
        end
    end

    def del_command(cmd)
        @commands.delete_if do |c|
            c == cmd
        end
    end

    def commands
        @commands.collect do |cmd|
            $command_db.generate(cmd,self)
        end
    end

    def player?
        @account!=nil
    end

    alias_method :all_attributes,:attributes
    def attributes
        # show only the "visible" ones... er, something
        all_attributes
    end
end
