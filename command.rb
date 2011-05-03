# file:: command.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

class UsageException < RuntimeError
end

class Command
    attr_accessor :name,:usage,:description
    def initialize(char,name,usage,desc)
        @character,@name,@usage,@description=char,name,usage,desc
    end
    def execute(params)
        raise NoSuchMethodError("execute Not Implemented")
    end
protected
    attr_accessor :character

    def inform(string)
        self.character.do_action(Action.new(:announce,self.character,
        {:msg => string+EOL}))
    end
end
