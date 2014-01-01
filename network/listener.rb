# file:: listener.rb
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
require 'socket'
require 'fcntl'
require 'network/net_connection'
require 'network/user_connection'

class SocketIO
    def initialize(socket,buffsize=8192)
        @socket = socket
        @buffsize = buffsize
        @outputbuffer=""
    end
    def read
        @socket.recv(@buffsize)
    end
    def write(msg)
        @outputbuffer << msg
        n = @socket.send(@outputbuffer,0)
        @outputbuffer.slice!(0...n)
        @outputbuffer.size == 0
    end
end

# Accepts incoming connections
class Listener < NetworkConnection
    include Observable
    def initialize(server,port)
        @port = port
        super(server)
    end
    def start
        @socket = TCPServer.new('0.0.0.0',@port)
        @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
        unless RUBY_PLATFORM =~ /darwin/
            @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_LINGER, false)
        end
        unless RUBY_PLATFORM =~ /win32/
          @socket.fcntl(Fcntl::F_SETFL, Fcntl::O_NONBLOCK)
        end
        self.accepting = true
        @server.connections << self
        true
    rescue Exception => e
        $stderr.puts "Listener error: #{e}"
        false
    end

    def handle_input
        socket = @socket.accept
        if socket
            unless RUBY_PLATFORM =~ /win32/
                socket.fcntl(Fcntl::F_SETFL, Fcntl::O_NONBLOCK)
            end
            conn = UserConnection.new(@server,socket)
            if conn.start
                changed
                notify_observers(conn)
            end
        end
    end
    
    def handle_close
        self.accepting = false
        @server.connections.delete(self)
        @socket.close
    end
end

