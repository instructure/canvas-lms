
require_relative '../rails_helper'

RSpec.describe 'Excused assignments on Course home page', type: :feature, js: true do

  include_context 'stubbed_network'

  before(:each) do
    course_with_student_logged_in(:active_all => true)

  # Module 1 -------
    @module1 = @course.context_modules.create!(:name => "Module 1")

  # Assignment 1
    @assignment1 = @course.assignments.create!(:name => "Assignment 1: pls submit", :submission_types => ["online_text_entry"], :points_possible => 25)
    @assignment1.publish
    @assignment1_tag = @module1.add_item(:id => @assignment1.id, :type => 'assignment', :title => 'Assignment: requires submission')

  # Assignment 2
    @assignment2 = @course.assignments.create!(:name => "Assignment 3: min score", :submission_types => ["online_text_entry"], :points_possible => 50)
    @assignment2.publish
    @assignment2_tag = @module1.add_item(:id => @assignment2.id, :type => 'assignment', :title => 'Assignment 2: min score')

    @module1.completion_requirements = {
      @assignment1_tag.id => { type: 'must_submit' },
      @assignment2_tag.id => { type: 'min_score', min_score: 70 },
    }

    @module1.save!

    # Excuse submissions, don't care about forcing requirements passing for this spec
    expect(Submission.count).not_to eq(0)
    Submission.all.each do |sub|
      sub.update_column :excused, true
    end
  end

  it "Assignment should show excused in title and in below requirements" do
    visit "/courses/#{@course.id}"

    expect(page).to have_selector('a.home.active')

    find(".sm-ig-header-title").click

    expect(page).to have_selector("#context_module_item_#{@assignment1_tag.id}", visible: true)

    [@assignment1_tag, @assignment2_tag].each do |tag|
      expect(page).to have_selector(
        "#context_module_item_#{tag.id} .excused-assignment-state.excused-assignment",
        visible: true
      )
    end
  end
end
