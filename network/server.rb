# file:: server.rb
# author::  Ralph M. Churchill
# version::
# date::
#
# This source code copyright (C) 2006 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.
require 'network/listener'

class MUDServer
    attr_accessor :connections

    def initialize(port=4000,*args)
        @port = port
        self.connections = []
    end

    def startup(engine)
        @listener = Listener.new(self,@port)
        raise "Error Starting Server!" unless @listener.start
        @listener.add_observer(engine) # to notify of
    end
    def shutdown
        self.connections.each{|c| c.closing=true}
        @listener.unsubscribe_all unless @listener.nil?
    end
    def poll(timeout)
        input,output,error=[],[],[]
        self.connections.each do |conn|
            input << conn.socket if conn.readable?
            output << conn.socket if conn.writable?
        end
        input,output = select(input,output,error,timeout)
        self.connections.each do |conn|
            conn.handle_input if input and input.include?(conn.socket)
            conn.handle_output if output and output.include?(conn.socket)
            conn.handle_close if conn.closing
        end
    rescue
        $stderr.puts $!
        raise
    end
end
