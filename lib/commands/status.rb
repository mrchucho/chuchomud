# file:: status.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

class Status < Command
    def initialize(char)
        super(char,'status','status',
        'Print character status info')
    end
    def execute(args)
        msg = "
--------------------------------------------------------------------------------
 #{BOLD}#{self.character} - Status#{RESET}
--------------------------------------------------------------------------------
"
self.character.attributes.each do |k,v|
    msg += "#{k} => #{v}#{EOL}"
end
    msg += "
--------------------------------------------------------------------------------
"
        self.inform(msg)
    end
end
