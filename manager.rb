# file:: manager.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

require 'connection'
require 'handler'

$: << "vendor/teensymud"
require 'network/reactor'

class NetManager
    def initialize(port)
        @server = Reactor.new(port,:server,:sockio,[:zmp],[:telnetfilter])
        @shutdown = false
    end

    def manage
        @server.start(self) # actually, LogonHandler
        until @shutdown
            @server.poll(0.2)
            $game.execute_loop
        end
        @server.stop
    end

    def update(newconn)
        # take the connection, convert to our connection interface
        conn = PlayerConnection.new(newconn)
        conn.switch_handler(LogonHandler.new(conn))
    end
end
