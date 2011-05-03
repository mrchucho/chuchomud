# file:: bad.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

class Bad < Command
    def initialize(char)
        super(char,'test','test','test')
    end
    def execute(args)
        99/0
    end
end
