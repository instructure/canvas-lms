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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ApplicationHelper do
  include ApplicationHelper
  
  context "folders_as_options" do
    before(:each) do
      course_model
      @f = Folder.create!(:name => 'f', :context => @course)
      @f_1 = Folder.create!(:name => 'f_1', :parent_folder => @f, :context => @course)
      @f_2 = Folder.create!(:name => 'f_2', :parent_folder => @f, :context => @course)
      @f_2_1 = Folder.create!(:name => 'f_2_1', :parent_folder => @f_2, :context => @course)
      @f_2_1_1 = Folder.create!(:name => 'f_2_1_1', :parent_folder => @f_2_1, :context => @course)
      @all_folders = [ @f, @f_1, @f_2, @f_2_1, @f_2_1_1 ]
    end
    
    it "should work work recursively" do
      option_string = folders_as_options([@f], :all_folders => @all_folders)
      
      html = Nokogiri::HTML::DocumentFragment.parse("<select>#{option_string}</select>")
      html.css('option').count.should == 5
      html.css('option')[0].text.should == @f.name
      html.css('option')[1].text.should match /^\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_1.name}/
      html.css('option')[4].text.should match /^\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_2_1_1.name}/
    end
    
    it "should limit depth" do
      option_string = folders_as_options([@f], :all_folders => @all_folders, :max_depth => 1)
      
      html = Nokogiri::HTML::DocumentFragment.parse("<select>#{option_string}</select>")
      html.css('option').count.should == 3
      html.css('option')[0].text.should == @f.name
      html.css('option')[1].text.should match /^\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_1.name}/
      html.css('option')[2].text.should match /^\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_2.name}/
    end
    
    it "should work without supplying all folders" do
      option_string = folders_as_options([@f])
      
      html = Nokogiri::HTML::DocumentFragment.parse("<select>#{option_string}</select>")
      html.css('option').count.should == 5
      html.css('option')[0].text.should == @f.name
      html.css('option')[1].text.should match /^\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_1.name}/
      html.css('option')[4].text.should match /^\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0\xC2\xA0- #{@f_2_1_1.name}/
    end
  end

  context "i18n js" do
    it "should include appropriate inline translations if there is a valid I18n scope" do
      js_blocks << {:i18n_scope => "time", :contents => '<script>alert("test")</script>'}
      render_js_blocks.should match(/<script>.*\{"en":\{"time".*I18n\.scoped\("time", function\(I18n\)\{\nalert\("test"\)\n\}\);\n<\/script>/m)
    end

    it "should not include inline translations if there is an invalid I18n scope" do
      js_blocks << {:i18n_scope => "foo", :contents => '<script>alert("foo")</script>'}
      render_js_blocks.should == "<script>\nI18n.scoped(\"foo\", function(I18n){\nalert(\"foo\")\n});\n</script>"
    end

    it "should cache inline translations on render" do
      ApplicationHelper.cached_translation_blocks = {}
      js_blocks << {:i18n_scope => "time", :contents => '<script>alert("test")</script>'} <<
                   {:i18n_scope => "time", :contents => '<script>alert("test2")</script>'} <<
                   {:i18n_scope => "foo", :contents => '<script>alert("foo")</script>'} <<
                   {:i18n_scope => "foo", :contents => '<script>alert("foo2")</script>'}
      output = render_js_blocks
      output.should match(/<script>.*\{"en":\{"time".*I18n\.scoped\("time", function\(I18n\)\{\nalert\("test"\)\n\}\);\n<\/script>/m)
      output.should include "<script>\nI18n.scoped(\"time\", function(I18n){\nalert(\"test2\")\n});\n</script>"
      output.should include "<script>\nI18n.scoped(\"foo\", function(I18n){\nalert(\"foo\")\n});\n</script>"
      output.should include "<script>\nI18n.scoped(\"foo\", function(I18n){\nalert(\"foo2\")\n});\n</script>"
      ApplicationHelper.cached_translation_blocks.size.should == 2
    end
  end

  it "show_user_create_course_button should work" do
    Account.default.update_attribute(:settings, { :teachers_can_create_courses => true, :students_can_create_courses => true })
    @domain_root_account = Account.default
    show_user_create_course_button(nil).should be_false
    user
    show_user_create_course_button(@user).should be_false
    course_with_teacher
    show_user_create_course_button(@teacher).should be_true
    account_admin_user
    show_user_create_course_button(@admin).should be_true
  end

  describe "tomorrow_at_midnight" do
    it "should always return a time in the future" do
      now = 1.day.from_now.midnight - 5.seconds
      tomorrow_at_midnight.should > now
    end
  end

  describe "cache_if" do
    it "should cache the fragment if the condition is true" do
      enable_cache do
        cache_if(true, "t1", :expires_in => 15.minutes, :no_locale => true) { output_buffer.concat "blargh" }
        @controller.read_fragment("t1").should == "blargh"
      end
    end

    it "should not cache if the condition is false" do
      enable_cache do
        cache_if(false, "t1", :expires_in => 15.minutes, :no_locale => true) { output_buffer.concat "blargh" }
        @controller.read_fragment("t1").should be_nil
      end
    end
  end
end
