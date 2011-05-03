# file:: account.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

require 'entities'

# Every user has an Account which stores their password, rank, etc. An Account
# can have one or more Character.
class Account < Entity
    include HasCharacters

    attr_accessor :password,:login_time,:rank,:allowed_accounts,:logged_in

    def initialize
        @allowed_accounts = 3
        @logged_in = false
    end
end
