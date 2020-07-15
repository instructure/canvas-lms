#
# Copyright (C) 2020 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class Trophy < ActiveRecord::Base
  TROPHY_NAMES = [
    'balloon',
    'bifrost_trophy',
    'butterfly',
    'einstein_rosen_trophy',
    'fire',
    'flowers',
    'four_leaf_clover',
    'gift',
    'gnome',
    'helix_rocket',
    'horse_shoe',
    'hot_air_balloon',
    'magic_mystery_thumbs_up',
    'medal',
    'moon',
    'ninja',
    'panama_rocket',
    'panda',
    'panda_unicycle',
    'pinwheel',
    'pizza_slice',
    'rocket',
    'star',
    'thumbs_up',
    'trophy'
  ].freeze

  belongs_to :user, inverse_of: :trophies

  def display_name
    case name
    when 'balloon'
      t(:balloon_display_name, 'Balloon')
    when 'bifrost_trophy'
      t(:bifrost_trophy_display_name, 'Bifrost Trophy')
    when 'butterfly'
      t(:butterfly_display_name, 'Butterfly')
    when 'einstein_rosen_trophy'
      t(:einstein_rosen_trophy_display_name, 'Einstein Rosen Trophy')
    when 'fire'
      t(:fire_display_name, 'Fire')
    when 'flowers'
      t(:flowers_display_name, 'Flower')
    when 'four_leaf_clover'
      t(:four_leaf_clover_display_name, 'Four Leaf Clover')
    when 'gift'
      t(:gift_display_name, 'Gift')
    when 'gnome'
      t(:gnome_display_name, 'Gnome')
    when 'helix_rocket'
      t(:helix_rocket_display_name, 'Helix Rocket')
    when 'horse_shoe'
      t(:horse_shoe_display_name, 'Horse Shoe')
    when 'hot_air_balloon'
      t(:hot_air_balloon_display_name, 'Hot Air Balloon')
    when 'magic_mystery_thumbs_up'
      t(:magic_mystery_thumbs_up_display_name, 'Magic Mystery Thumbs Up')
    when 'medal'
      t(:medal_display_name, 'Medal')
    when 'moon'
      t(:moon_display_name, 'Moon')
    when 'ninja'
      t(:ninja_display_name, 'Ninja')
    when 'panama_rocket'
      t(:panama_rocket_display_name, 'Panama Rocket')
    when 'panda'
      t(:panda_display_name, 'Panda')
    when 'panda_unicycle'
      t(:panda_unicycle_display_name, 'Panda Unicycle')
    when 'pinwheel'
      t(:pinwheel_display_name, 'Pinwheel')
    when 'pizza_slice'
      t(:pizza_slice_display_name, 'Pizza Slice')
    when 'rocket'
      t(:rocket_display_name, 'Rocket')
    when 'star'
      t(:star_display_name, 'Star')
    when 'thumbs_up'
      t(:thumbs_up_display_name, 'Thumbs Up')
    when 'trophy'
      t(:trophy_display_name, 'Trophy')
    end
  end

  def description
    case name
    when 'balloon'
      t(:balloon_description, 'Balloon Description')
    when 'bifrost_trophy'
      t(:bifrost_trophy_description, 'Bifrost Trophy Description')
    when 'butterfly'
      t(:butterfly_description, 'Butterfly Description')
    when 'einstein_rosen_trophy'
      t(:einstein_rosen_trophy_description, 'Einstein Rosen Trophy Description')
    when 'fire'
      t(:fire_description, 'Fire Description')
    when 'flowers'
      t(:flowers_description, 'Flower Description')
    when 'four_leaf_clover'
      t(:four_leaf_clover_description, 'Four Leaf Clover Description')
    when 'gift'
      t(:gift_description, 'Gift Description')
    when 'gnome'
      t(:gnome_description, 'Gnome Description')
    when 'helix_rocket'
      t(:helix_rocket_description, 'Helix Rocket Description')
    when 'horse_shoe'
      t(:horse_shoe_description, 'Horse Shoe Description')
    when 'hot_air_balloon'
      t(:hot_air_balloon_description, 'Hot Air Balloon Description')
    when 'magic_mystery_thumbs_up'
      t(:magic_mystery_thumbs_up_description, 'Magic Mystery Thumbs Up Description')
    when 'medal'
      t(:medal_description, 'Medal Description')
    when 'moon'
      t(:moon_description, 'Moon Description')
    when 'ninja'
      t(:ninja_description, 'Ninja Description')
    when 'panama_rocket'
      t(:panama_rocket_description, 'Panama Rocket Description')
    when 'panda'
      t(:panda_description, 'Panda Description')
    when 'panda_unicycle'
      t(:panda_unicycle_description, 'Panda Unicycle Description')
    when 'pinwheel'
      t(:pinwheel_description, 'Pinwheel Description')
    when 'pizza_slice'
      t(:pizza_slice_description, 'Pizza Slice Description')
    when 'rocket'
      t(:rocket_description, 'Rocket Description')
    when 'star'
      t(:star_description, 'Star Description')
    when 'thumbs_up'
      t(:thumbs_up_description, 'Thumbs Up Description')
    when 'trophy'
      t(:trophy_description, 'Trophy Description')
    end
  end

  def self.trophy_names
    TROPHY_NAMES
  end

  def self.blank_trophy(name)
    {
      name: name,
      _id: nil,
      id: nil,
      user_id: nil,
      display_name: nil,
      description: nil,
      created_at: nil,
      updated_at: nil
    }
  end
end
