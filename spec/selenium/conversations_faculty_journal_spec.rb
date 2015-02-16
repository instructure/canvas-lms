require File.expand_path(File.dirname(__FILE__) + '/helpers/conversations_common')

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

  context "faculty journal" do
    before(:each) do
      @course.account.update_attribute(:enable_user_notes, true)
      user_session(@teacher)
      get_conversations
    end

    it "should be allowed on new private conversations with students" do
      compose course: @course, to: [@s1, @s2], body: 'hallo!', send: false

      checkbox = f(".user_note")
      expect(checkbox).to be_displayed
      checkbox.click

      count1 = @s1.user_notes.count
      count2 = @s2.user_notes.count
      click_send
      expect(@s1.user_notes.reload.count).to eq count1 + 1
      expect(@s2.user_notes.reload.count).to eq count2 + 1
    end

    it "should be allowed with student groups" do
      compose course: @course, to: [@group], body: 'hallo!', send: false

      checkbox = f(".user_note")
      expect(checkbox).to be_displayed
      checkbox.click

      count1 = @s1.user_notes.count
      click_send
      expect(@s1.user_notes.reload.count).to eq count1 + 1
    end

    it "should not be allowed if disabled" do
      @course.account.update_attribute(:enable_user_notes, false)
      get_conversations
      compose course: @course, to: [@s1], body: 'hallo!', send: false
      expect(f(".user_note")).not_to be_displayed
    end

    it "should not be allowed for students" do
      user_session(@s1)
      get_conversations
      compose course: @course, to: [@s2], body: 'hallo!', send: false
      expect(f(".user_note")).not_to be_displayed
    end

    it "should not be allowed with non-student recipient" do
      compose course: @course, to: [@teacher], body: 'hallo!', send: false
      expect(f(".user_note")).not_to be_displayed
    end
  end
end


