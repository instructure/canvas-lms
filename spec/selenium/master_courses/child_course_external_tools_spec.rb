require_relative '../common'

describe "master courses - child courses - external tool locking" do
  include_context "in-process server selenium tests"

  before :once do
    Account.default.enable_feature!(:master_courses)

    @copy_from = course_factory(:active_all => true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
    attributes = {:name => "new tool", :consumer_key => "key",
      :shared_secret => "secret", :custom_fields => {'a' => '1', 'b' => '2'}, :url => "http://www.example.com"}
    @original_tool = @copy_from.context_external_tools.create!(attributes)
    @tag = @template.create_content_tag_for!(@original_tool)

    course_with_teacher(:active_all => true)
    @copy_to = @course
    @template.add_child_course!(@copy_to)
    @tool_copy = @copy_to.context_external_tools.new(attributes) # just create a copy directly instead of doing a real migration
    @tool_copy.migration_id = @tag.migration_id
    @tool_copy.save!
  end

  before :each do
    user_session(@teacher)
  end

  it "should not show the cog-menu options on the index when locked" do
    @tag.update_attribute(:restrictions, {:content => true, :settings => true})

    get "/courses/#{@copy_to.id}/settings#tab-tools"

    expect(f('.master-course-cell')).to contain_css('.icon-lock')

    expect(f('.ExternalToolsTableRow')).to_not contain_css('.al-trigger')
  end

  it "should show the cog-menu options on the index when not locked" do
    get "/courses/#{@copy_to.id}/settings#tab-tools"

    expect(f('.master-course-cell')).to contain_css('.icon-unlock')

    expect(f('.ExternalToolsTableRow')).to contain_css('.al-trigger')
  end
end
