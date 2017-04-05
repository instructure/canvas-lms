require_relative '../common'

describe "master courses - child courses - assignment locking" do
  include_context "in-process server selenium tests"

  before :once do
    Account.default.enable_feature!(:master_courses)

    @copy_from = course_factory(:active_all => true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
    @original_assmt = @copy_from.assignments.create!(:title => "blah", :description => "bloo")
    @tag = @template.create_content_tag_for!(@original_assmt)

    course_with_teacher(:active_all => true)
    @copy_to = @course
    @template.add_child_course!(@copy_to)
    @assmt_copy = @copy_to.assignments.new(:title => "blah", :description => "bloo") # just create a copy directly instead of doing a real migration
    @assmt_copy.migration_id = @tag.migration_id
    @assmt_copy.save!
  end

  before :each do
    user_session(@teacher)
  end

  it "should not allow the delete cog-menu option on the index when locked" do
    @tag.update_attribute(:restrictions, {:content => true})

    get "/courses/#{@copy_to.id}/assignments"

    expect(f('.master-course-cell')).to contain_css('.icon-lock')

    f('.al-trigger').click
    expect(f('.assignment')).to contain_css('a.delete_assignment.disabled')
  end

  it "should show the delete cog-menu option on the index when not locked" do
    get "/courses/#{@copy_to.id}/assignments"

    expect(f('.master-course-cell')).to contain_css('.icon-unlock')

    f('.al-trigger').click
    expect(f('.assignment')).to_not contain_css('a.delete_assignment.disabled')
    expect(f('.assignment')).to contain_css('a.delete_assignment')
  end

  it "should not allow the delete options on the edit page when locked" do
    @tag.update_attribute(:restrictions, {:content => true})

    get "/courses/#{@copy_to.id}/assignments/#{@assmt_copy.id}/edit"

    f('.al-trigger').click
    expect(f('#edit_assignment_header')).to contain_css('a.delete_assignment_link.disabled')
  end

  it "should show the delete cog-menu options on the edit when not locked" do
    get "/courses/#{@copy_to.id}/assignments/#{@assmt_copy.id}/edit"

    f('.al-trigger').click
    expect(f('#edit_assignment_header')).to_not contain_css('a.delete_assignment_link.disabled')
    expect(f('#edit_assignment_header')).to contain_css('a.delete_assignment_link')
  end
end
