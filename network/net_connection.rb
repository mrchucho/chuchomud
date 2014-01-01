# file:: net_connection.rb
# author::  Ralph M. Churchill
# version::
# date::
#
# This source code copyright (C) 2006 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

# Base Class for all network connections (in or out)
class NetworkConnection
    attr_reader :socket
    attr_accessor :accepting,:connected,:closing,:blocking
    def initialize(server,socket=nil)
        @server = server
        @socket = socket
        self.accepting=self.connected=self.closing=self.blocking=false
    end
    def start
        true
    end
    def handle_input
        put "#{self} not handling input"
    end
    def handle_output
        put "#{self} not handling output"
    end
    def handle_error
        put "#{self} not handling error"
    end

    def readable?
        self.connected or self.accepting
    end
    def writable?
        self.blocking
    end
    def closing?
        self.closing
    end
end


