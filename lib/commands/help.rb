# file:: help.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

class Help < Command
    def initialize(char)
        super(char,'help','help [command]',
        'Print the list of commands or get help on a specific command.')
    end
    def execute(args)
        helpon = args.join(' ') if args
        if helpon and (not helpon.empty?) then
            if cmd = self.character.find_command(helpon) then
                msg = cmd.usage+EOL+cmd.description
            else
                msg = "No help available for \"#{helpon}\""
            end
        else
            msg=<<EOF
/ - repeat the last command
' - alias for "say"
me - alias for "emote"
EOF
            msg += self.character.commands.collect{
                |c| "#{BOLD+c.name+RESET} - #{c.description}"}.join(EOL)
        end
        self.inform(msg)
    end
end
