# file:: bmud.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.
require 'rubygems'
require 'config'

require 'optparse'
require 'ostruct'
require 'strscan'

def handle_signal(sig)
    $stdout.puts("Handling #{sig}")
    finish
    exit
end

def finish
    $game.shutdown
    $game.save_all
    save_game
end

def load_game
    File.open(ChuchoMUDConfig.instance.module_directory+File::SEPARATOR+'game.yaml') do |file|
        YAML::load(file)
    end
end
def save_game
    File.open(ChuchoMUDConfig.instance.module_directory+File::SEPARATOR+'game.yaml','w') do |file|
        YAML::dump($game,file)
    end
    $stdout.puts("dumped game")
end

def load_modules
    module_dir = "#{ChuchoMUDConfig.instance.module_directory}/lib/".gsub('/',File::SEPARATOR)
    module_logic_dir = module_dir+'logic'
    module_command_dir = module_dir+'commands'
    logic_dir = 'lib'+File::SEPARATOR+'logic'

    $:.unshift 'lib/commands'
    $:.unshift 
    $:.unshift module_command_dir
    $:.unshift module_logic_dir

    Dir.glob(module_logic_dir+File::SEPARATOR+'*.rb') do |logic|
        require(logic)
    end
    Dir.glob(logic_dir+File::SEPARATOR+'*.rb') do |logic|
        require(logic)
    end

    $stdout.puts "Using Library Path: #{$:.join(',')}"
end

def parse_args(argv)
    options = OpenStruct.new
    options.module = "Default"

    opts = OptionParser.new do |opts|
        opts.banner = "Usage: chucho_mud.rb [options]"
        opts.separator ""
        opts.separator "Specific options:"
        
        opts.on("-m","--module MODULE",
            "Indicate which Module to load") do |module_name|
                options.module = module_name
        end

        opts.separator ""
        opts.separator "Common options:"

        # No argument, shows at tail.  This will print
        # an options summary.
        # Try it and see!
        opts.on_tail("-h", "--help", "Show this message") do
            puts opts
            exit
        end

        opts.on_tail("--version","Show version") do
            puts Version.join('.')
            exit
        end
    end
    
    begin
        opts.parse(argv)
    rescue => e
        $stderr.puts e
        puts opts
        exit
    end
    options
end

if RUBY_VERSION == "1.8.4"
    class Bignum
        def to_yaml( opts = {} )
            YAML::quick_emit( nil, opts ) { |out|
                out.scalar( nil, to_s, :plain )
            }
        end
    end
end

if $0 == __FILE__
    Signal.trap("INT",method(:handle_signal))
    Signal.trap("TERM",method(:handle_signal))
    Signal.trap("KILL",method(:handle_signal))

    config = ChuchoMUDConfig.instance

    options = parse_args(ARGV)
    config.module_name= options.module

    if not FileTest.exists?(config.module_directory) then
        $stderr.puts "#{config.module_name} does not exist"
        exit 1
    end
    load_modules

    require 'manager'
    require 'game'
    require 'logger'

    # ----------------------------------------

    $log = Logger.new('logs/game_log','daily')
    $log.datetime_format = "%Y-%m-%d %H:%M:%S "
    $evt_log = Logger.new('logs/event_log','daily')
    $evt_log.datetime_format = "%Y-%m-%d %H:%M:%S "

    srand Time.now.to_i

    # UGH HACK !!
        Dir.glob('lib/commands/*.rb') do |cmd|
            load(cmd)
        end


    $game = load_game
    $game.setup
    $game.load_all
    manager = NetManager.new(4000)
    while $game.running?
        manager.manage
    end
    finish
end
