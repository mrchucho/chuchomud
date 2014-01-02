# file:: config.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2006 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

require 'singleton'
require 'pathname'

class ChuchoMUDConfig
  include Singleton

  attr_accessor :module_name

  def module_directory
    @module_directory ||= Pathname.new(File.join('modules', self.module_name))
  end
end
