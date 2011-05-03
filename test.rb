# file:: test.rb
# author::  Ralph M. Churchill
# version:: 
# date::    
#
# This source code copyright (C) 2005 by Ralph M. Churchill
# All rights reserved.
#
# Released under the terms of the GNU General Public License
# See LICENSE file for additional information.

require 'test/unit'
require 'observer'
require 'telnet_commands'
require 'game'
require 'action'

class Array
    def get(v)
        fetch(v) if v
    end
    def find_open_id
        @id ||= 1000
        @id += 1
    end
    def generate_copy(entity)
        new = entity.dup
        new.oid = find_open_id
        insert(new.oid,new)
        new
    end
    def erase(i)
        self[i.oid] = nil
    end
end

class ItemTest < Test::Unit::TestCase
def setup
    $room_db = []
    $region_db = []
    $character_db = []
    $item_db = []

    # have a room, region, char
    @region = Region.new
    @region.oid = 99
    @region.name = 'region'
    $region_db[@region.oid] = @region

    @room = Room.new
    @room.oid = 88
    @room.name = 'room'
    @room.region = @region
    $room_db[@room.oid] = @room
    @region.add_room(@room)

    @char = Character.new
    @char.oid = 77
    @char.name = 'char'
    @char.room = @room
    @char.region = @region
    $character_db[@char.oid] = @char
    @region.add_character(@char)
    @room.add_character(@char)

    @game = Game.new
end

def test_get_item
    # create an item in a room/region
    item = Item.new
    item.oid = 66
    item.name = 'item'
    item.region = @region
    item.room = @room
    @room.add_item(item)
    @region.add_item(item)
    $item_db[item.oid] = item

    # char get item
    @game.get_item(@char,item,1)
    assert_equal(item.character,@char)
    assert_nil(item.room)
    assert_nil(item.region)
end
def test_drop_item
    # create an item on a character
    item = Item.new
    item.oid = 66
    item.name = 'item'
    item.character = @char
    @char.add_item(item)
    $item_db[item.oid] = item

    # char drop item
    @game.give_item(@char,@char.room,item,1)
    assert_nil(item.character)
    assert_equal(item.room,@char.room)
    assert_equal(item.region,@char.region)
end
def test_get_qty_item
    item = Item.new
    item.oid = 66
    item.name = 'Coin'
    item.description = '# coins'
    item.many = true
    item.quantity = 10
    item.region = @region
    item.room = @room
    @room.add_item(item)
    @region.add_item(item)
    $item_db[item.oid] = item

    @game.get_item(@char,item,2)
    assert_equal(item.character,@char)
    assert_nil(item.room)
    assert_nil(item.region)

    assert_equal(item.quantity,2)

    assert_equal(@region.items.empty?,false)
    assert_equal(@room.items.empty?,false)
    assert_equal(@region.items[0].quantity,8)
    assert_equal(@room.items[0].quantity,8)
end

def test_drop_qty_item
    item = Item.new
    item.oid = 66
    item.name = 'Coin'
    item.description = '# coins'
    item.many = true
    item.quantity = 10
    item.character = @char
    @char.add_item(item)
    $item_db[item.oid] = item

    @game.give_item(@char,@char.room,item,2)

    assert_nil(item.character)
    assert_equal(item.room,@char.room)
    assert_equal(item.region,@char.region)

    assert_equal(item.quantity,2)
    assert_equal(@region.items[0].quantity,2)
    assert_equal(@room.items[0].quantity,2)

    assert_equal(@char.items.empty?,false)
    assert_equal(@char.items[0].quantity,8)
end

def test_join_quantities
    one = Item.new
    one.oid=99
    one.many = true
    one.quantity = 1
    one.template_id = 88
    $item_db[one.oid] = one

    two = Item.new
    two.oid=98
    two.many = true
    two.quantity = 1
    two.template_id = 88
    $item_db[two.oid] = two

    three = Item.new
    three.oid=97
    three.many = true
    three.quantity = 1
    three.template_id = 88
    $item_db[three.oid] = three

    @char.add_item(one)
    one.character = @char
    assert_equal(@char.items.size,1)
    assert_equal(@char.items[0].quantity,1)

    @char.add_item(two)
    two.character = @char
    @game.join_quantities(@char,one)
    assert_equal(@char.items.size,1)
    assert_equal(2,@char.items[0].quantity)

    @char.add_item(three)
    three.character = @char
    @game.join_quantities(@char,one)
    assert_equal(@char.items.size,1)
    assert_equal(3,@char.items[0].quantity)
end
end
