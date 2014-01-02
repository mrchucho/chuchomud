# file:: player_connection.rb
# author::  Ralph M. Churchill
# version::
# date::
#
# This source code copyright (C) 2006 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

require 'util/simple_stack'
require 'observer'

class PlayerConnection
    include Observable

    def initialize(socket)
        @handlers = SimpleStack.new

        @socket = socket
        @socket.add_observer(self)
        add_observer(@socket)
    end

    # connection => socket
    # Route [+str+] to the attached socket.
    def send_string(str)
        changed
        notify_observers(str)
    end
    # socket => connection
    # Send [+data+] to the top handler to handle.
    # However, there are some Special Cases, handle those first.
    def update(data)
        case data
        when :disconnected
            close
        when :initdone
            @handlers.top.handle('initdone') if not @handlers.empty?
        when :logged_out
            @handlers.to.leave unless @handlers.empty?
        else
            @handlers.top.handle(data) unless @handlers.empty?
        end
    end

    # -------------------------------------------------------------------------
    # Is this hierarchy and it's management equivalent to Ruby's builtin
    # class/inheritence hierarchy? i.e. instead of pushing another handler
    # on top of the connection, could you just have the connection .extend
    # the next handler? I'm pretty sure there are hooks (would cover: enter, 
    # leave). The only question: can I go back (i.e. what's the opposite
    # of .extend)?
    # -------------------------------------------------------------------------
    def switch_handler(handler)
        @handlers.top.leave unless @handlers.empty?
        @handlers.pop
        add_handler(handler)
    end
    def add_handler(handler)
        @handlers.push(handler)
        @handlers.top.enter
    end
    def del_handler
        return if @handlers.empty?
        @handlers.top.leave
        @handlers.pop
        @handlers.top.enter unless @handlers.empty?
    end
    # FIXME for backwards compat.
    def remove_handler
      del_handler
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
end
