# file:: $Name$
# author::  $Author$
# version:: $Revision$
# date:: $Date$
#
# This source code copyright (C) 2006 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

# Just a clever util class to allow making paths:
# root/sub/file
# instead of:
# [root,sub,file].join(File::SEPARATOR)
# or:
# root+File::SEPARATOR+sub+File::SEPARATOR+file
class String
    def /(rhs)
        "#{self}#{File::SEPARATOR}#{rhs}"
    end
end
