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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe PluginSetting do
  before(:all) do
    Canvas::Plugin.register('plugin_setting_test', nil, {:encrypted_settings => [:foo], :settings => {:bar => 'asdf'}} )
  end

  it "should encrypt/decrypt transparently" do
    s = PluginSetting.new(:name => "plugin_setting_test", :settings => {:bar => "qwerty", :foo => "asdf"})
    s.save.should be_true
    s.reload
    s.valid_settings?.should be_true
    s.settings.keys.sort_by(&:to_s).should eql([:bar, :foo, :foo_dec, :foo_enc, :foo_salt])
    s.settings[:bar].should eql("qwerty")
    s.settings[:foo_dec].should eql("asdf")
  end

  it "should not be valid if there are decrypt errors" do
    s = PluginSetting.new(:name => "plugin_setting_test", :settings => {:bar => "qwerty", :foo_enc => "invalid", :foo_salt => "invalid"})
    s.send(:create_without_callbacks).should be_true

    s.reload
    s.valid_settings?.should be_false
    s.settings.should eql({:bar => "qwerty", :foo_enc => "invalid", :foo_salt => "invalid", :foo => PluginSetting::DUMMY_STRING})
  end
  
  it "should return default content if no setting is set" do
    settings = PluginSetting.settings_for_plugin("plugin_setting_test")
    settings.should_not be_nil
    settings[:bar].should == "asdf"
  end
  
  it "should return updated content if created" do
    s = PluginSetting.new(:name => "plugin_setting_test", :settings => {:bar => "qwerty"})
    s.send(:create_without_callbacks).should be_true
    settings = PluginSetting.settings_for_plugin("plugin_setting_test")
    settings.should_not be_nil
    settings[:bar].should == "qwerty"
  end
  
  it "should return default content if the setting is disabled" do
    s = PluginSetting.new(:name => "plugin_setting_test", :settings => {:bar => "qwerty"})
    s.send(:create_without_callbacks).should be_true
    settings = PluginSetting.settings_for_plugin("plugin_setting_test")
    settings.should_not be_nil
    settings[:bar].should == "qwerty"
    
    s.update_attribute(:disabled, true)
    settings = PluginSetting.settings_for_plugin("plugin_setting_test")
    settings.should_not be_nil
    settings[:bar].should == "asdf"
  end

  it "should immediately uncache on save" do
    enable_cache do
      s = PluginSetting.new(:name => "plugin_setting_test", :settings => {:bar => "qwerty"})
      s.save!
      # cache it
      settings = PluginSetting.settings_for_plugin("plugin_setting_test")
      settings.should == {:bar => "qwerty"}
      s.settings = {:food => "bar"}
      s.save!
      # new settings
      settings = PluginSetting.settings_for_plugin("plugin_setting_test")
      settings.should == {:food => "bar"}
    end
  end
end
