#
# Copyright (C) 2011 Instructure, Inc.
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

# == Schema Information
#
# Table name: plugin_settings
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)     default(""), not null
#  settings   :text
#  created_at :datetime
#  updated_at :datetime
#
class PluginSetting < ActiveRecord::Base
  validates_uniqueness_of :name, :if => :validate_uniqueness_of_name?
  before_save :validate_posted_settings
  serialize :settings
  attr_accessor :posted_settings
  attr_accessible :name, :settings
  attr_writer :plugin

  before_save :encrypt_settings
  after_save :clear_cache
  after_destroy :clear_cache
  after_initialize :initialize_plugin_setting
  
  def validate_uniqueness_of_name?
    true
  end

  def validate_posted_settings
    if @posted_settings
      plugin = Canvas::Plugin.find(name.to_s)
      plugin.validate_settings(self, @posted_settings)
    end
  end

  def plugin
    @plugin ||= Canvas::Plugin.find(name.to_s)
  end

  # dummy value for encrypted fields so that you can still have something in the form (to indicate
  # it's set) and be able to tell when it gets blanked out.
  DUMMY_STRING = "~!?3NCRYPT3D?!~"
  def initialize_plugin_setting
    return unless settings && self.plugin
    @valid_settings = true
    if self.plugin.encrypted_settings
      self.plugin.encrypted_settings.each do |key|
        if settings["#{key}_enc".to_sym]
          begin
            settings["#{key}_dec".to_sym] = self.class.decrypt(settings["#{key}_enc".to_sym], settings["#{key}_salt".to_sym])
          rescue
            @valid_settings = false
          end
          settings[key] = DUMMY_STRING
        end
      end
    end
  end

  def valid_settings?
    @valid_settings
  end

  def encrypt_settings
    if settings && self.plugin && self.plugin.encrypted_settings
      self.plugin.encrypted_settings.each do |key|
        unless settings[key].blank?
          value = settings.delete(key)
          settings.delete("#{key}_dec".to_sym)
          if value == DUMMY_STRING  # no change, use what was there previously
            settings["#{key}_enc".to_sym] = settings_was["#{key}_enc".to_sym]
            settings["#{key}_salt".to_sym] = settings_was["#{key}_salt".to_sym]
          else
            settings["#{key}_enc".to_sym], settings["#{key}_salt".to_sym] = self.class.encrypt(value)
          end
        end
      end
    end
  end
  
  def enabled?
    read_attribute(:disabled) != true
  end

  def self.cached_plugin_setting(name)
    plugin_setting = MultiCache.fetch(settings_cache_key(name), copies: MultiCache.copies("plugin_settings")) do
      PluginSetting.find_by_name(name.to_s) || :nil
    end
    plugin_setting = nil if plugin_setting == :nil
    plugin_setting
  end

  def self.settings_for_plugin(name, plugin=nil)
    if (plugin_setting = cached_plugin_setting(name)) && plugin_setting.valid_settings? && plugin_setting.enabled?
      plugin_setting.plugin = plugin
      settings = plugin_setting.settings
    else
      plugin ||= Canvas::Plugin.find(name.to_s)
      raise Canvas::NoPluginError unless plugin
      settings = plugin.default_settings
    end

    settings
  end

  def self.settings_cache_key(name)
    ["settings_for_plugin2", name].cache_key
  end

  def clear_cache
    connection.after_transaction_commit do
      MultiCache.delete(PluginSetting.settings_cache_key(self.name), copies: MultiCache.copies("plugin_settings"))
    end
  end

  def self.encrypt(text)
    Canvas::Security.encrypt_password(text, 'instructure_plugin_setting')
  end

  def self.decrypt(text, salt)
    Canvas::Security.decrypt_password(text, salt, 'instructure_plugin_setting')
  end

  def self.find_by_name(name)
    where(name: name).first
  end
end
