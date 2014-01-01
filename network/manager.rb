# file:: manager.rb
# author::  Ralph M. Churchill
# version::
# date::
#
# This source code copyright (C) 2006 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

require 'network/player_connection'
require 'handler'
require 'network/server'

class NetManager
    # [+engine+] Engine being managed
    # [+port+] Port on which to listen
    def initialize(engine,port)
        @engine = engine
        @server = MUDServer.new(port)
        @shutdown = false
    end

    # Management consists of periodically polling the incoming connected
    # sockets (@server.poll) and executing actions in the engine's queue
    # (@engine.execute_loop).
    def manage
        @server.startup(self)
        until @shutdown
            @server.poll(0.2)
            @engine.execute_loop
        end
        @server.shutdown
    end
    
    # Called whenever a new connection appears. Convert the socket
    # to a player connection, then turn over control to the Logon Handler.
    # [+new_connection+] a new, incoming connection (socket)
    def update(new_connection)
        c = PlayerConnection.new(new_connection)
        c.switch_handler(LogonHandler.new(c))
    end
end
