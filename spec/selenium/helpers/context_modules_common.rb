#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../common')

module ContextModulesCommon
  def io
    fixture_file_upload('scribd_docs/txt.txt', 'text/plain', true)
  end


  def create_modules(number_to_create, published=false)
    modules = []
    number_to_create.times do |i|
      m = @course.context_modules.create!(:name => "module #{i}")
      m.unpublish! unless published
      modules << m
    end
    modules
  end

  def publish_module
    fj('#context_modules .publish-icon-publish').click
    wait_for_ajaximations
  end

  def unpublish_module
    fj('#context_modules .publish-icon-published').click
    wait_for_ajaximations
  end

  def module_setup
    @module = @course.context_modules.create!(:name => "module")

    #create module items
    #add first and last module items to get previous and next displayed
    @assignment1 = @course.assignments.create!(:title => 'first item in module')
    @assignment2 = @course.assignments.create!(:title => 'assignment')
    @assignment3 = @course.assignments.create!(:title => 'last item in module')
    @quiz = @course.quizzes.create!(:title => 'quiz assignment')
    @quiz.publish!
    @wiki = @course.wiki_pages.create!(:title => "wiki", :body => 'hi')
    @discussion = @course.discussion_topics.create!(:title => 'discussion')

    #add items to module
    @module.add_item :type => 'assignment', :id => @assignment1.id
    @module.add_item :type => 'assignment', :id => @assignment2.id
    @module.add_item :type => 'quiz', :id => @quiz.id
    @module.add_item :type => 'wiki_page', :id => @wiki.id
    @module.add_item :type => 'discussion_topic', :id => @discussion.id
    @module.add_item :type => 'assignment', :id => @assignment3.id

    # add external tool
    @tool = @course.context_external_tools.create!(:name => "new tool", :consumer_key => "key",
                                                   :shared_secret => "secret", :domain => 'example.com',
                                                   :custom_fields => {'a' => '1', 'b' => '2'})
    @external_tool_tag = @module.add_item({
                                            :type => 'context_external_tool',
                                            :title => 'Example',
                                            :url => 'http://www.example.com',
                                            :new_tab => '0'
                                          })
    @external_tool_tag.publish!
    #add external url
    @external_url_tag = @module.add_item({
                                           :type => 'external_url',
                                           :title => 'pls view',
                                           :url => 'http://example.com/lolcats'
                                         })
    @external_url_tag.publish!

    #add another assignment at the end to create a bookend, provides next and previous for external url
    @module.add_item :type => 'assignment', :id => @assignment3.id
  end

  def test_relock
    wait_for_ajaximations
    expect(f('#relock_modules_dialog')).to be_displayed
    expect_any_instance_of(ContextModule).to receive(:relock_progressions).once
    fj(".ui-dialog:visible .ui-button:first-child").click
    wait_for_ajaximations
  end

  def create_context_module(module_name)
    context_module = @course.context_modules.create!(:name => module_name, :require_sequential_progress => true)
    context_module
  end

  def go_to_modules
    get "/courses/#{@course.id}/modules"
  end

  def validate_context_module_status_icon(module_id, icon_expected)
    if icon_expected == 'no-icon'
      expect(fj("#context_module_#{module_id}")).not_to contain_jqcss(".completion_status i:visible")
    else
      expect(fj("#context_module_#{module_id} .completion_status i:visible")).to be_present
      context_modules_status = f("#context_module_#{module_id} .completion_status")
      expect(context_modules_status.find_element(:css, '.' + icon_expected)).to be_displayed
    end
  end

  def verify_next_and_previous_buttons_display
    wait_for_ajaximations
    expect(f('.module-sequence-footer-button--previous')).to be_displayed
    expect(f('.module-sequence-footer-button--next')).to be_displayed
  end

  def validate_context_module_item_icon(module_item_id, icon_expected)
    if icon_expected == 'no-icon'
      expect(f("#context_module_item_#{module_item_id}")).not_to contain_jqcss(".module-item-status-icon i:visible")
    else
      expect(fj("#context_module_item_#{module_item_id} .module-item-status-icon i:visible")).to be_present
      item_status = f("#context_module_item_#{module_item_id} .module-item-status-icon")
      expect(item_status.find_element(:css, '.' + icon_expected)).to be_displayed
    end
  end

  def vaildate_correct_pill_message(module_id, message_expected)
    pill_message = f("#context_module_#{module_id} .requirements_message li").text
    expect(pill_message).to eq message_expected
  end

  def navigate_to_module_item(module_num, link_text)
    context_modules = ff('.context_module')
    expect_new_page_load { context_modules[module_num].find_element(:link, link_text).click }
    go_to_modules
  end

  def mark_as_done_setup
    @mark_done_module = create_context_module('Mark Done Module')
    page = @course.wiki_pages.create!(:title => "The page", :body => 'hi')
    @tag = @mark_done_module.add_item({:id => page.id, :type => 'wiki_page'})
    @mark_done_module.completion_requirements = {@tag.id => {:type => 'must_mark_done'}}
    @mark_done_module.save!
  end

  def navigate_to_wikipage(title)
    els = ff('.context_module_item')
    el = els.find {|e| e.text =~ /#{title}/}
    el.find_element(:css, 'a.title').click
    wait_for_ajaximations
  end

  def create_additional_assignment_for_module_1
    @assignment_4 = @course.assignments.create!(:title => "assignment 4")
    @tag_4 = @module_1.add_item({:id => @assignment_4.id, :type => 'assignment'})
    @module_1.completion_requirements = {@tag_1.id => {:type => 'must_view'},
                                         @tag_4.id => {:type => 'must_view'}}
    @module_1.save!
  end

  def make_module_1_complete_one
    @module_1.requirement_count = 1
    @module_1.save!
  end

  def assert_page_loads
    get "/courses/#{@course.id}/modules"
    expect(f('.name').text).to eq "some module"
  end

  def add_existing_module_item(item_select_selector, module_name, item_name)
    add_module(module_name + 'Module')
    f('.ig-header-admin .al-trigger').click
    wait_for_ajaximations
    f('.add_module_item_link').click
    wait_for_ajaximations
    select_module_item('#add_module_item_select', module_name)
    select_module_item(item_select_selector + ' .module_item_select', item_name)
    scroll_to(fj('.add_item_button.ui-button'))
    fj('.add_item_button.ui-button').click
    wait_for_ajaximations
    tag = ContentTag.last
    fj("#context_module_item_#{tag.id}:contains(#{item_name.inspect})")
  end

  def select_module_item(select_element_css, item_text)
    click_option(select_element_css, item_text)
  end

  def new_module_form
    f(".add_module_link").click
    fj('#add_context_module_form:visible')
  end

  def add_module(module_name = 'Test Module')
    wait_for_modules_ui
    add_form = new_module_form
    replace_content(add_form.find_element(:id, 'context_module_name'), module_name)
    submit_form(add_form)
    wait_for_ajaximations
    expect(add_form).not_to be_displayed
    expect(f('#context_modules')).to include_text(module_name)
  end

  def add_new_module_item(item_select_selector, module_name, new_item_text, item_title_text)
    f('.ig-header-admin .al-trigger').click
    f('.add_module_item_link').click
    select_module_item('#add_module_item_select', module_name)
    select_module_item(item_select_selector + ' .module_item_select', new_item_text)
    item_title = fj('.item_title:visible')
    expect(item_title).to be_displayed
    replace_content(item_title, item_title_text)
    yield if block_given?
    f('.add_item_button.ui-button').click
    wait_for_ajaximations
    tag = ContentTag.last
    module_item = f("#context_module_item_#{tag.id}")
    expect(module_item).to include_text(item_title_text)
  end

  def add_new_external_item(module_item, url_text, page_name_text)
    f('.ig-header-admin .al-trigger').click
    f('.add_module_item_link').click
    select_module_item('#add_module_item_select', module_item)
    url_input = fj('input[name="url"]:visible')
    title_input = fj('input[name="title"]:visible')
    replace_content(url_input, url_text)

    replace_content(title_input, page_name_text)
    scroll_to(fj('.add_item_button.ui-button'))
    fj('.add_item_button.ui-button').click
    wait_for_ajaximations
    tag = ContentTag.last
    module_item = f("#context_module_item_#{tag.id}")
    expect(module_item).to include_text(page_name_text)
    tag
  end

  def course_module
    @module = @course.context_modules.create!(:name => "some module")
  end

  def add_modules_and_set_prerequisites
    @module1 = @course.context_modules.create!(:name => "First module")
    @module2 = @course.context_modules.create!(:name => "Second module")
    @module3 = @course.context_modules.create!(:name => "Third module")
    @module3.prerequisites = "module_#{@module1.id},module_#{@module2.id}"
    @module3.save!
  end

  def add_non_requirement
    @assignment_4 = @course.assignments.create!(:title => "assignment 4")
    @tag_4 = @module_1.add_item({:id => @assignment_4.id, :type => 'assignment'})
    @module_1.save!
  end

  def add_min_score_assignment
    @assignment_4 = @course.assignments.create!(:title => "assignment 4")
    @tag_4 = @module_1.add_item({:id => @assignment_4.id, :type => 'assignment'})
    @module_1.completion_requirements = {@tag_1.id => {:type => 'must_view'},
                                         @tag_4.id => {:type => 'min_score', :min_score => 90}}
    @module_1.require_sequential_progress = false
    @module_1.save!
  end

  def make_past_due
    @assignment_4.submission_types = 'online_text_entry'
    @assignment_4.due_at = '2015-01-01'
    @assignment_4.save!
  end

  def grade_assignment(score)
    @assignment_4.grade_student(@user, grade: score, grader: @teacher)
  end

  def edit_module_item(module_item)
    module_item.find_element(:css, '.al-trigger').click
    wait_for_ajaximations
    module_item.find_element(:css, '.edit_item_link').click
    edit_form = f('#edit_item_form')
    yield edit_form
    submit_dialog_form(edit_form)
    wait_for_ajaximations
  end

  def verify_persistence(title)
    refresh_page
    verify_module_title(title)
  end

  def verify_module_title(title)
    expect(f('#context_modules')).to include_text(title)
  end

  def need_to_wait_for_modules_ui?
    !@already_waited_for_modules_ui
  end

  def wait_for_modules_ui
    return unless need_to_wait_for_modules_ui?
    # context_modules.js has some setTimeout(..., 1000) calls
    # before it adds click handlers and drag/drop
    sleep 2
    @already_waited_for_modules_ui = true
  end

   def verify_edit_item_form
     f('.context_module_item .al-trigger').click
     wait_for_ajaximations
     f('.edit_item_link').click
     wait_for_ajaximations
     expect(f('#edit_item_form')).to be_displayed
     expect(f('#content_tag_title')).to be_displayed
     expect(f('#content_tag_indent_select')).to be_displayed
   end

  def lock_check_click(form)
    move_to_click('label[for=unlock_module_at]')
  end

  # so terrible
  def get(url)
    @already_waited_for_modules_ui = false
    super
    wait_for_modules_ui if url =~ %r{\A/courses/\d+/modules\z}
  end
end
