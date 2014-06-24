require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/rubrics_common')
require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "account shared rubric specs" do
  include_examples "in-process server selenium tests"

  let(:rubric_url) { "/accounts/#{Account.default.id}/rubrics" }
  let(:who_to_login) { 'admin' }
  let(:account) { Account.default }

  before (:each) do
    resize_screen_to_normal
    course_with_admin_logged_in
  end

  it "should delete a rubric" do
    should_delete_a_rubric
  end
  it "should edit a rubric" do
    should_edit_a_rubric
  end

  it "should allow fractional points" do
    should_allow_fractional_points
  end


  it "should round to 2 decimal places" do
    should_round_to_2_decimal_places
  end

  it "should round to an integer when splitting" do
    resize_screen_to_default
    should_round_to_an_integer_when_splitting
  end

  it "should pick the lower value when splitting without room for an integer" do
    should_pick_the_lower_value_when_splitting_without_room_for_an_integer
  end
end
