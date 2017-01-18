require_relative '../../helpers/gradebook2_common'

describe "gradebook2 - post grades to SIS" do
  include Gradebook2Common
  include_context "in-process server selenium tests"

  before(:each) do
    gradebook_data_setup
    create_sis_assignment
  end

  def create_sis_assignment
    @assignment.post_to_sis = true
    @assignment.save
  end

  it "should not be visible by default", priority: "1", test_id: 244958 do
    get "/courses/#{@course.id}/gradebook2"
    expect(f("body")).not_to contain_css('.post-grades-placeholder')
  end

  it "should be visible when enabled on course with sis_source_id" do
    Account.default.set_feature_flag!('post_grades', 'on')
    @course.sis_source_id = 'xyz'
    @course.save
    get "/courses/#{@course.id}/gradebook2"
    expect(ff('.post-grades-placeholder').length).to eq 1
  end

  it "should not be displayed if viewing outcome gradebook", priority: "1", test_id: 244959 do
    Account.default.set_feature_flag!('post_grades', 'on')
    Account.default.set_feature_flag!('outcome_gradebook', 'on')
    @course.sis_source_id = 'xyz'
    @course.save

    get "/courses/#{@course.id}/gradebook2"

    f('a[data-id=outcome]').click
    wait_for_ajaximations
    expect(f('.post-grades-placeholder')).not_to be_displayed

    f('a[data-id=assignment]').click
    wait_for_ajaximations

    expect(f('.post-grades-placeholder')).to be_displayed
  end

  it "should display post grades button when powerschool is configured", priority: "1", test_id: 164219 do
    Account.default.set_feature_flag!('post_grades', 'on')
    @course.sis_source_id = 'xyz'
    @course.save
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    expect(f('.post-grades-placeholder > button')).to be_displayed
    f('.post-grades-placeholder > button').click
    wait_for_ajaximations
    expect(f('.post-grades-dialog')).to be_displayed
  end

  context 'post grades button' do
    def create_post_grades_tool(opts={})
      course = opts[:course] || @course
      post_grades_tool = course.context_external_tools.create!(
        name: opts[:name] || 'test tool',
        domain: 'example.com',
        url: 'http://example.com/lti',
        consumer_key: 'key',
        shared_secret: 'secret',
        settings: {
          post_grades: {
            url: 'http://example.com/lti/post_grades'
          }
        }
      )
      post_grades_tool.context_external_tool_placements.create!(placement_type: 'post_grades')
      post_grades_tool
    end

    it "should show when a post_grades lti tool is installed", priority: "1", test_id: 244960 do
      create_post_grades_tool

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      expect(f('button.external-tools-dialog')).to be_displayed
      f('button.external-tools-dialog').click
      wait_for_ajaximations
      expect(f('iframe.post-grades-frame')).to be_displayed
    end

    it "should show post grades lti button when only one section available" do
      course = Course.new(course_name: 'Math 201', account: @account, active_course: true, sis_source_id: 'xyz')
      course.save
      course.enroll_teacher(@user).accept!
      course.assignments.create!(name: 'Assignment1', post_to_sis: true)
      create_post_grades_tool(course: course)

      get "/courses/#{course.id}/gradebook2"
      wait_for_ajaximations
      expect(f('button.external-tools-dialog')).to be_displayed
      f('button.external-tools-dialog').click
      wait_for_ajaximations
      expect(f('iframe.post-grades-frame')).to be_displayed
    end

    it "should not hide post grades lti button when section selected", priority: "1", test_id: 248027 do
      create_post_grades_tool

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      expect(f('button.external-tools-dialog')).to be_displayed

      f('button.section-select-button').click
      wait_for_ajaximations
      fj('ul#section-to-show-menu li:nth(4)').click
      wait_for_ajaximations
      expect(f('button.external-tools-dialog')).to be_displayed
    end

    it "should show as drop down menu when multiple tools are installed", priority: "1", test_id: 244920 do
      (0...10).each do |i|
        create_post_grades_tool(name: "test tool #{i}")
      end

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      expect(ff('li.external-tools-dialog').count).to eq(10)
      expect(f('#post_grades .icon-mini-arrow-down')).to be_displayed
      move_to_click('button#post_grades')
      wait_for_ajaximations
      ff('li.external-tools-dialog > a').first.click
      wait_for_ajaximations
      expect(f('iframe.post-grades-frame')).to be_displayed
    end

    it "should not hide post grades lti dropdown when section selected", priority: "1", test_id: 248027 do
      (0...10).each do |i|
        create_post_grades_tool(name: "test tool #{i}")
      end

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      expect(ff('li.external-tools-dialog').count).to eq(10)

      f('button.section-select-button').click
      wait_for_ajaximations
      fj('ul#section-to-show-menu li:nth(4)').click
      wait_for_ajaximations
      expect(f('button#post_grades')).to be_displayed
    end

    it "should show as drop down menu with an ellipsis when too many " \
      "tools are installed", priority: "1", test_id: 244961 do
      (0...11).each do |i|
        create_post_grades_tool(name: "test tool #{i}")
      end

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      expect(ff('li.external-tools-dialog').count).to eq(11)
      # check for ellipsis (we only display top 10 added tools)
      expect(ff('li.external-tools-dialog.ellip').count).to eq(1)
    end

    it "should show as drop down menu when powerschool is configured " \
      "and an lti tool is installed", priority: "1", test_id: 244962 do
      Account.default.set_feature_flag!('post_grades', 'on')
      @course.sis_source_id = 'xyz'
      @course.save
      @assignment.post_to_sis = true
      @assignment.save

      create_post_grades_tool

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      expect(f('li.post-grades-placeholder > a')).to be_present
      expect(f('li.external-tools-dialog')).to be_present

      expect(f('#post_grades .icon-mini-arrow-down')).to be_displayed
      move_to_click('button#post_grades')
      wait_for_ajaximations
      f('li.post-grades-placeholder > a').click
      wait_for_ajaximations
      expect(f('.post-grades-dialog')).to be_displayed
      # close post grade dialog
      fj('.ui-icon-closethick:visible').click

      expect(f('#post_grades .icon-mini-arrow-down')).to be_displayed
      move_to_click('button#post_grades')
      wait_for_ajaximations
      ff('li.external-tools-dialog > a').first.click
      wait_for_ajaximations
      expect(f('iframe.post-grades-frame')).to be_displayed
    end

    it "should show menu with powerschool if section configured and selected and lti tools are disabled" do
      Account.default.set_feature_flag!('post_grades', 'on')
      @course.sis_source_id = 'xyz'
      @course.save
      @assignment.post_to_sis = true
      @assignment.save

      CourseSection.all.each_with_index do |course_section, index|
        course_section.sis_source_id = index.to_s
        course_section.save
      end

      create_post_grades_tool

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      expect(f('li.post-grades-placeholder > a')).to be_present
      expect(f('li.external-tools-dialog')).to be_present

      section_id = fj('ul#section-to-show-menu li:nth(3) a label')['for']
      section_id.slice!('section_option_')

      f('button.section-select-button').click
      wait_for_ajaximations
      fj('ul#section-to-show-menu li:nth(4)').click
      wait_for_ajaximations
      expect(f('button#post_grades')).to be_displayed

      f('button#post_grades').click
      wait_for_ajaximations
      f('li.post-grades-placeholder > a').click
      wait_for_ajaximations
      expect(f('.post-grades-dialog')).to be_displayed
    end
  end
end
