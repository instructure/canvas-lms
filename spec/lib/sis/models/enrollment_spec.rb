require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe SIS::Models::Enrollment do

  describe '#valid_context?' do
    it 'detects an invalid context' do
      expect(subject).to_not be_valid_context
    end

    it 'has a valid context if there is a course_id' do
      subject.course_id = 10
      expect(subject).to be_valid_context
    end

    it 'has a valid context if there is a section_id' do
      subject.section_id = 9
      expect(subject).to be_valid_context
    end
  end


  describe '#valid_user?' do
    it 'detects an invalid user' do
      expect(subject).to_not be_valid_user
    end

    it 'has a valid context if there is a user_id' do
      subject.user_id = 10
      expect(subject).to be_valid_user
    end

    it 'has a valid context if there is a user_integration_id' do
      subject.user_integration_id = 9
      expect(subject).to be_valid_user
    end
  end

  describe '#valid_status?' do
    it 'detects an empty status' do
      expect(subject).to_not be_valid_status
    end

    it 'detects a bad status' do
      subject.status = 'fake'
      expect(subject).to_not be_valid_status
    end

    it 'accepts the active status' do
      subject.status = 'active'
      expect(subject).to be_valid_status
    end

    it 'accepts the deleted status' do
      subject.status = 'deleted'
      expect(subject).to be_valid_status
    end

    it 'accepts the completed status' do
      subject.status = 'completed'
      expect(subject).to be_valid_status
    end

    it 'accepts the inactive status' do
      subject.status = 'inactive'
      expect(subject).to be_valid_status
    end
  end

  it 'outputs properties in the correct order in an array' do
    subject.course_id = 'course_id'
    subject.section_id = 'section_id'
    subject.user_id = 'user_id'
    subject.role = 'role'
    subject.role_id = 'role_id'
    subject.status = 'status'
    subject.start_date = 'start_date'
    subject.end_date = 'end_date'
    subject.associated_user_id = 'associated_user_id'
    subject.root_account_id = 'root_account_id'
    expect(subject.to_a).to eq ['course_id', 'section_id', 'user_id', 'role',
                                'role_id', 'status', 'start_date', 'end_date',
                                'associated_user_id', 'root_account_id']
  end

end
