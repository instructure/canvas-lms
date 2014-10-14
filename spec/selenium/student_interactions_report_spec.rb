require File.expand_path(File.dirname(__FILE__) + '/common')

describe "student interactions report" do
  include_examples "in-process server selenium tests"

  context "as a student" do

  before (:each) do
    course_with_teacher_logged_in(:active_all => true)
    @student1 = student_in_course(:active_all => true).user
    @student2 = student_in_course(:active_all => true, :name => "zzz student").user

    @assignment = @course.assignments.create(:name => "first assignment", :points_possible => 10)
    @sub1 = @assignment.submissions.create(:user => @student1)
    @sub2 = @assignment.submissions.create(:user => @student2)

    @sub1.update_attribute(:score, 10)
    @sub2.update_attribute(:score, 5)

    get "/users/#{@teacher.id}/teacher_activity/course/#{@course.id}"
  end

  it "should have sortable columns, except the email header" do
    ths = ff(".report th")
    expect(ths[0]).to have_class("header")
    expect(ths[1]).to have_class("header")
    expect(ths[2]).to have_class("header")
    expect(ths[3]).to have_class("header")
    expect(ths[4]).to have_class("header")
    expect(ths[5]).not_to have_class("header")
  end

  it "should allow sorting by columns" do
    ths = ff(".report th")
    trs = ff(".report tbody tr")
    ths[0].click
    wait_for_ajaximations
    expect(ths[0]).to have_class("headerSortDown")
    expect(ff(".report tbody tr")).to eq [trs[0], trs[1]]

    ths[0].click
    wait_for_ajaximations
    expect(ths[0]).to have_class("headerSortUp")
    expect(ff(".report tbody tr")).to eq [trs[1], trs[0]]

    ths[2].click
    wait_for_ajaximations
    expect(ths[2]).to have_class("headerSortDown")
    expect(ff(".report tbody tr")).to eq [trs[0], trs[1]]

    ths[2].click
    wait_for_ajaximations
    expect(ths[2]).to have_class("headerSortUp")
    expect(ff(".report tbody tr")).to eq [trs[1], trs[0]]

    ths[3].click
    wait_for_ajaximations
    expect(ths[3]).to have_class("headerSortDown")
    expect(ff(".report tbody tr")).to eq [trs[0], trs[1]]

    ths[3].click
    wait_for_ajaximations
    expect(ths[3]).to have_class("headerSortUp")
    expect(ff(".report tbody tr")).to eq [trs[1], trs[0]]

    ths[5].click
    wait_for_ajaximations
    expect(ths[5]).not_to have_class("header")
  end
end
end