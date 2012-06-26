require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "account admin grading schemes" do
  it_should_behave_like "in-process server selenium tests"

  def save_and_reload_changes(grading_standard)
    f('.save_button').click
    wait_for_ajax_requests
    grading_standard.reload
  end

  before (:each) do
    course_with_admin_logged_in
  end

  describe "grading schemes" do

    it "should add a grading scheme" do
      new_standard_name = 'new grading standard'
      get "/accounts/#{Account.default.id}/grading_standards"
      f('.add_standard_link').click
      f('#grading_standard_new .scheme_name').send_keys(new_standard_name)
      f('.save_button').click
      wait_for_ajax_requests
      new_grading_standard = GradingStandard.last
      new_grading_standard.title.should == new_standard_name
      f("#grading_standard_#{new_grading_standard.id}").should be_displayed
    end

    it "should edit a grading scheme" do
      edit_name = 'edited grading scheme'
      grading_standard_for(Account.default)
      get "/accounts/#{Account.default.id}/grading_standards"
      grading_standard = GradingStandard.last

      f('.edit_grading_standard_link').click
      f("#grading_standard_#{grading_standard.id} .scheme_name").send_keys(edit_name)
      save_and_reload_changes(grading_standard)
      grading_standard.title.should == edit_name
      fj("#grading_standard_#{grading_standard.id} .title").text.should == edit_name #fj to avoid selenium caching
    end

    it "should delete a grading scheme" do
      grading_standard_for(Account.default)
      get "/accounts/#{Account.default.id}/grading_standards"

      f('.delete_grading_standard_link').click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      GradingStandard.last.workflow_state.should == 'deleted'
    end
  end

  describe "grading scheme items" do

    def grading_standard_rows
      ff('.grading_standard_row')
    end

    before (:each) do
      account = Account.default
      grading_standard_for(account)
      @grading_standard = GradingStandard.last
      get "/accounts/#{account.id}/grading_standards"
      f('.edit_grading_standard_link').click
    end

    it "should add a grading scheme item" do
      data_count = @grading_standard.data.count
      driver.action.move_to(grading_standard_rows[0]).perform
      f('.insert_grading_standard_link').click
      replace_content(ff('.editing_box .standard_name')[0], 'F')
      save_and_reload_changes(@grading_standard)
      @grading_standard.data.count.should == data_count + 1
      @grading_standard.data[0][0].should == 'F'
    end

    it "should edit a grading scheme item" do
      replace_content(grading_standard_rows[0].find_element(:css, '.standard_name'), 'F')
      save_and_reload_changes(@grading_standard)
      @grading_standard.data[0][0].should == 'F'
    end

    it "should delete a grading scheme item" do
      data_count = @grading_standard.data.count
      grading_standard_rows[0].find_element(:css, '.delete_row_link').click
      wait_for_ajaximations
      save_and_reload_changes(@grading_standard)
      @grading_standard.data.count.should == data_count - 1
      @grading_standard.data[0][0].should == 'B'
    end
  end
end