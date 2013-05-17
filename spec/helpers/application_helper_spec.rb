# coding: utf-8
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

  context "include_account_css" do
    before do
      @site_admin = Account.site_admin
      @domain_root_account = Account.default
    end

    context "with no custom css" do
      it "should be empty" do
        include_account_css.should be_nil
      end
    end

    context "with custom css" do
      it "should include account css" do
        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_includes => true })
        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_stylesheet => '/path/to/css' })
        @domain_root_account.save!

        output = include_account_css
        output.should have_tag 'link'
        output.should match %r{/path/to/css}
      end

      it "should include site admin css" do
        @site_admin.settings = @site_admin.settings.merge({ :global_includes => true })
        @site_admin.settings = @site_admin.settings.merge({ :global_stylesheet => '/path/to/css' })
        @site_admin.save!

        output = include_account_css
        output.should have_tag 'link'
        output.should match %r{/path/to/css}
      end

      it "should include site admin css once" do
        @site_admin.settings = @site_admin.settings.merge({ :global_includes => true })
        @site_admin.settings = @site_admin.settings.merge({ :global_stylesheet => '/path/to/css' })
        @site_admin.save!

        output = include_account_css
        output.should have_tag 'link'
        output.scan(%r{/path/to/css}).length.should eql 1
      end

      it "should include site admin css first" do
        @site_admin.settings = @site_admin.settings.merge({ :global_includes => true })
        @site_admin.settings = @site_admin.settings.merge({ :global_stylesheet => '/path/to/admin/css' })
        @site_admin.save!

        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_includes => true })
        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_stylesheet => '/path/to/root/css' })
        @domain_root_account.save!

        output = include_account_css
        output.should have_tag 'link'
        output.scan(%r{/path/to/(root/|admin/)?css}).should eql [['admin/'], ['root/']]
      end

      it "should not include anything if param is set to 0" do
        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_includes => true })
        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_stylesheet => '/path/to/css' })
        @domain_root_account.save!

        params[:global_includes] = '0'
        output = include_account_css
        output.should be_nil
      end
    end

    context "sub-accounts" do
      before do
        @site_admin.settings = @site_admin.settings.merge({ :global_includes => true })
        @site_admin.settings = @site_admin.settings.merge({ :global_stylesheet => '/path/to/admin/css' })
        @site_admin.save!

        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_includes => true })
        @domain_root_account.settings = @domain_root_account.settings.merge({ :sub_account_includes => true })
        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_stylesheet => '/path/to/root/css' })
        @domain_root_account.save!

        @sub_account1 = account_model(:root_account => @domain_root_account)
        @sub_account1.settings = @sub_account1.settings.merge({ :global_stylesheet => '/path/to/sub1/css' })
        @sub_account1.settings = @sub_account1.settings.merge({ :sub_account_includes => true })
        @sub_account1.save!

        @sub_account2 = account_model(:root_account => @domain_root_account)
        @sub_account2.settings = @sub_account2.settings.merge({ :global_stylesheet => '/path/to/sub2/css' })
        @sub_account2.save!
      end

      it "should include sub-account css" do
        @context = @sub_account1
        output = include_account_css
        output.should have_tag 'link'
        output.scan(%r{/path/to/(sub1/|sub2/|root/|admin/)?css}).should eql [['admin/'], ['root/'], ['sub1/']]
      end

      it "should not include sub-account css when root account is context" do
        @context = @domain_root_account
        output = include_account_css
        output.should have_tag 'link'
        output.scan(%r{/path/to/(sub1/|sub2/|root/|admin/)?css}).should eql [['admin/'], ['root/']]
      end

      it "should include sub-account css for course context" do
        @context = @sub_account1.courses.create!
        output = include_account_css
        output.should have_tag 'link'
        output.scan(%r{/path/to/(sub1/|sub2/|root/|admin/)?css}).should eql [['admin/'], ['root/'], ['sub1/']]
      end

      it "should include sub-account css for group context" do
        @course = @sub_account1.courses.create!
        @context = @course.groups.create!
        output = include_account_css
        output.should have_tag 'link'
        output.scan(%r{/path/to/(sub1/|sub2/|root/|admin/)?css}).should eql [['admin/'], ['root/'], ['sub1/']]
      end

      it "should use include sub-account css, if sub-account is lowest common account context" do
        @course = @sub_account1.courses.create!
        @course.offer!
        student_in_course(:active_all => true)
        @context = @user
        @current_user = @user
        output = include_account_css
        output.should have_tag 'link'
        output.scan(%r{/path/to/(sub1/|sub2/|root/|admin/)?css}).should eql [['admin/'], ['root/'], ['sub1/']]
      end

      it "should not use include sub-account css, if sub-account is not lowest common account context" do
        @course1 = @sub_account1.courses.create!
        @course1.offer!
        @course2 = @sub_account2.courses.create!
        @course2.offer!
        student_in_course(:active_all => true, :course => @course1)
        student_in_course(:active_all => true, :course => @course2, :user => @user)
        @context = @user
        @current_user = @user
        output = include_account_css
        output.should have_tag 'link'
        output.scan(%r{/path/to/(sub1/|sub2/|root/|admin/)?css}).should eql [['admin/'], ['root/']]
      end

      it "should include multiple levesl of sub-account css in the right order for course page" do
        @sub_sub_account1 = account_model(:parent_account => @sub_account1, :root_account => @domain_root_account)
        @sub_sub_account1.settings = @sub_sub_account1.settings.merge({ :global_stylesheet => '/path/to/subsub1/css' })
        @sub_sub_account1.save!

        @context = @sub_sub_account1.courses.create!
        output = include_account_css
        output.should have_tag 'link'
        output.scan(%r{/path/to/(subsub1/|sub1/|sub2/|root/|admin/)?css}).should eql [['admin/'], ['root/'], ['sub1/'], ['subsub1/']]
      end

      it "should include multiple levesl of sub-account css in the right order" do
        @sub_sub_account1 = account_model(:parent_account => @sub_account1, :root_account => @domain_root_account)
        @sub_sub_account1.settings = @sub_sub_account1.settings.merge({ :global_stylesheet => '/path/to/subsub1/css' })
        @sub_sub_account1.save!

        @course = @sub_sub_account1.courses.create!
        @course.offer!
        student_in_course(:active_all => true)
        @context = @user
        @current_user = @user
        output = include_account_css
        output.should have_tag 'link'
        output.scan(%r{/path/to/(subsub1/|sub1/|sub2/|root/|admin/)?css}).should eql [['admin/'], ['root/'], ['sub1/'], ['subsub1/']]
      end
    end
  end

  describe "include_account_js" do
    before do
      @site_admin = Account.site_admin
      @domain_root_account = Account.default
    end

    context "with no custom js" do
      it "should be empty" do
        include_account_js.should be_nil
      end
    end

    context "with custom js" do
      it "should include account javascript" do
        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_includes => true })
        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_javascript => '/path/to/js' })
        @domain_root_account.save!

        output = include_account_js
        output.should have_tag 'script'
        output.should match %r{/path/to/js}
      end

      it "should include site admin javascript" do
        @site_admin.settings = @site_admin.settings.merge({ :global_includes => true })
        @site_admin.settings = @site_admin.settings.merge({ :global_javascript => '/path/to/js' })
        @site_admin.save!

        output = include_account_js
        output.should have_tag 'script'
        output.should match %r{/path/to/js}
      end

      it "should include both site admin and root account javascript, site admin first" do
        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_includes => true })
        @domain_root_account.settings = @domain_root_account.settings.merge({ :global_javascript => '/path/to/root/js' })
        @domain_root_account.save!

        @site_admin.settings = @site_admin.settings.merge({ :global_includes => true })
        @site_admin.settings = @site_admin.settings.merge({ :global_javascript => '/path/to/admin/js' })
        @site_admin.save!

        output = include_account_js
        output.should have_tag 'script'
        output.scan(%r{/path/to/(admin/|root/)?js}).should eql [['admin/'], ['root/']]
      end
    end
  end

  context "global_includes" do
    it "should only compute includes once, with includes" do
      @site_admin = Account.site_admin
      @site_admin.expects(:global_includes_hash).once.returns({:css => "/path/to/css", :js => "/path/to/js"})
      include_account_css.should match %r{/path/to/css}
      include_account_js.should match %r{/path/to/js}
    end

    it "should only compute includes once, with includes" do
      @site_admin = Account.site_admin
      @site_admin.expects(:global_includes_hash).once.returns(nil)
      include_account_css.should be_nil
      include_account_js.should be_nil
    end
  end

  describe "hidden dialogs" do
    before do
      hidden_dialogs.should be_empty
    end

    it "should generate empty string when there are no dialogs" do
      str = render_hidden_dialogs
      str.should == ''
    end

    it "should work with one hidden_dialog" do
      hidden_dialog('my_test_dialog') { "Hello there!" }
      str = render_hidden_dialogs
      str.should == "<div id='my_test_dialog' style='display: none;''>Hello there!</div>"
    end

    it "should work with more than one hidden dialog" do
      hidden_dialog('first_dialog') { "first" }
      hidden_dialog('second_dialog') { "second" }
      str = render_hidden_dialogs
      str.should == "<div id='first_dialog' style='display: none;''>first</div><div id='second_dialog' style='display: none;''>second</div>"
    end

    it "should raise an error when a dialog with conflicting content is added" do
      hidden_dialog('dialog_id') { 'content' }
      lambda { hidden_dialog('dialog_id') { 'different content' } }.should raise_error
    end

    it "should only render a dialog once when it has been added multiple times" do
      hidden_dialog('dialog_id') { 'content' }
      hidden_dialog('dialog_id') { 'content' }
      str = render_hidden_dialogs
      str.should == "<div id='dialog_id' style='display: none;''>content</div>"
    end
  end

  describe "collection_cache_key" do
    it "should generate a cache key, changing when an element cache_key changes" do
      collection = [user, user, user]
      key1 = collection_cache_key(collection)
      key2 = collection_cache_key(collection)
      key1.should == key2
      # verify it's not overly long
      key1.length.should <= 40

      User.where(:id => collection[1]).update_all(:updated_at => 1.hour.ago)
      collection[1].reload
      key3 = collection_cache_key(collection)
      key1.should_not == key3
    end
  end

  describe "avatar_image" do
    before do
      user_model(:short_name => 'test guy')
    end

    it "should accept a user id" do
      self.expects(:avatar_url_for_user).with(@user).returns("http://www.example.com/test/url")
      img = Nokogiri::HTML::DocumentFragment.parse(avatar_image(@user)).children.first
      img['alt'].should == 'test guy'
      img['src'].should == "http://www.example.com/test/url"
      img['style'].should match %r"width: 50px"
    end

    it "should short-circuit user id 0" do
      img = Nokogiri::HTML::DocumentFragment.parse(avatar_image(0)).children.first
      img['alt'].should == ''
      img['src'].should match %r"/images/messages/avatar-50.png"
    end

    it "should accept a user" do
      self.expects(:avatar_url_for_user).with(@user).returns("http://www.example.com/test/url")
      img = Nokogiri::HTML::DocumentFragment.parse(avatar_image(@user, 30)).children.first
      img['alt'].should == 'test guy'
      img['src'].should == "http://www.example.com/test/url"
      img['style'].should match %r"width: 30px"
    end
  end

  describe "jt" do
    after do
      I18n.locale = nil
    end

    it "should output the translated default" do
      def i18n_scope; "date.days"; end
      (I18n.available_locales - [:en]).each do |locale|
        I18n.locale = locale
        expected = I18n.t("#date.days.today").to_json
        # relative
        jt("today", nil).should include expected
        # and absolute
        jt("#date.days.today", nil).should include expected
      end
    end
  end
end
