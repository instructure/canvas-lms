require_relative '../common'

describe "master courses - child courses - discussion locking" do
  include_context "in-process server selenium tests"

  before :once do
    Account.default.enable_feature!(:master_courses)

    @copy_from = course_factory(:active_all => true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
    @original_topic = @copy_from.discussion_topics.create!(:title => "blah", :message => "bloo")
    @tag = @template.create_content_tag_for!(@original_topic)

    course_with_teacher(:active_all => true)
    @copy_to = @course
    @topic_copy = @copy_to.discussion_topics.new(:title => "blah", :message => "bloo") # just create a copy directly instead of doing a real migration
    @topic_copy.migration_id = @tag.migration_id
    @topic_copy.save!
  end

  before :each do
    user_session(@teacher)
  end

  it "should not show the cog-menu options on the index when locked" do
    @tag.update_attribute(:restrictions, {:content => true, :settings => true})

    get "/courses/#{@copy_to.id}/discussion_topics"

    expect(f('.master-course-cell')).to contain_css('.icon-lock')

    expect(f('.discussion-row')).to_not contain_css('.al-trigger')
  end

  it "should show the cog-menu options on the index when not locked" do
    get "/courses/#{@copy_to.id}/discussion_topics"

    expect(f('.master-course-cell')).to contain_css('.icon-unlock')

    expect(f('.discussion-row')).to contain_css('.al-trigger')
  end

  it "should not show the edit/delete options on the show page when locked" do
    @tag.update_attribute(:restrictions, {:content => true, :settings => true})

    get "/courses/#{@copy_to.id}/discussion_topics/#{@topic_copy.id}"

    expect(f('#content')).to_not contain_css('.edit-btn')
    f('.al-trigger').click
    expect(f('.al-options')).to_not contain_css('.delete_discussion')
  end

  it "should show the edit/delete cog-menu options on the show when not locked" do
    get "/courses/#{@copy_to.id}/discussion_topics/#{@topic_copy.id}"

    expect(f('#content')).to contain_css('.edit-btn')
    f('.al-trigger').click
    expect(f('.al-options')).to contain_css('.delete_discussion')
  end

  context "announcements" do
    before :once do
      @original_topic.update_attribute(:type, 'Announcement')
      @topic_copy.update_attribute(:type, 'Announcement')
    end

    it "should not show the cog-menu options on the index when locked" do
      @tag.update_attribute(:restrictions, {:content => true, :settings => true})

      get "/courses/#{@copy_to.id}/announcements"

      expect(f('.master-course-cell')).to contain_css('.icon-lock')

      expect(f('.discussion-topic')).to_not contain_css('.al-trigger')
    end

    it "should show the cog-menu options on the index when not locked" do
      get "/courses/#{@copy_to.id}/announcements"

      expect(f('.master-course-cell')).to contain_css('.icon-unlock')

      expect(f('.discussion-topic')).to contain_css('.al-trigger')
    end

    it "should not show the edit/delete options on the show page when locked" do
      @tag.update_attribute(:restrictions, {:content => true, :settings => true})

      get "/courses/#{@copy_to.id}/discussion_topics/#{@topic_copy.id}"

      expect(f('#content')).to_not contain_css('.edit-btn')
      f('.al-trigger').click
      expect(f('.al-options')).to_not contain_css('.delete_discussion')
    end

    it "should show the edit/delete cog-menu options on the show when not locked" do
      get "/courses/#{@copy_to.id}/discussion_topics/#{@topic_copy.id}"

      expect(f('#content')).to contain_css('.edit-btn')
      f('.al-trigger').click
      expect(f('.al-options')).to contain_css('.delete_discussion')
    end
  end
end
