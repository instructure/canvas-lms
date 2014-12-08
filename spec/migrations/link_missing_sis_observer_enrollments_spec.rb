require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe 'DataFixup::LinkMissingSisObserverEnrollments' do
  it "should create missing observer enrollments" do

    batch = Account.default.sis_batches.create!
    course_with_student(:active_all => true)

    observer = user_with_pseudonym
    @student.observers << observer

    @student.student_enrollments.first.update_attribute(:sis_batch_id, batch.id)

    observer.reload
    expect(observer.observer_enrollments.count).to eq 1
    observer.enrollments.delete_all

    DataFixup::LinkMissingSisObserverEnrollments.run

    observer.reload
    expect(observer.observer_enrollments.count).to eq 1
  end
end
