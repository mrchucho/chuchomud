# file:: basic_timer.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

# A not-particularly-fine-grained timer object :)
# * Resettable
# * Can pretty-print (with ::digital)
class Timer
    def initialize
        @start = 0
        @init = 0
    end

    def reset(time_passed)
        @start = time_passed
        @init = _ms
    end

    def ms
        (_ms-@init) + @start
    end

    def sec; ms / 1000; end
    def min; ms / 60000; end
    def hour; ms / 3600000; end
    def day; ms / 86400000; end
    def year; day / 365; end

    def to_s
        y=year
        d=day%365
        h=hour%24
        m=min%60

        "Years #{y} Days #{d} Hours #{h} Minutes #{m}"
    end
    # Show the time in a "readable" format.
    def digital
        y=year
        d=day%365
        h=hour%24
        m=min%60

        sprintf("%02d:%02d",h,m)
    end

    # Convenience routine for converting a time into digital(readable) format
    # [+t+] The time to convert
    def Timer.digital(t)
        tmp = Timer.new
        tmp.reset(t)
        tmp.digital
    end
private
    def _ms
        t = Time.now
        s = t.tv_sec
        s *= 1000
        s += (t.tv_sec/1000)
    end

end
