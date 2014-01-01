# file:: handler.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

require 'util/connection_utils'
require 'action'
require 'telnet_commands'

class LogonHandler
    def initialize(connection)
        @connection = connection
        @connection.extend ConnectionUtils
        @state = :init
    end
	def enter
	end
	
    def leave
    end
	def hang_up
	end

    def handle(data)
        case @state
        when :init
          # FIXME was this just a dependency of tmud?
            # return unless data == 'initdone'
            @connection.display("Welcome to Chucho MUD.")
            @connection.prompt(:echo)
            @connection.prompt(:zmp)
            @connection.prompt(:terminal)
            @connection.prompt(:termsize)
            @connection.prompt([:terminal,"xterm"])
            @connection.prompt("Please enter your name or \"new\" if you are new: ")
            @state = :entername
        when :entername
            if data =~ /new/ then
                # print the new account message
                @state = :enternewname
                # clear screen
                @connection.prompt(
                "Please enter your desired username: ")
            else
                if @account = $account_db.find_name(data) 
                    @state = :enterpass
                    # check if banned
                        # :enterdead
                    @connection.prompt("Password: ")
                    @connection.prompt([:hide,true])
                else
                    @connection.display("#{data} not found.")
                    @connection.prompt(
                    "Please enter your name or \"new\" if you are new: ")
                end
            end
        when :enternewname
            if $account_db.find_name(data) then
                @connection.display("Sorry, \"#{data}\" is already taken.")
                @connection.prompt("Please enter another name: ")
            elsif not $account_db.acceptable_name?(data) then
                @connection.display("Sorry, \"#{data}\" is not acceptable.")
                @connection.prompt("Please enter another name: ")
            else
                @state = :enternewpass
                @name = data
                @connection.prompt(
                "Please enter your desired password: ")
                @connection.prompt([:hide,true])
            end
        when :enternewpass
            # valid pass?
            @connection.display("Account Accepted. Entering...")
            @account = $account_db.create(@name,data)
            $account_db.add(@account)
            @name = nil
            menu 
        when :enterpass
            if data == @account.password
                menu
            else
                @connection.display("Invalid Password!")
                @connection.prompt("Password: ")
            end
        end
    end

    def menu
        @connection.prompt([:hide,false])
        @connection.switch_handler(MenuHandler.new(@account,@connection))
        @state = nil
    end
end

MENU=<<EOH
--------------------------------------------------------------------------------
Welcome to #{BOLD}#{MAGENTA}Chucho MUD#{RESET}
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
        @account,@connection = account,connection
    end

    def enter
        # handle already logged in
        @account.logged_in = true
        @connection.clear_screen
        @connection.prompt(MENU+"Choice: ")
    end
    def leave
        @account.logged_in = false
    end
    def handle(data)
        case data
        when /0/
            @connection.close
        when /1/
            @connection.add_handler(EnterGameHandler.new(@account,@connection))
        when /2/
            # check # chars
            @connection.add_handler(NewCharacterHandler.new(@account,@connection))
        when /3/
            # add menu delete
        when /4/
            @connection.add_handler(HelpHandler.new(@connection))
        else
            @connection.display("Unrecognized Option.")
            @connection.prompt(MENU+"Choice: ")
        end
    end
end

RACES=<<EOF
EOF
class NewCharacterHandler
    def initialize(account,connection)
        @account,@connection,@char = account,connection,nil
    end

    def enter
        # print templates
        @connection.prompt(
"--------------------------------------------------------------------------------
Please select a template:
--------------------------------------------------------------------------------
")
        $character_db.templates.each do |t|
            @connection.display(
            "#{t.oid} - #{t.name}: #{t.description}") if t and t.playable?
        end
        @connection.prompt(
"--------------------------------------------------------------------------------
Choice: ")

    end
    def leave
    end
    def handle(data)
        @connection.remove_handler if data=~/^0/

        if @char then
            if not $account_db.acceptable_name?(data) then
                @connection.display("Sorry, \"#{data}\" is not acceptable.")
                @connection.prompt("Please enter another name: ")
            elsif $character_db.find{|c|c.named?(data)} then
                @connection.display("Sorry, \"#{data}\" is already taken.")
                @connection.prompt("Please enter another name: ")
            else
                @char.name = data

                # go BACK to menu?
                @connection.remove_handler
                return
            end
        end

        @connection.remove_handler if data=~/0/

        tmpl = $character_db.get_template(data.to_i) # from list of races/templates
        if not tmpl
            @connection.prompt(
            "Invalid option, please try again: ")
            return
        end

        @char = $character_db.generate(data.to_i)
        @char.account = @account.oid
        @account.add_character(@char)
        setup(@char)
        @connection.prompt(
        "Please enter your desired name: ")
    end

    def setup(char)
        # could be moved to something fancier, but for now:
        $command_db.give_commands(char)
        char.room=$room_db.get(1)
        char.region=$region_db.get(1)
    end
end

class EnterGameHandler
    def initialize(account,connection)
        @account,@connection = account,connection
    end

    def enter
        @account.characters.each do |c|
            @connection.display("#{c.oid} - #{c.name}")
        end
        @connection.prompt("Choice: ")
    end
    def leave
    end
    def handle(data)
        case data
        when /^0/
            @connection.remove_handler
        else
            @player = @account.characters.find{|c| c.oid==data.to_i}
            if not @player then
                @connection.display("Invalid Character.")
                @connection.prompt("Choice: ")
            else
                @connection.clear_screen
                @connection.switch_handler(
                    GameHandler.new(@player,@connection))
                update_player
                update_from_template($character_db)
                # update_from_template($item_db)
            end
        end
    end

    def update_player
        $command_db.give_commands(@player)
    end

    def update_from_template(db)
        db.each do |c|
            if c == @player then
                template = db.get_template(c.template_id)
                (template.logics - c.logics).each do |l|
                    c.add_logic(
                        $logic_db.generate(l,c)) 
                end
                template.attributes.each do |k,v|
                    c[k] = v unless c.has_key?(k)
                end
            end
        end
    end
end

HELP=<<EOL
#{BOLD}Help#{RESET}
If you have not yet created a character, do so by selecting option #2. After you
create a character, select option #1 to enter the game. You will be presented
with a list of characters from which to choose. Enter a character's ID to begin 
the game!

Selecting "0" at any time will exit the current menu.
--- Press any key to continue ---
EOL
class HelpHandler
    def initialize(conn)
        @connection = conn
    end
    def enter
        @connection.display(HELP)
    end
    def handle(data)
        @connection.remove_handler
    end
    def leave;end;
end

class GameHandler
    def initialize(player,connection)
        @player,@connection = player,connection
    end

    def enter
        $evt_log.debug("GameHandler::enter")
        @player.add_logic(TelnetReporter.new(@player,@connection))
        $game.do_action(Action.new(:enterrealm,@player))
    end
     
	def leave
        $evt_log.debug("GameHandler::leave")
        $game.do_action(Action.new(:leaverealm,@player))
        tr = @player.find_logic_by_name("TelnetReporter")
        @player.del_logic(tr) if tr
	end

    def handle(data)
        $game.do_action(Action.new(:command,@player,
            { :data => data }))
    end
end
