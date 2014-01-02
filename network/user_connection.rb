# file:: user_connection.rb
# author::  Ralph M. Churchill
# version::
# date::
#
# This source code copyright (C) 2006 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

require 'observer'
require 'network/net_connection'

# An incoming connection from a potential user/player
class UserConnection < NetworkConnection
    include Observable
    def initialize(server,socket)
        super(server,socket)
        @io = SocketIO.new(@socket)
        @inputbuffer=@outputbuffer = ""
    end
    def start
        @host, @addr = @socket.peeraddr.slice(2..3)
        self.connected = true
        @server.connections << self
        true
    rescue Exception => e
        $stderr.puts "UserConnection error: #{e}"
        false
    end
    def handle_input
        buffer = @io.read
        raise EOFError if not buffer or buffer.empty?
=begin
        @inputbuffer << buffer# {{{
        while p = @inputbuffer.index("\n")
            ln = @inputbuffer.slice!(0..p).chop
            changed
            notify_observers(ln)
        end# }}}
=end
        changed
        notify_observers(buffer.chomp)
    rescue Exception => e
        $stderr.puts "Error: #{e}" unless e.kind_of?(EOFError)
        self.closing = true
        changed
        notify_observers(:disconnected)
        delete_observers
    end
    def handle_output
        done = @io.write(@outputbuffer)
        @outputbuffer = ""
        self.blocking = !done
    rescue Exception
        self.closing = true
        changed
        notify_observers(:disconnected)
        delete_observers
    end
    def handle_close
        self.connected = false
        changed
        notify_observers(:disconnected)
        delete_observers
        @server.connections.delete(self)
        @socket.close
    end
    def update(msg)
        case msg
        when :quit,:logged_out
            self.closing = true
        when String
            @outputbuffer << msg
            self.blocking = true
        when Symbol,Array
          $stderr.puts "Unhandled message type: #{msg.inspect}"
        else
            $stderr.puts "Unknown message: #{msg}"
        end
    end
end
