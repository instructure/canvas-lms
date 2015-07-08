require File.expand_path(File.dirname(__FILE__) + '/../helpers/conversations_common')

describe "conversations new" do
  include_examples "in-process server selenium tests"

  before do
    conversation_setup
    @s1 = user(name: "first student")
    @s2 = user(name: "second student")
    [@s1, @s2].each { |s| @course.enroll_student(s).update_attribute(:workflow_state, 'active') }
    cat = @course.group_categories.create(:name => "the groups")
    @group = cat.groups.create(:name => "the group", :context => @course)
    @group.users = [@s1, @s2]
  end

  describe "view filter" do
    before do
      conversation(@teacher, @s1, @s2, workflow_state: 'unread')
      conversation(@teacher, @s1, @s2, workflow_state: 'read', starred: true)
      conversation(@teacher, @s1, @s2, workflow_state: 'archived', starred: true)
    end

    it "should default to inbox view" do
      get_conversations
      selected = expect(get_bootstrap_select_value(get_view_filter)).to eq 'inbox'
      expect(conversation_elements.size).to eq 2
    end

    it "should have an unread view" do
      get_conversations
      select_view('unread')
      expect(conversation_elements.size).to eq 1
    end

    it "should have an starred view" do
      get_conversations
      select_view('starred')
      expect(conversation_elements.size).to eq 2
    end

    it "should have an sent view" do
      get_conversations
      select_view('sent')
      expect(conversation_elements.size).to eq 3
    end

    it "should have an archived view" do
      get_conversations
      select_view('archived')
      expect(conversation_elements.size).to eq 1
    end

    it "should default to all courses view" do
      get_conversations
      selected = expect(get_bootstrap_select_value(get_course_filter)).to eq ''
      expect(conversation_elements.size).to eq 2
    end

    it "should truncate long course names" do
      @course.name = "this is a very long course name that will be truncated"
      @course.save!
      get_conversations
      select_course(@course.id)
      button_text = f('.filter-option', get_course_filter).text
      expect(button_text).not_to eq @course.name
      expect(button_text[0...5]).to eq @course.name[0...5]
      expect(button_text[-5..-1]).to eq @course.name[-5..-1]
    end

    it "should filter by course" do
      get_conversations
      select_course(@course.id)
      expect(conversation_elements.size).to eq 2
    end

    it "should filter by course plus view" do
      get_conversations
      select_course(@course.id)
      select_view('unread')
      expect(conversation_elements.size).to eq 1
    end

    it "should hide the spinner after deleting the last conversation" do
      get_conversations
      select_view('archived')
      expect(conversation_elements.size).to eq 1
      conversation_elements[0].click
      wait_for_ajaximations
      fj('#delete-btn').click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(conversation_elements.size).to eq 0
      expect(ffj('.message-list .paginatedLoadingIndicator:visible').length).to eq 0
      expect(ffj('.actions .btn-group button:disabled').size).to eq 4
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
      # make star button visible via mouse over
      driver.mouse.move_to(unstarred_elt)
      wait_for_ajaximations
      star_btn = f('.star-btn', unstarred_elt)
      expect(star_btn).to be_present
      expect(f('.active', unstarred_elt)).to be_nil

      star_btn.click
      wait_for_ajaximations
      expect(f('.active', unstarred_elt)).to be_present
      expect(@conv_unstarred.reload.starred).to be_truthy
    end

    it "should unstar via star icon" do
      get_conversations
      starred_elt = conversation_elements[0]
      star_btn = f('.star-btn', starred_elt)
      expect(star_btn).to be_present
      expect(f('.active', starred_elt)).to be_present

      star_btn.click
      wait_for_ajaximations
      expect(f('.active', starred_elt)).to be_nil
      expect(@conv_starred.reload.starred).to be_falsey
    end

    it "should star via gear menu" do
      get_conversations
      unstarred_elt = conversation_elements[1]
      unstarred_elt.click
      wait_for_ajaximations
      click_star_toggle_menu_item
      expect(f('.active', unstarred_elt)).to be_present
      run_progress_job
      expect(@conv_unstarred.reload.starred).to be_truthy
    end

    it "should unstar via gear menu" do
      get_conversations
      starred_elt = conversation_elements[0]
      starred_elt.click
      wait_for_ajaximations
      click_star_toggle_menu_item
      expect(f('.active', starred_elt)).to be_nil
      run_progress_job
      expect(@conv_starred.reload.starred).to be_falsey
    end
  end
end
