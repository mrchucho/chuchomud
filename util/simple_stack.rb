# file:: simple_stack.rb
# author::  Ralph M. Churchill
# version::
# date::
#
# This source code copyright (C) 2006 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

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

