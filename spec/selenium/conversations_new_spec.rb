require File.expand_path(File.dirname(__FILE__) + '/helpers/conversations_common')

describe "conversations new" do
  it_should_behave_like "in-process server selenium tests"

  def conversations_url
    "/conversations"
  end

  def get_conversations
    get conversations_url
    wait_for_ajaximations
  end

  def conversation_elements
    ffj('.messages > li')
  end

  def get_view_filter
    fj('.type-filter.bootstrap-select')
  end

  def get_course_filter
    pending('course filter selector fails intermittently')
    fj('.course-filter.bootstrap-select')
  end

  def get_bootstrap_select_value(element)
    fj('.selected .text', element).attribute('data-value')
  end

  def set_bootstrap_select_value(element, new_value)
    fj('.dropdown-toggle', element).click()
    fj('.text[data-value="'+new_value+'"]', element).click()
  end

  def select_view(new_view)
    set_bootstrap_select_value(get_view_filter, new_view)
    wait_for_ajaximations
  end

  def select_course(new_course)
    set_bootstrap_select_value(get_course_filter, new_course)
    wait_for_ajaximations
  end

  def click_star_toggle_menu_item()
    f('#admin-btn').click
    f("#star-toggle-btn").click
    wait_for_ajaximations
  end

  before do
    conversation_setup
    @teacher.preferences[:use_new_conversations] = true
    @teacher.save!

    @s1 = user(name: "first student")
    @s2 = user(name: "second student")
    [@s1, @s2].each { |s| @course.enroll_student(s).update_attribute(:workflow_state, 'active') }
  end

  describe "view filter" do
    before do
      conversation(@teacher, @s1, @s2, workflow_state: 'unread')
      conversation(@teacher, @s1, @s2, workflow_state: 'read', starred: true)
      conversation(@teacher, @s1, @s2, workflow_state: 'archived', starred: true)
    end

    it "should default to inbox view" do
      get_conversations
      selected = get_bootstrap_select_value(get_view_filter).should eql 'inbox'
      conversation_elements.size.should eql 2
    end

    it "should have an unread view" do
      get_conversations
      select_view('unread')
      conversation_elements.size.should eql 1
    end

    it "should have an starred view" do
      get_conversations
      select_view('starred')
      conversation_elements.size.should eql 2
    end

    it "should have an sent view" do
      get_conversations
      select_view('sent')
      conversation_elements.size.should eql 3
    end

    it "should have an archived view" do
      get_conversations
      select_view('archived')
      conversation_elements.size.should eql 1
    end

    it "should default to all courses view" do
      get_conversations
      selected = get_bootstrap_select_value(get_course_filter).should eql ''
      conversation_elements.size.should eql 2
    end

    it "should filter by course" do
      get_conversations
      select_course(@course.id.to_s)
      conversation_elements.size.should eql 2 
    end

    it "should filter by course plus view" do
      get_conversations
      select_course(@course.id.to_s)
      select_view('unread')
      conversation_elements.size.should eql 1 
    end
  end

  describe "starred" do
    before do
      @conv_unstarred = conversation(@teacher, @s1, @s2)
      @conv_starred = conversation(@teacher, @s1, @s2)
      @conv_starred.starred = true
      @conv_starred.save!
    end

    it "should star via star icon" do
      get_conversations
      unstarred_elt = conversation_elements[1]
      star_btn = f('.star-btn', unstarred_elt)
      star_btn.should be_present
      f('.active', unstarred_elt).should be_nil

      star_btn.click
      wait_for_ajaximations
      f('.active', unstarred_elt).should be_present
      @conv_unstarred.reload.starred.should be_true
    end

    it "should unstar via star icon" do
      get_conversations
      starred_elt = conversation_elements[0]
      star_btn = f('.star-btn', starred_elt)
      star_btn.should be_present
      f('.active', starred_elt).should be_present

      star_btn.click
      wait_for_ajaximations
      f('.active', starred_elt).should be_nil
      @conv_starred.reload.starred.should be_false
    end

    it "should star via gear menu" do
      get_conversations
      unstarred_elt = conversation_elements[1]
      unstarred_elt.click
      wait_for_ajaximations
      click_star_toggle_menu_item
      f('.active', unstarred_elt).should be_present
      @conv_unstarred.reload.starred.should be_true
    end

    it "should unstar via gear menu" do
      get_conversations
      starred_elt = conversation_elements[0]
      starred_elt.click
      wait_for_ajaximations
      click_star_toggle_menu_item
      f('.active', starred_elt).should be_nil
      @conv_starred.reload.starred.should be_false
    end
  end

end
