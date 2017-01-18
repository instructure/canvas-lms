require_relative '../spec_helper'

describe DataFixup::PopulateStreamItemNotificationCategory do
  it "should populate notification_category" do
    course_with_student(:active_all => true)
    category = "TestImmediately"
    Notification.create(:name => 'Assignment Due Date Changed', :category => category)
    Assignment.any_instance.stubs(:created_at).returns(4.hours.ago)
    assignment_model(:course => @course)
    @assignment.update_attribute(:due_at, 1.week.from_now)

    item = StreamItem.where(:asset_type => "Message").last
    # should have auto-populated with new code now
    expect(item.notification_category).to eq category

    StreamItem.where(:id => item).update_all(:notification_category => nil)
    DataFixup::PopulateStreamItemNotificationCategory.run

    item.reload
    expect(item.notification_category).to eq category
  end
end
