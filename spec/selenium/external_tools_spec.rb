require File.expand_path(File.dirname(__FILE__) + '/helpers/external_tools_common')

describe "external tools" do
  include_examples "external tools tests"

  describe "app center" do
    before (:each) do
      enable_app_center_plugin
      @account = Account.default
      account_admin_user(:account => @account)
      user_session(@user)

      get "/accounts/#{@account.id}/settings"
      f("#tab-tools-link").click
    end

    # This test has included multiple tests due because there is no need to slow down
    # the testing cycle. All of these tests depend on the prior to pass.
    it "should be able to view app center list and manage a add an app" do
      ff('.app').size.should > 0
      ff('.app').first.click
      wait_for_ajaximations

      fj('a.add_app').should be_present
      fj('table.review-item').should be_present
      fj('a.app_cancel').click
      wait_for_ajaximations

      #App list should have apps
      ff('.app').size.should > 0
      fj('a[data-toggle-installed-state="installed"]').click
      wait_for_ajaximations

      #Installed app list should have no apps
      ff('.app').size.should == 0
      fj('a[data-toggle-installed-state="not_installed"]').click
      wait_for_ajaximations

      #Not installed app list should have apps
      ff('.app').size.should > 0
      fj('a[data-toggle-installed-state="all"]').click
      wait_for_ajaximations

      #Install an app
      ff('.app').size.should > 0
      ff('.app').first.click
      wait_for_ajaximations

      f("#add_app_form").should be_nil
      fj('a.add_app').click
      wait_for_ajaximations

      #It should auto install because it only requires a name
      f("#add_app_form").should be_nil
      fj('.view_app_center_link').click
      wait_for_ajaximations

      fj('a[data-toggle-installed-state="installed"]').click
      wait_for_ajaximations

      #Installed app list should have apps
      ff('.app').size.should > 0
      ff('.app').first.click
      wait_for_ajaximations

      #Install app again
      fj('a.add_app').click
      wait_for_ajaximations

      #Add app form should be displayed because the app is already installed
      f("#add_app_form").should be_displayed
      replace_content(f("#canvas_app_name"), "New App")
      fj('button.btn-primary[role="button"]').click
      wait_for_ajaximations

      ff('td.external_tool').size.should > 0
      fj('.view_app_center_link').click
      wait_for_ajaximations

      ff('.app').size.should > 0
      fj('.view_tools_link').click
      wait_for_ajaximations

      fj('.add_tool_link').should be_present
    end

    it "should not see the app center if the plugin is disabled" do
      @plugin_setting = PluginSetting.find_by_name('app_center')
      @plugin_setting.disabled = true
      @plugin_setting.save

      get "/accounts/#{@account.id}/settings"
      f("#tab-tools-link").click
      wait_for_ajaximations
      fj('.add_tool_link').should be_present
    end
  end

  describe "editing external tools" do
    include_examples "external tools tests"

    before (:each) do
      course_with_teacher_logged_in
    end

    it "should clear the shared secret after saving" do
      tool_name = 'test tool'
      get "/courses/#{@course.id}/settings"
      f("#tab-tools-link").click
      f('.add_tool_link').click
      f('#external_tool_name').send_keys(tool_name)
      f('#external_tool_consumer_key').send_keys('fdjaklfjdaklfdjaslfjajfkljsalkjflas')
      f('#external_tool_shared_secret').send_keys('r08132ufio1jfj1iofj3j1kf3ljl1')
      f('#external_tool_domain').send_keys('instructure.com')
      fj('.ui-dialog:visible .btn-primary').click()
      wait_for_ajaximations
      f(".edit_tool_link[data-edit-external-tool='#{ContextExternalTool.find_by_name(tool_name).id}']").click
      f('#external_tool_name').should have_attribute(:value, tool_name)
      f('#external_tool_shared_secret').should have_attribute(:value, "")
    end

    it "should allow creating a new course external tool with custom fields" do
      get "/courses/#{@course.id}/settings"
      f("#tab-tools-link").click
      add_external_tool
      tool = ContextExternalTool.last
      tool_elem = f("#external_tool_#{tool.id}")
      tool_elem.should be_displayed
    end

    it "should allow creating a new course external tool with extensions" do
      get "/courses/#{@course.id}/settings"
      f("#tab-tools-link").click
      add_external_tool :xml
    end

    it "should allow editing an existing external tool with custom fields" do
      tool = @course.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
      get "/courses/#{@course.id}/settings"
      keep_trying_until { f("#tab-tools-link").should be_displayed }
      f("#tab-tools-link").click
      f("#external_tool_#{tool.id} .edit_tool_link").click
      f("#external_tool_name").should have_value "new tool"
      f("#external_tool_consumer_key").should have_value 'key'
      f("#external_tool_domain").should have_value 'example.com'
      f("#external_tool_custom_fields_string").should have_value "a=1\nb=2"
      replace_content(f("#external_tool_name"), "new tool (updated)")
      replace_content(f("#external_tool_consumer_key"), "key (updated)")
      replace_content(f("#external_tool_shared_secret"), "secret (updated)")
      replace_content(f("#external_tool_domain"), "example2.com")
      replace_content(f("#external_tool_custom_fields_string"), "a=9\nb=8")
      fj('.ui-dialog:visible .btn-primary').click()
      wait_for_ajax_requests
      tool_elem = fj("#external_tools .external_tool").should be_displayed
      tool_elem.should_not be_nil
      tool.reload
      tool.name.should == "new tool (updated)"
      tool.consumer_key.should == "key (updated)"
      tool.shared_secret.should == "secret (updated)"
      tool.domain.should == "example2.com"
      tool.custom_fields.should == {'a' => '9', 'b' => '8'}
    end

    it "should allow adding an external tool to a course module" do
      @module = @course.context_modules.create!(:name => "module")
      get "/courses/#{@course.id}/modules"

      keep_trying_until { driver.execute_script("return window.modules.refreshed == true") }

      f("#context_module_#{@module.id} .admin-links.al-trigger").click
      f("#context_module_#{@module.id} .add_module_item_link").click

      f("#add_module_item_select option[value='context_external_tool']").click
      f("#external_tool_create_url").send_keys("http://www.example.com")
      f("#external_tool_create_title").send_keys("Example")
      f("#external_tool_create_new_tab").click
      fj(".add_item_button:visible").click
      wait_for_ajax_requests
      f("#select_context_content_dialog").should_not be_displayed
      ff("#context_module_item_new").length.should == 0

      @tag = ContentTag.last
      @tag.should_not be_nil
      @tag.title.should == "Example"
      @tag.new_tab.should == true
      @tag.url.should == "http://www.example.com"
    end

    it "should not list external tools that don't have a url, domain, or resource_selection configured" do
      @module = @course.context_modules.create!(:name => "module")

      @tool1 = @course.context_external_tools.create!(:name => "First Tool", :url => "http://www.example.com", :consumer_key => "key", :shared_secret => "secret")
      @tool2 = @course.context_external_tools.new(:name => "Another Tool", :consumer_key => "key", :shared_secret => "secret")
      @tool2.settings[:editor_button] = {:url => "http://www.example.com", :icon_url => "http://www.example.com", :selection_width => 100, :selection_height => 100}.with_indifferent_access
      @tool2.save!
      @tool3 = @course.context_external_tools.new(:name => "Third Tool", :consumer_key => "key", :shared_secret => "secret")
      @tool3.settings[:resource_selection] = {:url => "http://www.example.com", :icon_url => "http://www.example.com", :selection_width => 100, :selection_height => 100}.with_indifferent_access
      @tool3.save!

      get "/courses/#{@course.id}/modules"

      keep_trying_until { driver.execute_script("return window.modules.refreshed == true") }

      f("#context_module_#{@module.id} .admin-links.al-trigger").click
      f("#context_module_#{@module.id} .add_module_item_link").click

      f("#add_module_item_select option[value='context_external_tool']").click

      keep_trying_until { ff("#context_external_tools_select .tool .name").length > 0 }
      names = ff("#context_external_tools_select .tool .name").map(&:text)
      names.should be_include(@tool1.name)
      names.should_not be_include(@tool2.name)
      names.should be_include(@tool3.name)
    end

    it "should allow adding an existing external tool to a course module, and should pick the correct tool" do
      @module = @course.context_modules.create!(:name => "module")
      @tool1 = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool2 = @course.context_external_tools.create!(:name => "b", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')

      get "/courses/#{@course.id}/modules"

      keep_trying_until { driver.execute_script("return window.modules.refreshed == true") }

      f("#context_module_#{@module.id} .admin-links.al-trigger").click
      f("#context_module_#{@module.id} .add_module_item_link").click

      f("#add_module_item_select option[value='context_external_tool']").click
      keep_trying_until { ff("#context_external_tools_select .tools .tool").length > 0 }
      ff("#context_external_tools_select .tools .tool")[1].click
      f("#external_tool_create_url").should have_value @tool2.url
      f("#external_tool_create_title").should have_value @tool2.name
      ff("#context_external_tools_select .tools .tool")[0].click
      f("#external_tool_create_url").should have_value @tool1.url
      f("#external_tool_create_title").should have_value @tool1.name
      fj(".add_item_button:visible").click
      wait_for_ajax_requests
      f("#select_context_content_dialog").should_not be_displayed
      keep_trying_until { ff("#context_module_item_new").length.should == 0 }

      @tag = ContentTag.last
      @tag.should_not be_nil
      @tag.title.should == @tool1.name
      @tag.url.should == @tool1.url
      @tag.content.should == @tool1

      f("#context_module_#{@module.id} .admin-links.al-trigger").click
      f("#context_module_#{@module.id} .add_module_item_link").click

      f("#add_module_item_select option[value='context_external_tool']").click
      ff("#context_external_tools_select .tools .tool")[1].click
      f("#external_tool_create_url").should have_value @tool2.url
      f("#external_tool_create_title").should have_value @tool2.name
      fj(".add_item_button:visible").click
      wait_for_ajax_requests
      f("#select_context_content_dialog").should_not be_displayed
      ff("#context_module_item_new").length.should == 0

      @tag = ContentTag.last
      @tag.should_not be_nil
      @tag.title.should == @tool2.name
      @tag.url.should == @tool2.url
    end

    it "should allow adding an external tool with resource selection enabled to a course module" do
      @module = @course.context_modules.create!(:name => "module")
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :url => "http://www.example.com/ims/lti")
      tool.resource_selection = {
          :url => "http://#{HostUrl.default_host}/selection_test",
          :selection_width => 400,
          :selection_height => 400
      }
      tool.save!
      tool2 = @course.context_external_tools.new(:name => "not bob", :consumer_key => "not bob", :shared_secret => "not bob", :url => "https://www.example.com")
      tool2.save!
      get "/courses/#{@course.id}/modules"

      keep_trying_until { driver.execute_script("return window.modules.refreshed == true") }

      f("#context_module_#{@module.id} .admin-links.al-trigger").click
      f("#context_module_#{@module.id} .add_module_item_link").click

      f("#add_module_item_select option[value='context_external_tool']").click
      wait_for_ajax_requests
      ff("#context_external_tools_select .tools .tool").length > 0

      tools = ff("#context_external_tools_select .tools .tool")
      tools[0].find_element(:css, ".name").text.should_not match(/not/)
      tools[1].find_element(:css, ".name").text.should match(/not bob/)
      tools[1].click
      f("#external_tool_create_url").should have_value "https://www.example.com"
      f("#external_tool_create_title").should have_value "not bob"

      tools[0].click
      keep_trying_until { f("#resource_selection_dialog").should be_displayed }

      in_frame('resource_selection_iframe') do
        keep_trying_until { ff("#basic_lti_link").length > 0 }
        ff(".link").length.should == 4
        f("#basic_lti_link").click
        wait_for_ajax_requests
      end
      f("#resource_selection_dialog").should_not be_displayed
      f("#external_tool_create_url").should have_value "http://www.example.com"
      f("#external_tool_create_title").should have_value "lti embedded link"
    end

    it "should alert when invalid url data is returned by a resource selection dialog" do
      @module = @course.context_modules.create!(:name => "module")
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :url => "http://www.example.com/ims/lti")
      tool.resource_selection = {
          :url => "http://#{HostUrl.default_host}/selection_test",
          :selection_width => 400,
          :selection_height => 400
      }
      tool.save!
      tool2 = @course.context_external_tools.new(:name => "not bob", :consumer_key => "not bob", :shared_secret => "not bob", :url => "https://www.example.com")
      tool2.save!
      get "/courses/#{@course.id}/modules"

      keep_trying_until { driver.execute_script("return window.modules.refreshed == true") }

      f("#context_module_#{@module.id} .admin-links.al-trigger").click
      f("#context_module_#{@module.id} .add_module_item_link").click
      f("#add_module_item_select option[value='context_external_tool']").click
      wait_for_ajax_requests
      ff("#context_external_tools_select .tools .tool").length > 0

      tools = ff("#context_external_tools_select .tools .tool")
      tools[0].find_element(:css, ".name").text.should_not match(/not/)
      tools[1].find_element(:css, ".name").text.should match(/not bob/)
      tools[1].click
      f("#external_tool_create_url").should have_value "https://www.example.com"
      f("#external_tool_create_title").should have_value "not bob"

      tools[0].click

      keep_trying_until { f("#resource_selection_dialog").should be_displayed }

      expect_fired_alert do
        in_frame('resource_selection_iframe') do
          keep_trying_until { ff("#basic_lti_link").length > 0 }
          ff(".link").length.should == 4
          f("#bad_url_basic_lti_link").click
        end
      end
      wait_for_ajax_requests
      f("#resource_selection_dialog").should_not be_displayed

      f("#external_tool_create_url").should have_value ""
      f("#external_tool_create_title").should have_value ""

      tools[0].click
      keep_trying_until { f("#resource_selection_dialog").should be_displayed }

      expect_fired_alert do
        in_frame('resource_selection_iframe') do
          keep_trying_until { ff("#basic_lti_link").length > 0 }
          ff(".link").length.should == 4
          f("#no_url_basic_lti_link").click
        end
      end
      wait_for_ajax_requests
      f("#resource_selection_dialog").should_not be_displayed
      f("#external_tool_create_url").should have_value ""
      f("#external_tool_create_title").should have_value ""
    end

    it "should use the tool name if no link text is returned" do
      @module = @course.context_modules.create!(:name => "module")
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :url => "http://www.example.com/ims/lti")
      tool.resource_selection = {
          :url => "http://#{HostUrl.default_host}/selection_test",
          :selection_width => 400,
          :selection_height => 400
      }
      tool.save!
      tool2 = @course.context_external_tools.new(:name => "not bob", :consumer_key => "not bob", :shared_secret => "not bob", :url => "https://www.example.com")
      tool2.save!
      get "/courses/#{@course.id}/modules"

      keep_trying_until { driver.execute_script("return window.modules.refreshed == true") }

      f("#context_module_#{@module.id} .admin-links.al-trigger").click
      f("#context_module_#{@module.id} .add_module_item_link").click
      f("#add_module_item_select option[value='context_external_tool']").click

      keep_trying_until { ff("#context_external_tools_select .tools .tool").length > 0 }

      tools = ff("#context_external_tools_select .tools .tool")
      tools[0].find_element(:css, ".name").text.should_not match(/not/)
      tools[1].find_element(:css, ".name").text.should match(/not bob/)
      tools[1].click
      f("#external_tool_create_url").should have_value "https://www.example.com"
      f("#external_tool_create_title").should have_value "not bob"

      tools[0].click
      keep_trying_until { f("#resource_selection_dialog").should be_displayed }
      in_frame('resource_selection_iframe') do
        keep_trying_until { ff("#basic_lti_link").length > 0 }
        ff(".link").length.should == 4
        f("#no_text_basic_lti_link").click
        wait_for_ajax_requests
      end
      f("#resource_selection_dialog").should_not be_displayed
      f("#external_tool_create_url").should have_value "http://www.example.com"
      f("#external_tool_create_title").should have_value "bob"
    end

    it "should allow editing the settings for a tool in a module" do
      @module = @course.context_modules.create!(:name => "module")
      @tag = @module.add_item({
                                  :type => 'context_external_tool',
                                  :title => 'Example',
                                  :url => 'http://www.example.com',
                                  :new_tab => '1'
                              })
      get "/courses/#{@course.id}/modules"
      keep_trying_until { driver.execute_script("return window.modules.refreshed == true") }

      f("#context_module_item_#{@tag.id}").click
      f("#context_module_item_#{@tag.id} .edit_item_link").click

      f("#edit_item_form").should be_displayed
      replace_content(f("#edit_item_form #content_tag_title"), "Example 2")
      f("#edit_item_form #content_tag_new_tab").click
      submit_form("#edit_item_form")

      wait_for_ajax_requests

      @tag.reload
      @tag.should_not be_nil
      @tag.title.should == "Example 2"
      @tag.new_tab.should == false
      @tag.url.should == "http://www.example.com"
    end

    it "should launch assignment external tools when viewing assignment" do
      @tool = @course.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
      assignment_model(:course => @course, :points_possible => 40, :submission_types => 'external_tool', :grading_type => 'points')
      tag = @assignment.build_external_tool_tag(:url => "http://example.com")
      tag.content_type = 'ContextExternalTool'
      tag.save!
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      ff("#tool_content").length.should == 1
      keep_trying_until { f("#tool_content").should be_displayed }
    end

    it "should automatically load tools with default configuration" do
      @tool = @course.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
      @module = @course.context_modules.create!(:name => "module")
      @tag = @module.add_item({
                                  :type => 'context_external_tool',
                                  :title => 'Example',
                                  :url => 'http://www.example.com',
                                  :new_tab => '0'
                              })
      get "/courses/#{@course.id}/modules/items/#{@tag.id}"

      ff("#tool_content").length.should == 1
      keep_trying_until { f("#tool_content").should be_displayed }
    end

    it "should not automatically load tools configured to load in a new tab" do
      @tool = @course.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
      @module = @course.context_modules.create!(:name => "module")
      @tag = @module.add_item({
                                  :type => 'context_external_tool',
                                  :title => 'Example',
                                  :url => 'http://www.example.com',
                                  :new_tab => '1'
                              })
      get "/courses/#{@course.id}/modules/items/#{@tag.id}"

      f("#tool_form").should be_displayed
      ff("#tool_form .load_tab").length.should == 1
    end

    context "homework submission from an LTI tool" do
      before(:each) do
        course_with_student_logged_in
        @assignment = @course.assignments.create!(:title => "test assignment", :submission_types => "online_upload,online_url")
      end

      def homework_submission_tool(count=4)
        count.times do |i|
          @tool = @course.context_external_tools.new(:name => "bob-#{i}", :consumer_key => "bob", :shared_secret => "bob", :url => "http://www.example.com/ims/lti")
          @tool.homework_submission = {
              :url => "http://#{HostUrl.default_host}/selection_test",
              :selection_width => 400,
              :selection_height => 400
          }
          @tool.save!
        end
      end

      def pick_submission_tool(iframe_link_selector)
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_dom_ready
        f(".submit_assignment_link").click
        wait_for_ajax_requests
        f(".submit_from_external_tool_option").should be_displayed
        f(".submit_from_external_tool_option").click
        ff("#submit_from_external_tool_form .tools .tool").length.should > 0
        f("#external_tool_url").attribute('value').should == ""
        select_submission_content(iframe_link_selector)
      end

      def select_submission_content(iframe_link_selector)
        f("#submit_from_external_tool_form .tools .tool").click
        keep_trying_until { f("#homework_selection_dialog").should be_displayed }

        in_frame('homework_selection_iframe') do
          keep_trying_until { ff(iframe_link_selector).length > 0 }
          f(iframe_link_selector).click
        end
        keep_trying_until { f("#homework_selection_dialog") == nil }
      end

      def assert_invalid_selection_message(msg=nil)
        msg ||= /returned an invalid/
        keep_trying_until{ ffj("#flash_message_holder li").length > 0 }
        message = f("#flash_message_holder li")
        message.should_not be_nil
        message.text.should match(msg)
        ff("#submit_assignment .cancel_button").select(&:displayed?).first.click
      end

      it "should not load if no tools are configured" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_dom_ready
        f(".submit_assignment_link").click
        wait_for_ajax_requests
        ff(".submit_from_external_tool_option").length.should == 0
        ff("#submit_assignment .cancel_button").select(&:displayed?).first.click
      end

      it "should load a list of tools in the 'more' tab if configured and applicable" do
        homework_submission_tool
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_dom_ready
        f(".submit_assignment_link").click
        wait_for_ajax_requests
        ff("li a.external-tool").length.should == 3
        f(".submit_from_external_tool_option").should be_displayed
        ff("#submit_assignment .cancel_button").select(&:displayed?).first.click
        # TODO: make sure the 'submit' button isn't enabled yed
      end

      it "should show tabs for two tools and not display the 'more' tab'" do
        homework_submission_tool(2)
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_dom_ready
        f(".submit_assignment_link").click
        wait_for_ajax_requests
        ff("li a.external-tool").length.should == 2 
        ff(".submit_from_external_tool_option").length.should == 0
      end

      it "should allow submission for a tool that returns a file URL for a file assignment" do
        homework_submission_tool
        pick_submission_tool('#file_link')

        f("#external_tool_url").attribute('value').should match(/delete\.png/)
        f("#external_tool_filename").attribute('value').should ==('delete.png')
        f("#external_tool_submission_type").attribute('value').should ==('online_url_to_file')

        expect do
          f("#submit_from_external_tool_form .btn-primary").click
          wait_for_ajaximations
        end.to change(Delayed::Job, :count).by(1)

        Delayed::Job.last.invoke_job
        a = Attachment.last
        keep_trying_until { a.file_state == 'available' }
        keep_trying_until { !f("#submit_assignment").displayed? }
        submission = @assignment.find_or_create_submission(@user)
        submission.submission_type.should == 'online_upload'
        submission.submitted_at.should_not be_nil
      end

      it "should allow submission for a tool that returns a URL for a URL assignment" do
        homework_submission_tool
        pick_submission_tool('#full_url_link')

        f("#external_tool_url").attribute('value').should match(/delete\.png/)
        f("#external_tool_submission_type").attribute('value').should ==('online_url')
        f("#submit_from_external_tool_form .btn-primary").click
        keep_trying_until { !f("#submit_assignment").displayed? }
        submission = @assignment.find_or_create_submission(@user)
        submission.submission_type.should == 'online_url'
        submission.submitted_at.should_not be_nil
      end

      it "should fail if the tool tries to return any other type" do
        homework_submission_tool
        pick_submission_tool('#basic_lti_link')

        assert_invalid_selection_message
      end

      it "should fail if the tool returns a file type that isn't valid for the file assignment" do
        @assignment.update_attributes(:allowed_extensions => 'pdf,doc')
        @assignment.reload.allowed_extensions.should == ['pdf', 'doc']
        homework_submission_tool
        pick_submission_tool('#file_link')
        f('#submit_from_external_tool_form .bad_ext_msg').should be_displayed
        f('#submit_from_external_tool_form .btn-primary').should have_attribute('disabled', 'true')
        ff("#submit_assignment .cancel_button").select(&:displayed?).first.click
      end

      it "should allow submission for a valid type after an invalid submission" do
        @assignment.update_attributes(:allowed_extensions => 'pdf,doc')
        @assignment.reload.allowed_extensions.should == ['pdf', 'doc']
        homework_submission_tool
        pick_submission_tool('#file_link')
        select_submission_content('#full_url_link')
        f('#submit_from_external_tool_form .bad_ext_msg').should_not be_displayed
        f('#submit_from_external_tool_form .btn-primary').attribute('disabled').should be_nil
        ff("#submit_assignment .cancel_button").select(&:displayed?).first.click
      end

      it "should fail if the tool returns a file URL for a non-file assignment" do
        @assignment.update_attributes(:submission_types => 'online_url')
        homework_submission_tool
        pick_submission_tool('#file_link')
        assert_invalid_selection_message
      end

      it "should fail if the tool returns a URL for a non-URL assignment" do
        @assignment.update_attributes(:submission_types => 'online_upload')
        homework_submission_tool
        pick_submission_tool('#full_url_link')
        assert_invalid_selection_message
      end

      it "should fail to submit if the tool returns an invalid file URL" do
        homework_submission_tool
        pick_submission_tool('#bad_file_link')

        f("#external_tool_submission_type").attribute('value').should ==('online_url_to_file')
        f('#submit_from_external_tool_form .btn-primary').click
        wait_for_ajax_requests
        Delayed::Job.last.invoke_job
        a = Attachment.last

        assert_invalid_selection_message(/problem retrieving/)
      end
    end

    context "tool creation" do
      context "app center" do
        before(:each) do
          #set up app center plugin
          app_center = Canvas::Plugin.find(:app_center)
          default_settings = Canvas::Plugin.find(:app_center).default_settings
          default_settings['base_url'] = 'www.example.com'
          PluginSetting.create(:name => app_center.id, :settings => default_settings)
        end

        it "uses app center if enabled" do
          tool_name = 'test tool'
          get "/courses/#{@course.id}/settings"
          f("#tab-tools-link").click
          f('.app_center').should be_displayed
        end

        it "can still add tools manually" do
          tool_name = 'test tool'
          get "/courses/#{@course.id}/settings"
          f('#tab-tools-link').click
          f('.view_tools_link').click
          f('.add_tool_link').click
          wait_for_ajaximations
          f('#external_tool_name').send_keys(tool_name)
          f('#external_tool_consumer_key').send_keys('fdjaklfjdaklfdjaslfjajfkljsalkjflas')
          f('#external_tool_shared_secret').send_keys('r08132ufio1jfj1iofj3j1kf3ljl1')
          f('#external_tool_domain').send_keys('instructure.com')
          f('#external_tool_form').submit()
          wait_for_ajaximations
          f("#external_tool_#{ContextExternalTool.find_by_name(tool_name).id} .edit_tool_link").click
          f('#external_tool_name').should have_attribute(:value, tool_name)
          f('#external_tool_shared_secret').should have_attribute(:value, "")
        end
      end
    end

  end

  describe 'showing external tools' do
    before do
      course_with_teacher_logged_in(active_all: true)
      @tool = @course.context_external_tools.create!(
        name: "new tool",
        consumer_key: "key",
        shared_secret: "secret",
        url: "http://#{HostUrl.default_host}/selection_test",
      )

    end

    it "assumes course navigation launch type" do
      @tool.course_navigation = {}
      @tool.save!
      get "/courses/#{@course.id}/external_tools/#{@tool.id}"
      in_frame('tool_content') do
        keep_trying_until { ff("#basic_lti_link").size.should > 0 }
      end
    end

    it "accepts an explicit launch type" do
      @tool.migration_selection = {}
      @tool.save!
      get "/courses/#{@course.id}/external_tools/#{@tool.id}?launch_type=migration_selection"
      in_frame('tool_content') do
        keep_trying_until { ff("#basic_lti_link").size.should > 0 }
      end
    end

    it "validates the launch type" do
      @tool.course_navigation = {}
      @tool.save!
      get "/courses/#{@course.id}/external_tools/#{@tool.id}?launch_type=bad_type"
      assert_flash_error_message(/couldn't find valid settings/i)
    end

    describe "display type" do
      before do
        @tool.course_navigation = {}
        @tool.save!
      end

      it "defaults to normal display type" do
        get "/courses/#{@course.id}/external_tools/#{@tool.id}"
        f('#footer').should be_displayed
        f('#left-side').should_not be_nil
        f('#breadcrumbs').should_not be_nil
        f('body').attribute('class').should_not include('full-width')
      end

      it "shows full width if top level property specified" do
        @tool.settings[:display_type] = "full_width"
        @tool.save!
        get "/courses/#{@course.id}/external_tools/#{@tool.id}"
        f('#footer').should_not be_displayed
        f('#left-side').should be_nil
        f('#breadcrumbs').should be_nil
        f('body').attribute('class').should include('full-width')
      end

      it "shows full width if extension property specified" do
        @tool.course_navigation[:display_type] = "full_width"
        @tool.save!
        get "/courses/#{@course.id}/external_tools/#{@tool.id}"
        f('#footer').should_not be_displayed
        f('#left-side').should be_nil
        f('#breadcrumbs').should be_nil
        f('body').attribute('class').should include('full-width')
      end
    end

  end

  private

  def enable_app_center_plugin
    @plugin_settings = PluginSetting.create(:name => 'app_center', :settings => {
        :base_url => "www.example.com",
        :apps_index_endpoint => "apps",
        :app_reviews_endpoint => "/apps/:id"
    })

    AppCenter::AppApi.any_instance.stubs(:get_apps).returns({
       'meta' => { "next" => "https://www.example.com/api/v1/apps?offset=72"},
       'current_offset' => 0,
       'limit' => 72,
       'lti_apps' => [
           {
               'name' => 'First Tool',
               'short_name' => 'first_tool',
               'requires_secret' => false,
               'config_xml_url' => ""
           },
           {
               'name' => 'Second Tool',
               'short_name' => 'second_tool',
               'requires_secret' => true,
           }
       ]
    })

    AppCenter::AppApi.any_instance.stubs(:get_app_reviews).returns({
         'meta' => { "next" => "https://www.example.com/api/v1/apps/first_tool/reviews?offset=15"},
         'current_offset' => 0,
         'limit' => 15,
         'reviews' => [
             {
                 'user' => {
                     "name" => 'Iron Man',
                     "avatar_url" => 'http://www.example.com/rich.ico',
                     "url" => nil
                 },
                 'comments' => 'This tool is so great',
             },
             {
                 'user' => {
                     "name" => 'The Hulk',
                     "avatar_url" => 'http://www.example.com/beefy.ico',
                     "url" => nil
                 },
                 'comments' => 'SMASH!',
             }
         ]
     })

    ContextExternalTool.any_instance.stubs(:process_extended_configuration)
    ContextExternalTool.any_instance.stubs(:url).returns('www.example.com')
  end

end
