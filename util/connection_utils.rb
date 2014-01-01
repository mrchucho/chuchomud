# file:: connection_utils.rb
# author::  Ralph M. Churchill
# version::
# date::
#
# This source code copyright (C) 2006 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

require 'network/telnet_commands'

module ConnectionUtils
    def display(str)
        send_string(str+TelnetCommands::EOL)
    end
    def prompt(str)
        send_string(str)
    end
    def clear_screen
        send_string(TelnetCommands::CLEARSCREEN)
    end
end
