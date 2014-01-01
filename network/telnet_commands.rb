# file:: telnet_commands.rb
# author::  Ralph M. Churchill
# version::
# date::
#
# This source code copyright (C) 2006 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

module TelnetCommands
    RESET = "\x1B[0m";
    BOLD = "\x1B[1m";
    DIM = "\x1B[2m";
    UNDER = "\x1B[4m";
    REVERSE = "\x1B[7m";
    HIDE = "\x1B[8m";

    CLEARSCREEN = "\x1B[2J";
    CLEARLINE = "\x1B[2K";

    BLACK = "\x1B[30m";
    RED = "\x1B[31m";
    GREEN = "\x1B[32m";
    YELLOW = "\x1B[33m";
    BLUE = "\x1B[34m";
    MAGENTA = "\x1B[35m";
    CYAN = "\x1B[36m";
    WHITE = "\x1B[37m";

    BBLACK = "\x1B[40m";
    BRED = "\x1B[41m";
    BGREEN = "\x1B[42m";
    BYELLOW = "\x1B[43m";
    BBLUE = "\x1B[44m";
    BMAGENTA = "\x1B[45m";
    BCYAN = "\x1B[46m";
    BWHITE = "\x1B[47m";

    EOL = "\r\n\x1B[0m";
end
