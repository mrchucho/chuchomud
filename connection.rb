# file:: connection.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

require 'observer'

class SimpleStack
    include Enumerable
    def initialize
        @stack = []
    end
    def top
        @stack[-1]
    end
    def push(v)
        @stack.push(v)
    end
    def pop
        @stack.pop
    end
    def empty?
        @stack.empty?
    end
    def each
        @stack.each{|e| yield e}
    end
end


class PlayerConnection
    include Observable
    def initialize(socket)
        @handlers = SimpleStack.new
        @socket = socket

        @socket.subscribe(self)
        add_observer(@socket)
    end

    def display(str)
        send_string(str+EOL)
    end
    def prompt(str)
        send_string(str)
    end
    def clear_screen
        send_string(CLEARSCREEN)
    end
    def send_string(str)
        changed
        notify_observers(str)
    end

    def update(data) # whenever we rcv from socket
        $log.debug("Connection wants #{@handlers.top} to handle => #{data}")
        case data
        when :disconnected
            close
        when :logged_out
            @handlers.top.leave if not @handlers.empty?
        when :initdone
            @handlers.top.handle('initdone') if not @handlers.empty?
        else
            if not data.kind_of?(String)
                $log.debug("Connection should #{data}")
            else
                @handlers.top.handle(data) if not @handlers.empty?
            end
        end
    end

	def switch_handler(handler)
		@handlers.top.leave if not @handlers.empty?
        @handlers.pop
		@handlers.push(handler)
		@handlers.top.enter
	end

    def add_handler(handler)
        # in my implementation, don't leave the handler
        # you are switching away from. only leave when
        # you are FINISHED with the hanlder
        # @handlers.top.leave if not @handlers.empty?
        @handlers.push(handler)
        @handlers.top.enter
    end

    def remove_handler
        return if @handlers.empty?
        @handlers.top.leave
        @handlers.pop
        @handlers.top.enter if not @handlers.empty?
    end
	
	def clear_handlers 
        until @handlers.empty?
            @handlers.pop.leave
        end
	end

	def close
        clear_handlers

        changed
        notify_observers(:logged_out)
	end
	
	def closed?
		@socket == nil
	end

    def _debug_handlers
        puts("-------")
        @handlers.each do |h|
            puts("#{h.class}")
        end
        puts("^^^^^^^")
    end
end
