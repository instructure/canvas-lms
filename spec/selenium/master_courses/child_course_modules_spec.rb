require_relative '../helpers/context_modules_common'

describe "master courses - child courses - module item locking" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon

  before :once do
    Account.default.enable_feature!(:master_courses)

    @copy_from = course_factory(:active_all => true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
    @original_page = @copy_from.wiki.wiki_pages.create!(:title => "blah", :body => "bloo")
    @page_mc_tag = @template.create_content_tag_for!(@original_page, :restrictions => {:content => true, :settings => true})

    @original_topic = @copy_from.discussion_topics.create!(:title => "blah", :message => "bloo")
    @topic_mc_tag = @template.create_content_tag_for!(@original_topic)

    course_with_teacher(:active_all => true)
    @copy_to = @course
    @sub = @template.add_child_course!(@copy_to)

    @page_copy = @copy_to.wiki.wiki_pages.create!(:title => "locked page", :migration_id => @page_mc_tag.migration_id)
    @topic_copy = @copy_to.discussion_topics.create!(:title => "unlocked topic", :migration_id => @topic_mc_tag.migration_id)
    [@page_copy, @topic_copy].each{|obj| @sub.create_content_tag_for!(obj)}
    @assmt = @copy_to.assignments.create!(:title => "normal assignment")

    @mod = @copy_to.context_modules.create!(:name => "modle")
    @locked_tag = @mod.add_item(:id => @page_copy.id, :type => "wiki_page")
    @unlocked_tag = @mod.add_item(:id => @topic_copy.id, :type => "discussion_topic")
    @normal_tag = @mod.add_item(:id => @assmt.id, :type => "assignment")
  end

  before :each do
    user_session(@teacher)
  end

  it "should show all the icons on the modules index" do
    get "/courses/#{@copy_to.id}/modules"

    expect(f("#context_module_item_#{@locked_tag.id} .master-course-cell")).to contain_css('.icon-lock')
    expect(f("#context_module_item_#{@unlocked_tag.id} .master-course-cell")).to contain_css('.icon-unlock')
    expect(f("#context_module_item_#{@normal_tag.id}")).to_not contain_css('.master-course-cell')
  end

  it "should disable the title edit input for locked items" do
    get "/courses/#{@copy_to.id}/modules"

    f("#context_module_item_#{@locked_tag.id} .al-trigger").click
    f("#context_module_item_#{@locked_tag.id} .al-options .edit_link").click
    expect(f("#content_tag_title")).to be_disabled
  end

  it "should not disable the title edit input for unlocked items" do
    get "/courses/#{@copy_to.id}/modules"

    f("#context_module_item_#{@unlocked_tag.id} .al-trigger").click
    f("#context_module_item_#{@unlocked_tag.id} .al-options .edit_link").click
    expect(f("#content_tag_title")).to_not be_disabled
  end

  it "loads new restriction info as needed when adding an item" do
    title = "new quiz"
    original_quiz = @copy_from.quizzes.create!(:title => title)
    quiz_mc_tag = @template.create_content_tag_for!(original_quiz, :restrictions => {:content => true, :settings => true})

    quiz_copy = @copy_to.quizzes.create!(:title => title, :migration_id => quiz_mc_tag.migration_id)
    @sub.create_content_tag_for!(quiz_copy)

    get "/courses/#{@copy_to.id}/modules"

    f("#context_module_#{@mod.id} .add_module_item_link").click
    wait_for_ajaximations
    click_option('#add_module_item_select', "Quiz")
    click_option('#quizs_select .module_item_select', title)
    fj('.add_item_button.ui-button').click

    wait_for_ajaximations
    new_tag = ContentTag.last
    expect(new_tag.content).to eq quiz_copy

    # does another fetch to get restrictions for the new tag
    expect(f("#context_module_item_#{new_tag.id} .master-course-cell")).to contain_css('.icon-lock')
  end
end
