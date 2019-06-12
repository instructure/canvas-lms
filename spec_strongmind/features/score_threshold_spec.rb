
require_relative '../rails_helper'

RSpec.describe 'Score threshold feature', type: :feature, js: true do
  include_context 'stubbed_network'

  context "with score_threshold set" do
    before do
      allow_any_instance_of(ContextModule).to receive(:score_threshold).and_return(75.0)
      account_admin_user
      user_session(@admin)
      course_with_teacher_logged_in(user: @admin)
      
      @module = @course.context_modules.create!(:name => "some module")
      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item({:id => @assignment.id, :type => 'assignment'})
      @module.completion_requirements = {@tag.id => {:type => 'must_submit'}}
      @module.publish
      @module.save!
      visit "/courses/#{@course.id}"
      find("#distraction-free-toggle-icon-state").click
    end

    it "initializes modules with the threshold" do
      find(".expand_module_link").click
      expect(page).to have_content('Score at least 75.0')
    end
  end
end
