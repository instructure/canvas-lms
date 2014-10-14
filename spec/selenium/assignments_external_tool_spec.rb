require File.expand_path(File.dirname(__FILE__) + '/common')

describe "external tool assignments" do
  include_examples "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    @t1 = factory_with_protected_attributes(@course.context_external_tools, :url => "http://www.example.com/tool1", :shared_secret => 'test123', :consumer_key => 'test123', :name => 'tool 1')
    @t2 = factory_with_protected_attributes(@course.context_external_tools, :url => "http://www.example.com/tool2", :shared_secret => 'test123', :consumer_key => 'test123', :name => 'tool 2')
  end

  it "should allow creating" do
    get "/courses/#{@course.id}/assignments"

    #create assignment
    click_option('#right-side select.assignment_groups_select', 'Assignments')
    f('#right-side .add_assignment_link').click
    f('#assignment_title').send_keys('test1')
    f('.ui-datepicker-trigger').click
    datepicker = datepicker_next
    datepicker.find_element(:css, '.ui-datepicker-ok').click
    replace_content(f('#assignment_points_possible'), '5')
    click_option('.assignment_submission_types', 'External Tool')
    expect_new_page_load { f('.more_options_link').click }
    click_option('#assignment_submission_type', 'External Tool')
    f('#assignment_external_tool_tag_attributes_url').click
    keep_trying_until do
      fj('#context_external_tools_select td .tools .tool:first-child:visible').click
      wait_for_ajaximations
      #sleep 2 # wait for javascript to execute
      expect(f('#context_external_tools_select input#external_tool_create_url')).to have_attribute('value', @t1.url)
    end
    keep_trying_until do
      ff('#context_external_tools_select td .tools .tool')[1].click
      expect(f('#context_external_tools_select input#external_tool_create_url')).to have_attribute('value', @t2.url)
    end
    fj('.add_item_button:visible').click
    expect(f('#assignment_external_tool_tag_attributes_url')).to have_attribute('value', @t2.url)
    expect_new_page_load { submit_form('#edit_assignment_form') }

    a = @course.assignments(true).last
    expect(a).to be_present
    expect(a.submission_types).to eq 'external_tool'
    expect(a.external_tool_tag).to be_present
    expect(a.external_tool_tag.url).to eq @t2.url
    expect(a.external_tool_tag.new_tab).to be_falsey
  end

  it "should allow editing" do
    a = assignment_model(:course => @course, :title => "test2", :submission_types => 'external_tool', :due_at => Time.zone.now + 1.days)
    a.create_external_tool_tag(:url => @t1.url)
    a.external_tool_tag.update_attribute(:content_type, 'ContextExternalTool')

    get "/courses/#{@course.id}/assignments/#{a.id}/edit"
    # don't display dialog on page load, since url isn't blank
    expect(f('#context_external_tools_select')).not_to be_displayed
    f('#assignment_external_tool_tag_attributes_url').click
    ff('#context_external_tools_select td .tools .tool')[0].click
    expect(f('#context_external_tools_select input#external_tool_create_url')).to have_attribute('value', @t1.url)
    fj('.add_item_button:visible').click
    expect(f('#assignment_external_tool_tag_attributes_url')).to have_attribute('value', @t1.url)

    expect_new_page_load { submit_form('#edit_assignment_form') }

    a.reload
    expect(a.submission_types).to eq 'external_tool'
    expect(a.external_tool_tag).to be_present
    expect(a.external_tool_tag.url).to eq @t1.url
  end
end
