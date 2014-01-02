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
  File.open(ChuchoMUDConfig.instance.module_directory.join('game.yaml')) do |file|
    YAML::load(file)
  end
end
def save_game
    File.open(ChuchoMUDConfig.instance.module_directory.join('game.yaml'),'w') do |file|
        YAML::dump($game,file)
    end
    $stdout.puts("dumped game")
end

def load_modules
    module_dir = ChuchoMUDConfig.instance.module_directory.join('lib')
    module_logic_dir = module_dir+'logic'
    module_command_dir = module_dir+'commands'
    logic_dir = File.join('lib', 'logic')

    $:.unshift 'lib/commands'
    $:.unshift 
    $:.unshift module_command_dir
    $:.unshift module_logic_dir

    Dir.glob(File.join(module_logic_dir, '*.rb')) do |logic|
        require(logic)
    end
    Dir.glob(File.join(logic_dir, '*.rb')) do |logic|
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

    if not config.module_directory.exist? then
        $stderr.puts "#{config.module_name} does not exist"
        exit 1
    end
    load_modules

    require 'network/manager'
    require 'game'
    require 'log4r'
    require 'log4r/yamlconfigurator'

    # ----------------------------------------

    log4r_config = YAML.load_file(File.join(File.dirname(__FILE__), "logging.yaml"))
    Log4r::YamlConfigurator.decode_yaml(log4r_config['log4r_config'])
    $log = Log4r::Logger["game_log"]
    $evt_log = Log4r::Logger["event_log"]

    srand Time.now.to_i

    # UGH HACK !!
        Dir.glob('lib/commands/*.rb') do |cmd|
            load(cmd)
        end


    $game = load_game
    $game.setup
    $game.load_all
    manager = NetManager.new($game, 4000)
    while $game.running?
        manager.manage
    end
    finish
end
