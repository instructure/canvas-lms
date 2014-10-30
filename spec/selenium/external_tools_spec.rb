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
      expect(ff('.app').size).to be > 0
      ff('.app').first.click
      wait_for_ajaximations

      expect(fj('a.add_app')).to be_present
      expect(fj('table.review-item')).to be_present
      fj('a.app_cancel').click
      wait_for_ajaximations

      #App list should have apps
      expect(ff('.app').size).to be > 0
      fj('a[data-toggle-installed-state="installed"]').click
      wait_for_ajaximations

      #Installed app list should have no apps
      expect(ff('.app').size).to eq 0
      fj('a[data-toggle-installed-state="not_installed"]').click
      wait_for_ajaximations

      #Not installed app list should have apps
      expect(ff('.app').size).to be > 0
      fj('a[data-toggle-installed-state="all"]').click
      wait_for_ajaximations

      #Install an app
      expect(ff('.app').size).to be > 0
      ff('.app').first.click
      wait_for_ajaximations

      expect(f("#add_app_form")).to be_nil
      fj('a.add_app').click
      wait_for_ajaximations

      #It should auto install because it only requires a name
      expect(f("#add_app_form")).to be_nil
      fj('.view_app_center_link').click
      wait_for_ajaximations

      fj('a[data-toggle-installed-state="installed"]').click
      wait_for_ajaximations

      #Installed app list should have apps
      expect(ff('.app').size).to be > 0
      ff('.app').first.click
      wait_for_ajaximations

      #Install app again
      fj('a.add_app').click
      wait_for_ajaximations

      #Add app form should be displayed because the app is already installed
      expect(f("#add_app_form")).to be_displayed
      replace_content(f("#canvas_app_name"), "New App")
      fj('button.btn-primary[role="button"]').click
      wait_for_ajaximations

      expect(ff('th.external_tool').size).to be > 0
      fj('.view_app_center_link').click
      wait_for_ajaximations

      expect(ff('.app').size).to be > 0
      fj('.view_tools_link').click
      wait_for_ajaximations

      expect(fj('.add_tool_link')).to be_present
    end

    it "should not see the app center if the plugin is disabled" do
      @plugin_setting = PluginSetting.find_by_name('app_center')
      @plugin_setting.disabled = true
      @plugin_setting.save

      get "/accounts/#{@account.id}/settings"
      f("#tab-tools-link").click
      wait_for_ajaximations
      expect(fj('.add_tool_link')).to be_present
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
      f(".edit_tool_link[data-edit-external-tool='#{ContextExternalTool.where(name: tool_name).first.id}']").click
      expect(f('#external_tool_name')).to have_attribute(:value, tool_name)
      expect(f('#external_tool_shared_secret')).to have_attribute(:value, "")
    end

    it "should allow creating a new course external tool with custom fields" do
      get "/courses/#{@course.id}/settings"
      f("#tab-tools-link").click
      add_external_tool
      tool = ContextExternalTool.last
      tool_elem = f("#external_tool_#{tool.id}")
      expect(tool_elem).to be_displayed
    end

    it "should allow creating a new course external tool with extensions" do
      get "/courses/#{@course.id}/settings"
      f("#tab-tools-link").click
      add_external_tool :xml
    end

    it "should allow editing an existing external tool with custom fields" do
      tool = @course.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
      get "/courses/#{@course.id}/settings"
      keep_trying_until { expect(f("#tab-tools-link")).to be_displayed }
      f("#tab-tools-link").click
      f("#external_tool_#{tool.id} .edit_tool_link").click
      expect(f("#external_tool_name")).to have_value "new tool"
      expect(f("#external_tool_consumer_key")).to have_value 'key'
      expect(f("#external_tool_domain")).to have_value 'example.com'
      expect(f("#external_tool_custom_fields_string")).to have_value "a=1\nb=2"
      replace_content(f("#external_tool_name"), "new tool (updated)")
      replace_content(f("#external_tool_consumer_key"), "key (updated)")
      replace_content(f("#external_tool_shared_secret"), "secret (updated)")
      replace_content(f("#external_tool_domain"), "example2.com")
      replace_content(f("#external_tool_custom_fields_string"), "a=9\nb=8")
      fj('.ui-dialog:visible .btn-primary').click()
      wait_for_ajax_requests
      tool_elem = expect(fj("#external_tools .external_tool")).to be_displayed
      expect(tool_elem).not_to be_nil
      tool.reload
      expect(tool.name).to eq "new tool (updated)"
      expect(tool.consumer_key).to eq "key (updated)"
      expect(tool.shared_secret).to eq "secret (updated)"
      expect(tool.domain).to eq "example2.com"
      expect(tool.custom_fields).to eq({'a' => '9', 'b' => '8'})
    end

    it "should allow adding an external tool to a course module" do
      @module = @course.context_modules.create!(:name => "module")
      get "/courses/#{@course.id}/modules"

      keep_trying_until { driver.execute_script("return window.modules.refreshed == true") }

      f("#context_module_#{@module.id} .add_module_item_link").click

      f("#add_module_item_select option[value='context_external_tool']").click
      f("#external_tool_create_url").send_keys("http://www.example.com")
      f("#external_tool_create_title").send_keys("Example")
      f("#external_tool_create_new_tab").click
      fj(".add_item_button:visible").click
      wait_for_ajax_requests
      expect(f("#select_context_content_dialog")).not_to be_displayed
      expect(ff("#context_module_item_new").length).to eq 0

      @tag = ContentTag.last
      expect(@tag).not_to be_nil
      expect(@tag.title).to eq "Example"
      expect(@tag.new_tab).to eq true
      expect(@tag.url).to eq "http://www.example.com"
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

      f("#context_module_#{@module.id} .add_module_item_link").click

      f("#add_module_item_select option[value='context_external_tool']").click

      keep_trying_until { ff("#context_external_tools_select .tool .name").length > 0 }
      names = ff("#context_external_tools_select .tool .name").map(&:text)
      expect(names).to be_include(@tool1.name)
      expect(names).not_to be_include(@tool2.name)
      expect(names).to be_include(@tool3.name)
    end

    it "should allow adding an existing external tool to a course module, and should pick the correct tool" do
      @module = @course.context_modules.create!(:name => "module")
      @tool1 = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool2 = @course.context_external_tools.create!(:name => "b", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')

      get "/courses/#{@course.id}/modules"

      keep_trying_until { driver.execute_script("return window.modules.refreshed == true") }

      f("#context_module_#{@module.id} .add_module_item_link").click

      f("#add_module_item_select option[value='context_external_tool']").click
      keep_trying_until { ff("#context_external_tools_select .tools .tool").length > 0 }
      ff("#context_external_tools_select .tools .tool")[1].click
      expect(f("#external_tool_create_url")).to have_value @tool2.url
      expect(f("#external_tool_create_title")).to have_value @tool2.name
      ff("#context_external_tools_select .tools .tool")[0].click
      expect(f("#external_tool_create_url")).to have_value @tool1.url
      expect(f("#external_tool_create_title")).to have_value @tool1.name
      fj(".add_item_button:visible").click
      wait_for_ajax_requests
      expect(f("#select_context_content_dialog")).not_to be_displayed
      keep_trying_until { expect(ff("#context_module_item_new").length).to eq 0 }

      @tag = ContentTag.last
      expect(@tag).not_to be_nil
      expect(@tag.title).to eq @tool1.name
      expect(@tag.url).to eq @tool1.url
      expect(@tag.content).to eq @tool1

      f("#context_module_#{@module.id} .add_module_item_link").click

      f("#add_module_item_select option[value='context_external_tool']").click
      ff("#context_external_tools_select .tools .tool")[1].click
      expect(f("#external_tool_create_url")).to have_value @tool2.url
      expect(f("#external_tool_create_title")).to have_value @tool2.name
      fj(".add_item_button:visible").click
      wait_for_ajax_requests
      expect(f("#select_context_content_dialog")).not_to be_displayed
      expect(ff("#context_module_item_new").length).to eq 0

      @tag = ContentTag.last
      expect(@tag).not_to be_nil
      expect(@tag.title).to eq @tool2.name
      expect(@tag.url).to eq @tool2.url
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

      f("#context_module_#{@module.id} .add_module_item_link").click

      f("#add_module_item_select option[value='context_external_tool']").click
      wait_for_ajax_requests
      ff("#context_external_tools_select .tools .tool").length > 0

      tools = ff("#context_external_tools_select .tools .tool")
      expect(tools[0].find_element(:css, ".name").text).not_to match(/not/)
      expect(tools[1].find_element(:css, ".name").text).to match(/not bob/)
      tools[1].click
      expect(f("#external_tool_create_url")).to have_value "https://www.example.com"
      expect(f("#external_tool_create_title")).to have_value "not bob"

      tools[0].click
      keep_trying_until { expect(f("#resource_selection_dialog")).to be_displayed }

      in_frame('resource_selection_iframe') do
        keep_trying_until { ff("#basic_lti_link").length > 0 }
        expect(ff(".link").length).to eq 4
        f("#basic_lti_link").click
        wait_for_ajax_requests
      end
      expect(f("#resource_selection_dialog")).not_to be_displayed
      expect(f("#external_tool_create_url")).to have_value "http://www.example.com"
      expect(f("#external_tool_create_title")).to have_value "lti embedded link"
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

      f("#context_module_#{@module.id} .add_module_item_link").click
      f("#add_module_item_select option[value='context_external_tool']").click
      wait_for_ajax_requests
      ff("#context_external_tools_select .tools .tool").length > 0

      tools = ff("#context_external_tools_select .tools .tool")
      expect(tools[0].find_element(:css, ".name").text).not_to match(/not/)
      expect(tools[1].find_element(:css, ".name").text).to match(/not bob/)
      tools[1].click
      expect(f("#external_tool_create_url")).to have_value "https://www.example.com"
      expect(f("#external_tool_create_title")).to have_value "not bob"

      tools[0].click

      keep_trying_until { expect(f("#resource_selection_dialog")).to be_displayed }

      expect_fired_alert do
        in_frame('resource_selection_iframe') do
          keep_trying_until { ff("#basic_lti_link").length > 0 }
          expect(ff(".link").length).to eq 4
          f("#bad_url_basic_lti_link").click
        end
      end
      wait_for_ajax_requests
      expect(f("#resource_selection_dialog")).not_to be_displayed

      expect(f("#external_tool_create_url")).to have_value ""
      expect(f("#external_tool_create_title")).to have_value ""

      tools[0].click
      keep_trying_until { expect(f("#resource_selection_dialog")).to be_displayed }

      expect_fired_alert do
        in_frame('resource_selection_iframe') do
          keep_trying_until { ff("#basic_lti_link").length > 0 }
          expect(ff(".link").length).to eq 4
          f("#no_url_basic_lti_link").click
        end
      end
      wait_for_ajax_requests
      expect(f("#resource_selection_dialog")).not_to be_displayed
      expect(f("#external_tool_create_url")).to have_value ""
      expect(f("#external_tool_create_title")).to have_value ""
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

      f("#context_module_#{@module.id} .add_module_item_link").click
      f("#add_module_item_select option[value='context_external_tool']").click

      keep_trying_until { ff("#context_external_tools_select .tools .tool").length > 0 }

      tools = ff("#context_external_tools_select .tools .tool")
      expect(tools[0].find_element(:css, ".name").text).not_to match(/not/)
      expect(tools[1].find_element(:css, ".name").text).to match(/not bob/)
      tools[1].click
      expect(f("#external_tool_create_url")).to have_value "https://www.example.com"
      expect(f("#external_tool_create_title")).to have_value "not bob"

      tools[0].click
      keep_trying_until { expect(f("#resource_selection_dialog")).to be_displayed }
      in_frame('resource_selection_iframe') do
        keep_trying_until { ff("#basic_lti_link").length > 0 }
        expect(ff(".link").length).to eq 4
        f("#no_text_basic_lti_link").click
        wait_for_ajax_requests
      end
      expect(f("#resource_selection_dialog")).not_to be_displayed
      expect(f("#external_tool_create_url")).to have_value "http://www.example.com"
      expect(f("#external_tool_create_title")).to have_value "bob"
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

      f("#context_module_item_#{@tag.id} .al-trigger").click
      f("#context_module_item_#{@tag.id} .edit_item_link").click

      expect(f("#edit_item_form")).to be_displayed
      replace_content(f("#edit_item_form #content_tag_title"), "Example 2")
      f("#edit_item_form #content_tag_new_tab").click
      submit_form("#edit_item_form")

      wait_for_ajax_requests

      @tag.reload
      expect(@tag).not_to be_nil
      expect(@tag.title).to eq "Example 2"
      expect(@tag.new_tab).to eq false
      expect(@tag.url).to eq "http://www.example.com"
    end

    it "should launch assignment external tools when viewing assignment" do
      @tool = @course.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
      assignment_model(:course => @course, :points_possible => 40, :submission_types => 'external_tool', :grading_type => 'points')
      tag = @assignment.build_external_tool_tag(:url => "http://example.com")
      tag.content_type = 'ContextExternalTool'
      tag.save!
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(ff("#tool_content").length).to eq 1
      keep_trying_until { expect(f("#tool_content")).to be_displayed }
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

      expect(ff("#tool_content").length).to eq 1
      keep_trying_until { expect(f("#tool_content")).to be_displayed }
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

      expect(f("#tool_form")).to be_displayed
      expect(ff("#tool_form .load_tab").length).to eq 1
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
        expect(f(".submit_from_external_tool_option")).to be_displayed
        f(".submit_from_external_tool_option").click
        expect(ff("#submit_from_external_tool_form .tools .tool").length).to be > 0
        expect(f("#external_tool_url").attribute('value')).to eq ""
        select_submission_content(iframe_link_selector)
      end

      def select_submission_content(iframe_link_selector)
        f("#submit_from_external_tool_form .tools .tool").click
        keep_trying_until { expect(f("#homework_selection_dialog")).to be_displayed }

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
        expect(message).not_to be_nil
        expect(message.text).to match(msg)
        ff("#submit_assignment .cancel_button").select(&:displayed?).first.click
      end

      it "should not load if no tools are configured" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_dom_ready
        f(".submit_assignment_link").click
        wait_for_ajax_requests
        expect(ff(".submit_from_external_tool_option").length).to eq 0
        ff("#submit_assignment .cancel_button").select(&:displayed?).first.click
      end

      it "should load a list of tools in the 'more' tab if configured and applicable" do
        homework_submission_tool
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_dom_ready
        f(".submit_assignment_link").click
        wait_for_ajax_requests
        expect(ff("li a.external-tool").length).to eq 3
        expect(f(".submit_from_external_tool_option")).to be_displayed
        ff("#submit_assignment .cancel_button").select(&:displayed?).first.click
        # TODO: make sure the 'submit' button isn't enabled yed
      end

      it "should show tabs for two tools and not display the 'more' tab'" do
        homework_submission_tool(2)
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_dom_ready
        f(".submit_assignment_link").click
        wait_for_ajax_requests
        expect(ff("li a.external-tool").length).to eq 2 
        expect(ff(".submit_from_external_tool_option").length).to eq 0
      end

      it "should allow submission for a tool that returns a file URL for a file assignment" do
        homework_submission_tool
        pick_submission_tool('#file_link')

        expect(f("#external_tool_url").attribute('value')).to match(/delete\.png/)
        expect(f("#external_tool_filename").attribute('value')).to eq('delete.png')
        expect(f("#external_tool_submission_type").attribute('value')).to eq('online_url_to_file')

        expect do
          f("#submit_from_external_tool_form .btn-primary").click
          wait_for_ajaximations
        end.to change(Delayed::Job, :count).by(1)

        Delayed::Job.last.invoke_job
        a = Attachment.last
        keep_trying_until { a.file_state == 'available' }
        keep_trying_until { !f("#submit_assignment").displayed? }
        submission = @assignment.find_or_create_submission(@user)
        expect(submission.submission_type).to eq 'online_upload'
        expect(submission.submitted_at).not_to be_nil
      end

      it "should allow submission for a tool that returns a URL for a URL assignment" do
        homework_submission_tool
        pick_submission_tool('#full_url_link')

        expect(f("#external_tool_url").attribute('value')).to match(/delete\.png/)
        expect(f("#external_tool_submission_type").attribute('value')).to eq('online_url')
        f("#submit_from_external_tool_form .btn-primary").click
        keep_trying_until { !f("#submit_assignment").displayed? }
        submission = @assignment.find_or_create_submission(@user)
        expect(submission.submission_type).to eq 'online_url'
        expect(submission.submitted_at).not_to be_nil
      end

      it "should fail if the tool tries to return any other type" do
        homework_submission_tool
        pick_submission_tool('#basic_lti_link')

        assert_invalid_selection_message
      end

      it "should fail if the tool returns a file type that isn't valid for the file assignment" do
        @assignment.update_attributes(:allowed_extensions => 'pdf,doc')
        expect(@assignment.reload.allowed_extensions).to eq ['pdf', 'doc']
        homework_submission_tool
        pick_submission_tool('#file_link')
        expect(f('#submit_from_external_tool_form .bad_ext_msg')).to be_displayed
        expect(f('#submit_from_external_tool_form .btn-primary')).to have_attribute('disabled', 'true')
        ff("#submit_assignment .cancel_button").select(&:displayed?).first.click
      end

      it "should allow submission for a valid type after an invalid submission" do
        @assignment.update_attributes(:allowed_extensions => 'pdf,doc')
        expect(@assignment.reload.allowed_extensions).to eq ['pdf', 'doc']
        homework_submission_tool
        pick_submission_tool('#file_link')
        select_submission_content('#full_url_link')
        expect(f('#submit_from_external_tool_form .bad_ext_msg')).not_to be_displayed
        expect(f('#submit_from_external_tool_form .btn-primary').attribute('disabled')).to be_nil
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

        expect(f("#external_tool_submission_type").attribute('value')).to eq('online_url_to_file')
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
          expect(f('.app_center')).to be_displayed
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
          f("#external_tool_#{ContextExternalTool.where(name: tool_name).first.id} .edit_tool_link").click
          expect(f('#external_tool_name')).to have_attribute(:value, tool_name)
          expect(f('#external_tool_shared_secret')).to have_attribute(:value, "")
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
        keep_trying_until { expect(ff("#basic_lti_link").size).to be > 0 }
      end
    end

    it "accepts an explicit launch type" do
      @tool.migration_selection = {}
      @tool.save!
      get "/courses/#{@course.id}/external_tools/#{@tool.id}?launch_type=migration_selection"
      in_frame('tool_content') do
        keep_trying_until { expect(ff("#basic_lti_link").size).to be > 0 }
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
        expect(f('#footer')).to be_displayed
        expect(f('#left-side')).not_to be_nil
        expect(f('#breadcrumbs')).not_to be_nil
        expect(f('body').attribute('class')).not_to include('full-width')
      end

      it "shows full width if top level property specified" do
        @tool.settings[:display_type] = "full_width"
        @tool.save!
        get "/courses/#{@course.id}/external_tools/#{@tool.id}"
        expect(f('#footer')).not_to be_displayed
        expect(f('#left-side')).to be_nil
        expect(f('#breadcrumbs')).to be_nil
        expect(f('body').attribute('class')).to include('full-width')
      end

      it "shows full width if extension property specified" do
        @tool.course_navigation[:display_type] = "full_width"
        @tool.save!
        get "/courses/#{@course.id}/external_tools/#{@tool.id}"
        expect(f('#footer')).not_to be_displayed
        expect(f('#left-side')).to be_nil
        expect(f('#breadcrumbs')).to be_nil
        expect(f('body').attribute('class')).to include('full-width')
      end
    end

    def frameResize(height)
      script = <<-SCRIPT
        parent.postMessage(JSON.stringify({subject: 'lti.frameResize', height: #{height}}), '*');
      SCRIPT
      driver.execute_script(script)
    end

    it 'resizes the iframe when receiving resize messages' do
      @tool.course_navigation = {}
      @tool.save!
      get "/courses/#{@course.id}/external_tools/#{@tool.id}"

      in_frame('tool_content') do
        frameResize(372)
      end
      expect(f('#tool_content').size.height).to eq(450)

      in_frame('tool_content') do
        frameResize(851)
      end
      expect(f('#tool_content').size.height).to eq(851)
    end
  end

  describe 'content migration launch through full-width redirect' do
    before do
      course_with_teacher_logged_in(active_all: true)
      @course.root_account.enable_feature!(:lor_for_account)
      @tool = @course.context_external_tools.create!(
          name: "new tool",
          consumer_key: "key",
          shared_secret: "secret",
          url: "http://#{HostUrl.default_host}/selection_test",
      )
      @tool.course_home_sub_navigation = {
          url: "http://#{HostUrl.default_host}/selection_test",
          text: "tool text",
          icon_url: "/images/add.png",
          display_type: 'full_width'
      }
      @tool.save!
    end

    it "should queue a content migration with content returned from the external tool" do
      get "/courses/#{@course.id}"
      tool_link = f('a.course-home-sub-navigation-lti')
      expect_new_page_load { tool_link.click }
      wait_for_ajaximations

      expect_new_page_load do
        in_frame('tool_content') do
          keep_trying_until { ff("#file_link").length > 0 }
          f("#file_link").click
        end
      end

      # should redirect to the content_migration page on success
      expect(driver.current_url).to match %r{/courses/\d+/content_migrations}
      expect(@course.content_migrations.count).to eq 1
    end

    it "should not show the link if the LOR feature flag is not enabled" do
      @course.root_account.disable_feature!(:lor_for_account)
      get "/courses/#{@course.id}"
      tool_link = f('a.course-home-sub-navigation-lti')
      expect(tool_link).to be_nil
    end
  end

  describe 'return url redirection' do
    before do
      course_with_teacher_logged_in(active_all: true)
      @tool = @course.context_external_tools.create!(
          name: "new tool",
          consumer_key: "key",
          shared_secret: "secret",
          url: "http://#{HostUrl.default_host}/selection_test",
      )
    end

    def return_from_tool
      expect(ff("#tool_content").length).to eq 1
      keep_trying_until { expect(f("#tool_content")).to be_displayed }

      expect_new_page_load do
        in_frame('tool_content') do
          keep_trying_until { ff("#basic_lti_link").length > 0 }
          f("#basic_lti_link").click
        end
      end
    end

    context "for external assignments" do
      before do
        assignment_model(:course => @course, :points_possible => 40, :submission_types => 'external_tool', :grading_type => 'points', :description => "fluffy ponies!")
        tag = @assignment.build_external_tool_tag(:url => @tool.url)
        tag.content_type = 'ContextExternalTool'
        tag.save!
        @mod = @course.context_modules.create! name: 'TestModule'
        @mod_item = @mod.add_item(:id => @assignment.id, :type => 'assignment')
      end

      it "should redirect back to the assignments page by default for an assignment tool" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        expect(f('.description').text).to match_ignoring_whitespace(@assignment.description)

        return_from_tool

        expect(driver.current_url).to match %r{/courses/\d+/assignments$}
      end

      it "should redirect back to the modules page if following a standard module item url" do
        next_item = @mod.add_item(:type => 'external_url', :url => "http://#{HostUrl.default_host}", :title => 'pls view')
        get "/courses/#{@course.id}/modules/items/#{@mod_item.id}"

        expect(f('#sequence_footer a.pull-right')['href']).to end_with "/courses/#{@course.id}/modules/items/#{next_item.id}"
        return_from_tool

        expect(driver.current_url).to match %r{/courses/\d+/modules$}
      end
    end

    context "for course navigation links" do
      before do
        settings = {
            url: "http://#{HostUrl.default_host}/selection_test",
            text: "tool text",
            icon_url: "/images/add.png",
            display_type: 'full_width'
        }
        [:course_navigation, :course_settings_sub_navigation].each do |type|
          @tool.send(:"#{type}=", settings)
        end
        @tool.save!
      end

      it "should return to course settings page for course_settings_sub_navigation launches" do
        Account.default.enable_feature!(:lor_for_account)
        get "/courses/#{@course.id}/settings"
        expect_new_page_load { f('.course-settings-sub-navigation-lti').click }

        return_from_tool

        expect(driver.current_url).to match %r{/courses/\d+/settings$}
      end

      it "should return to course home for course_navigation launches" do
        get "/courses/#{@course.id}"
        expect_new_page_load { f("a.context_external_tool_#{@tool.id}").click }

        return_from_tool

        expect(driver.current_url).to match %r{/courses/\d+$}
      end
    end

    it "should return to the modules page for external tool module items" do
      @mod = @course.context_modules.create! name: 'TestModule'
      @mod_item = @mod.add_item(:id => @tool.id, :type => 'external_tool', :url => @tool.url)

      get "/courses/#{@course.id}/modules/items/#{@mod_item.id}"

      return_from_tool

      expect(driver.current_url).to match %r{/courses/\d+/modules$}
    end

    it "should return to the dashboard for global navigation" do
      Account.default.enable_feature!(:lor_for_account)
      @tool = Account.default.context_external_tools.new(
          name: "new tool",
          consumer_key: "key",
          shared_secret: "secret",
          url: "http://#{HostUrl.default_host}/selection_test",
      )
      @tool.global_navigation = {:url => "http://#{HostUrl.default_host}/selection_test", :text => "Example URL 2"}
      @tool.save!

      get "/"
      expect_new_page_load {f("##{@tool.asset_string}_menu_item a").click }

      return_from_tool
      expect(driver.current_url).to eq "http://#{HostUrl.default_host}/"
    end

    it "should return to the account home page for account navigation" do
      user_session(site_admin_user)
      @tool = Account.default.context_external_tools.new(
          name: "new tool",
          consumer_key: "key",
          shared_secret: "secret",
          url: "http://#{HostUrl.default_host}/selection_test",
      )
      @tool.account_navigation = {:url => "http://#{HostUrl.default_host}/selection_test", :text => "Example URL 2"}
      @tool.save!

      get "/accounts/#{Account.default.id}"
      expect_new_page_load { f("a.context_external_tool_#{@tool.id}").click }

      return_from_tool

      expect(driver.current_url).to match %r{/accounts/\d+$}
    end

    it "should return to the user settings page for user navigation" do
      @tool = Account.default.context_external_tools.new(
          name: "new tool",
          consumer_key: "key",
          shared_secret: "secret",
          url: "http://#{HostUrl.default_host}/selection_test",
      )
      @tool.user_navigation = {:url => "http://#{HostUrl.default_host}/selection_test", :text => "Example URL 2"}
      @tool.save!

      get "/profile/settings"
      expect_new_page_load { f("a.context_external_tool_#{@tool.id}").click }

      return_from_tool

      expect(driver.current_url).to match %r{/about/\d+$}
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
