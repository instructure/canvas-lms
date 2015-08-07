require File.expand_path(File.dirname(__FILE__) + '/helpers/context_modules_common')

describe "context modules" do
  include_context "in-process server selenium tests"
  context "menu tools", priority: "1" do
      before do
        course_with_teacher_logged_in
        Account.default.enable_feature!(:lor_for_account)

        @tool = Account.default.context_external_tools.new(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
        @tool.assignment_menu = {:url => "http://www.example.com", :text => "Export Assignment"}
        @tool.module_menu = {:url => "http://www.example.com", :text => "Export Module"}
        @tool.quiz_menu = {:url => "http://www.example.com", :text => "Export Quiz"}
        @tool.wiki_page_menu = {:url => "http://www.example.com", :text => "Export Wiki Page"}
        @tool.save!

        @module1 = @course.context_modules.create!(:name => "module1")
        @assignment = @course.assignments.create!(:name => "pls submit", :submission_types => ["online_text_entry"], :points_possible => 20)
        @assignment_tag = @module1.add_item(:id => @assignment.id, :type => 'assignment')
        @quiz = @course.quizzes.create!(:title => "score 10")
        @quiz.publish!
        @quiz_tag = @module1.add_item(:id => @quiz.id, :type => 'quiz')
        @wiki_page = @course.wiki.wiki_pages.create!(:title => 'title', :body => '')
        @wiki_page.workflow_state = 'active'
        @wiki_page.save!
        @wiki_page_tag = @module1.add_item(:id => @wiki_page.id, :type => 'wiki_page')
        @subheader_tag = @module1.add_item(:type => 'context_module_sub_header', :title => 'subheader')
      end

      def should_have_menu_tool_link_in_gear
        gear = f("#context_module_#{@module1.id} .header .al-trigger")
        gear.click
        link = f("#context_module_#{@module1.id} .header li a.menu_tool_link")
        expect(link).to be_displayed
        expect(link.text).to match_ignoring_whitespace(@tool.label_for(:module_menu))
        expect(link['href']).to eq course_external_tool_url(@course, @tool, launch_type: 'module_menu', :modules => [@module1.id])
      end

      it "should show tool launch links in the gear for modules" do
        get "/courses/#{@course.id}/modules"
        should_have_menu_tool_link_in_gear
      end

      it "should show tool launch links in the gear for modules on course home if set to modules" do
        @course.default_view = 'modules'
        @course.save!
        get "/courses/#{@course.id}"
        should_have_menu_tool_link_in_gear
      end

      it "should not render tool links unless the lor flag is enabled" do
        Account.default.disable_feature!(:lor_for_account)
        get "/courses/#{@course.id}/modules"
        gear = f("#context_module_#{@module1.id} .header .al-trigger")
        gear.click
        link = f("#context_module_#{@module1.id} .header li a.menu_tool_link")
        expect(link).to be_nil
      end

      it "should show tool launch links in the gear for exportable module items" do
        get "/courses/#{@course.id}/modules"
        type_to_tag = {
            :assignment_menu => @assignment_tag,
            :quiz_menu => @quiz_tag,
            :wiki_page_menu => @wiki_page_tag
        }
        type_to_tag.each do |type, tag|
          gear = f("#context_module_item_#{tag.id} .al-trigger")
          gear.click

          type_to_tag.keys.each do |other_type|
            next if other_type == type
            expect(f("#context_module_item_#{tag.id} li.#{other_type} a.menu_tool_link")).to be_nil
          end

          link = f("#context_module_item_#{tag.id} li.#{type} a.menu_tool_link")
          expect(link).to be_displayed
          expect(link.text).to match_ignoring_whitespace(@tool.label_for(type))
          expect(link['href']).to eq course_external_tool_url(@course, @tool, launch_type: type, :module_items => [tag.id])
        end

        gear = f("#context_module_item_#{@subheader_tag.id} .al-trigger")
        gear.click
        link = f("#context_module_item_#{@subheader_tag.id} a.menu_tool_link")
        expect(link).to be_nil
      end

      it "should add links to newly created modules" do
        get "/courses/#{@course.id}/modules"
        wait_for_modules_ui

        f(".add_module_link").click
        wait_for_ajaximations
        form = f('#add_context_module_form')
        replace_content(form.find_element(:id, 'context_module_name'), 'new module')
        submit_form(form)
        wait_for_ajaximations

        new_module = ContextModule.last
        expect(new_module.name).to eq 'new module'

        gear = f("#context_module_#{new_module.id} .header .al-trigger")
        gear.click
        link = f("#context_module_#{new_module.id} .header li a.menu_tool_link")
        expect(link).to be_displayed
        expect(link.text).to match_ignoring_whitespace(@tool.label_for(:module_menu))
        expect(link['href']).to eq course_external_tool_url(@course, @tool, launch_type: 'module_menu', :modules => [new_module.id])
      end

      it "should add links to newly created module items" do
        get "/courses/#{@course.id}/modules"
        wait_for_modules_ui
        f("#context_module_#{@module1.id} .add_module_item_link").click
        wait_for_ajaximations

        click_option('#add_module_item_select', 'wiki_page', :value)
        click_option('#wiki_pages_select .module_item_select', 'new', :value)
        replace_content(f('#wiki_pages_select .item_title'), 'new page')
        fj('.add_item_button.ui-button').click
        wait_for_ajaximations

        new_page = WikiPage.last
        expect(new_page.title).to eq 'new page'

        new_tag = ContentTag.last
        expect(new_tag.content).to eq new_page

        gear = f("#context_module_item_#{new_tag.id} .al-trigger")
        gear.click

        [:assignment_menu, :quiz_menu].each do |other_type|
          link = f("#context_module_item_#{new_tag.id} li.#{other_type} a.menu_tool_link")
          expect(link).not_to be_displayed
        end

        link = f("#context_module_item_#{new_tag.id} li.wiki_page_menu a.menu_tool_link")
        expect(link).to be_displayed
        expect(link.text).to match_ignoring_whitespace(@tool.label_for(:wiki_page_menu))
        expect(link['href']).to eq course_external_tool_url(@course, @tool, launch_type: 'wiki_page_menu', :module_items => [new_tag.id])
      end

      it "should not show add links to newly created module items if not exportable" do
        get "/courses/#{@course.id}/modules"
        wait_for_modules_ui

        f("#context_module_#{@module1.id} .add_module_item_link").click
        wait_for_ajaximations
        click_option('#add_module_item_select', 'external_url', :value)
        replace_content(f('#content_tag_create_url'), 'http://www.example.com')
        replace_content(f('#content_tag_create_title'), 'new item')

        fj('.add_item_button.ui-button').click
        wait_for_ajaximations

        new_tag = ContentTag.last

        gear = f("#context_module_item_#{new_tag.id} .al-trigger")
        gear.click
        link = f("#context_module_item_#{new_tag.id} li.ui-menu-item a.menu_tool_link")
        expect(link).not_to be_displayed
      end
  end
end
