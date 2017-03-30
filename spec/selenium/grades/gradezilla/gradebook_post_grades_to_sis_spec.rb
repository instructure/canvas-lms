require_relative '../../helpers/gradezilla_common'
require_relative '../page_objects/gradezilla_page'

describe "Gradezilla - post grades to SIS" do
  include GradezillaCommon
  include_context "in-process server selenium tests"

  let(:gradezilla_page) { Gradezilla::MultipleGradingPeriods.new }

  before(:once) do
    gradebook_data_setup
    create_sis_assignment
  end

  before(:each) do
    Account.default.set_feature_flag!('gradezilla', 'on')
    user_session(@teacher)
  end

  after(:each) do
    clear_local_storage
  end

  def create_sis_assignment
    @assignment.post_to_sis = true
    @assignment.workflow_state = 'published'
    @assignment.save
  end

  def export_plugin_setting
    plugin = Canvas::Plugin.find('grade_export')
    plugin_setting = PluginSetting.find_by(name: plugin.id)
    plugin_setting || PluginSetting.new(name: plugin.id, settings: plugin.default_settings)
  end

  describe "Plugin" do
    before(:once) { export_plugin_setting.update(disabled: false) }

    it "should not be visible by default", priority: "1", test_id: 244958 do
      gradezilla_page.visit(@course)
      gradezilla_page.open_action_menu

      expect(f('body')).not_to contain_css(gradezilla_page.action_menu_item_selector('post_grades_feature_tool'))
    end

    it "should be visible when enabled on course with sis_source_id" do
      Account.default.set_feature_flag!('post_grades', 'on')
      @course.sis_source_id = 'xyz'
      @course.save

      gradezilla_page.visit(@course)
      gradezilla_page.open_action_menu

      expect(f('body')).to contain_css(gradezilla_page.action_menu_item_selector('post_grades_feature_tool'))
    end

    it "containing menu should not be displayed if viewing outcome gradebook", priority: "1", test_id: 244959 do
      Account.default.set_feature_flag!('post_grades', 'on')
      Account.default.set_feature_flag!('outcome_gradebook', 'on')
      @course.sis_source_id = 'xyz'
      @course.save

      gradezilla_page.visit(@course)
      gradezilla_page.open_gradebook_dropdown_menu
      gradezilla_page.select_menu_item('learning-mastery')

      expect(gradezilla_page.action_menu).not_to be_displayed
    end

    it 'does not show assignment errors when clicking the post grades button if all ' \
      'assignments have due dates for each section', priority: '1', test_id: 3036003 do
      Account.default.set_feature_flag!('post_grades', 'on')

      @course.update!(sis_source_id: 'xyz')
      @course.course_sections.each do |section|
        @attendance_assignment.assignment_overrides.create! do |override|
          override.set = section
          override.title = 'section override'
          override.due_at = Time.zone.now
          override.due_at_overridden = true
        end
      end
      gradezilla_page.visit(@course)
      gradezilla_page.open_action_menu
      gradezilla_page.select_action_menu_item('post_grades_feature_tool')

      expect(f('.post-grades-dialog')).not_to contain_css('#assignment-errors')
    end
  end

  describe 'LTI' do
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
      post_grades_tool
    end

    let!(:tool) { create_post_grades_tool }
    let(:tool_name) { "post_grades_lti_#{tool.id}" }

    it "should show when a post_grades lti tool is installed", priority: "1", test_id: 244960 do
      gradezilla_page.visit(@course)
      gradezilla_page.open_action_menu

      expect(gradezilla_page.action_menu_item(tool_name)).to be_displayed

      gradezilla_page.select_action_menu_item(tool_name)

      expect(f('iframe.post-grades-frame')).to be_displayed
    end

    it "should show post grades lti button when only one section available" do
      course = Course.new(name: 'Math 201', account: @account, sis_source_id: 'xyz')
      course.save
      course.enroll_teacher(@user).accept!
      course.assignments.create!(name: 'Assignment1', post_to_sis: true)
      create_post_grades_tool(course: course)

      gradezilla_page.visit(@course)
      gradezilla_page.open_action_menu

      expect(gradezilla_page.action_menu_item(tool_name)).to be_displayed

      gradezilla_page.select_action_menu_item(tool_name)

      expect(f('iframe.post-grades-frame')).to be_displayed
    end

    it "should not hide post grades lti button when section selected", priority: "1", test_id: 248027 do
      create_post_grades_tool

      gradezilla_page.visit(@course)
      gradezilla_page.open_action_menu

      expect(gradezilla_page.action_menu_item(tool_name)).to be_displayed

      f('button.section-select-button').click
      fj('ul#section-to-show-menu li:nth(4)').click
      gradezilla_page.open_action_menu

      expect(gradezilla_page.action_menu_item(tool_name)).to be_displayed
    end
  end
end
