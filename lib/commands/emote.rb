# file:: emote.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

class Emote < Command
    def initialize(char)
        super(char,'emote','emote <verb phrase>',
        'Perform a superfluous action.')
    end
    def execute(args)
        raise UsageException if not args or args.empty?
        $game.do_action(Action.new(:vision ,self.character.room,
            {:sight => "#{BOLD}#{self.character}#{RESET} #{args.join(' ')+EOL}"}))
    end
end
