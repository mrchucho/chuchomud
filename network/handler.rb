# file:: handler.rb
# author::  Ralph M. Churchill
# version::
# date::
#
# This source code copyright (C) 2006 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

require 'util/connection_utils'
require 'network/telnet_commands'
require 'models/account'
require 'database/game_database'

# -------------------------------------------------------------------------
# Is there are way to do this with blocks, procs, continuations? Doesn't
# feel very Rubyish.
# -------------------------------------------------------------------------
# These *really* need test cases... but it's hard. Which makes me feel even
# more strongly that they are not very Rubyish.
# -------------------------------------------------------------------------
class LogonHandler
    def initialize(connection)
        @connection = connection
        @connection.extend ConnectionUtils

        @state = :init
        @account = nil
        @new_name = nil
    end

    def enter; end
    def leave; end
    def hang_up; end
    
    def handle(data)
        case @state
        when :init
            # return unless data==:initdone
            @connection.display("Welcome to #{TelnetCommands::BOLD+TelnetCommands::GREEN}Chucho MUD#{TelnetCommands::RESET}")
            @connection.prompt(
                "Please enter your name or \"new\" if you are new: ")
            @state = :entername
        when :entername
            if data == 'new' then
                @state = :enternewname
                @connection.prompt(
                    "Please enter your desired username: ")
            else
                if @account = AccountDatabase.instance.find_by_name(data)
                    @state = :enterpass
                    @connection.prompt("Password: ")
                else
                    @connection.display("#{data} not found.")
                    @connection.prompt(
                        "Please enter your name or \"new\" if you are new: ")
                end
            end
        when :enternewname
            begin
                name = Account.acceptable_name?(data)
                raise "\"#{data}\" is already taken." if AccountDatabase.instance.find_by_name(name)

                @state = :enternewpass
                @new_name = name
                @connection.prompt(
                    "Please enter your desired password: ")
            rescue => e
                @connection.display("\"#{data}\" is not acceptable: #{e}")
                @connection.prompt("Please enter another name: ")
            end
        when :enternewpass
            begin
                password=Account.acceptable_password?(data) 
                @connection.display("Account Accepted. Entering...")
                @account = Account.create({
                    :name => @new_name, :password => password}) 
                AccountDatabase.instance.add(@account)
                @new_name = nil
                show_menu
            rescue => e
                @connection.display("Password not accepted: #{e}")
            end
        when :enterpass
            if data == @account.password
                show_menu
            else
                @connection.display("Invalid Password!")
                @connection.prompt("Password: ")
            end
        end
    end

    def show_menu
        @state = nil
        @connection.switch_handler(MenuHandler.new(@account,@connection))
    end
end

MENU=<<EOH
--------------------------------------------------------------------------------
Welcome to #{TelnetCommands::BOLD}#{TelnetCommands::MAGENTA}Chucho MUD#{TelnetCommands::RESET}
--------------------------------------------------------------------------------
0 - Quit
1 - Enter Game
2 - Create New Character
3 - Delete Existing Character
4 - Help
--------------------------------------------------------------------------------
EOH
class MenuHandler
    def initialize(account,connection)
        @account,@connection=account,connection
    end
    def enter
        @account.logged_in = true
        @account.login_time = Time.now
        @connection.clear_screen
        @connection.prompt(MENU+"Choice: ")
    end
    def leave
        @account.logged_in = false
    end
    def hang_up; end
    
    def handle(data)
        case data
        when /0/
            @connection.close
        when /1/
            @connection.add_handler(EnterGameHandler.new(@account,@connection))
        when /2/
            if @account.characters.size >= @account.allowed_accounts
                @connection.prompt(
                    "Sorry, you are only allowed #{@account.allowed_accounts} characters.")
            else
                @connection.add_handler(NewCharacterHandler.new(@account,@connection))
            end
        else
            @connection.display("Unrecognized Option.")
            @connection.prompt(MENU+"Choice: ")
        end
    end
end

class NewCharacterHandler
    def initialize(account,connection)
        @account,@connection,@character=account,connection,nil
    end
    def enter
        @connection.prompt(
"--------------------------------------------------------------------------------
Please select a template:
--------------------------------------------------------------------------------
")
        CharacterDatabase.instance.templates.each do |tmpl|
            @connection.display(
                "#{tmpl.oid} - #{tmpl.name}: #{tmpl.description}") if tmpl.playable?
        end
        @connection.prompt(
"--------------------------------------------------------------------------------
Choice: ")
    end
    def leave; end
    def handle(data)
        @connection.del_handler if data=~/^0/

        if @char then
            begin
                name = Account.acceptable_name?(data) 
                raise "\"#{name}\" is already taken." if CharacterDatabase.instance.find{|c| c.named?(name)}

                @char.name = name
                @connection.del_handler
                return
            rescue => e
                @connection.display("\"#{data}\" is not acceptable: #{e}")
                @connection.prompt("Please enter another name: ")
            end
        else
            tmpl = CharacterDatabase.instance.get_template(data.to_i)
            if not tmpl
                @connection.prompt("Invalid option, please try again: ")
                return
            end

            @char = CharacterDatabase.instance.generate_from_template(tmpl)
            @char.account = @account
            @account.add_character(@char)
            setup_player
            @connection.prompt("Please enter your desired name: ")
        end
    end
private
    def setup_player
        @char.region = RegionDatabase.instance.min
        @char.room = RoomDatabase.instance.min
    end
end

class EnterGameHandler
    def initialize(account,connection)
        @account,@connection=account,connection
    end
    def enter
        @account.characters.each do |c|
            @connection.display("#{c.oid} - #{c.name}")
        end
        @connection.prompt('Choice: ')
    end
    def leave; end
    def handle(data)
        case data
        when /^0/
            @connection.del_handler
        else
            @player = @account.characters.find{|c| c.oid==data.to_i}
            if not @player 
                @connection.display("Invalid Character.")
                @connection.prompt("Choice: ")
            else
                @connection.clear_screen
                @connection.switch_handler(GameHandler.new(@player,@connection))
                update_player
            end
        end
    end
private
    def update_player
        CommandDatabase.instance.give_commands_to_player(@player)
    end
end

class GameHandler
    require 'engine/action'
    require 'logic/telnet_reporter'
    def initialize(player,connection)
        @player,@connection=player,connection
    end
    def enter
        @player.add_logic(TelnetReporter.new(@player,@connection))
        GameEngine.instance.do_action(Action.new(:enterrealm,@player))
    end
    def leave
        GameEngine.instance.do_action(Action.new(:leaverealm,@player))
        @player.del_logic(TelnetReporter)
    end
    def handle(data)
        GameEngine.instance.do_action(
            Action.new(:command,@player,{:data => data}))
    end
end
