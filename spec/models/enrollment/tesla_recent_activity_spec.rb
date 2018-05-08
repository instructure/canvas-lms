require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')


describe Enrollment::RecentActivity do
  before do
    @user = User.create!
    @course = Course.create!
    @enrollment = StudentEnrollment.create!(
      valid_enrollment_attributes
    )
  end
  subject { described_class.new(@enrollment) }

  it 'works' do
    subject.record!
  end
end
