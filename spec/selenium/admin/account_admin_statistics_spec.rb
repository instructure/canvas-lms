require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/basic/statistics_common')

describe "account admin statistics" do
  describe "shared statistics specs" do
    it_should_behave_like "in-process server selenium tests"

    let(:url) { "/accounts/#{Account.default.id}/statistics" }
    let(:account) { Account.default }
    let(:list_css) { {:created => '#recently_created_item_list', :started => '#recently_started_item_list', :ended => '#recently_ended_item_list', :logged_in => '#recently_logged_in_item_list'} }

    context "with admin initially logged in" do

      before (:each) do
        @course = Course.create!(:name => 'stats', :account => account)
        @course.offer!
        admin_logged_in
      end

      it "should validate recently created courses display" do
        should_validate_recently_created_courses_display
      end

      it "should validate recently started courses display" do
        should_validate_recently_started_courses_display
      end

      it "should validate no info in list display" do
        should_validate_no_info_in_list_display
      end

      it "should validate link works in list" do
        should_validate_link_works_in_list
      end

      it "should validate recently ended courses display" do
        should_validate_recently_ended_courses_display
      end
    end

    it "should validate recently logged-in courses display" do
      should_validate_recently_logged_in_courses_display
    end
  end
end