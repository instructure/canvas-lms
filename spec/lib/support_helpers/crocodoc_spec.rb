require_relative '../../spec_helper'

describe SupportHelpers::Crocodoc::CrocodocFixer do
  let(:student) { user_factory(active_all: true) }
  let(:test_course) { Account.default.courses.create!(name: 'croco') }
  let(:assignment) do
    test_course.assignments.create!(title: 'doc',
                                    submission_types: 'online_text_entry,online_upload')
  end
  let(:assignment2) do
    test_course.assignments.create!(title: 'doc',
                                    submission_types: 'online_text_entry,online_upload')
  end
  let!(:submission) do
    assignment.submit_homework(student, submission_type: 'online_upload',
                               attachments: [shardattachment])
  end

  let!(:submission2) do
    assignment.submit_homework(student, submission_type: 'online_upload',
                               attachments: [shardattachment2])
  end

  let!(:submission3) do
    assignment2.submit_homework(student, submission_type: 'online_upload',
                               attachments: [shardattachment3])
  end

  let(:shardattachment) do
    Attachment.create!(filename: 'terrible.txt', uploaded_data: StringIO.new('yo, what up?'),
                       user: student, content_type: 'application/msword', context: student)
  end
  let(:shardattachment2) do
    Attachment.create!(filename: 'terrible.txt', uploaded_data: StringIO.new('yo, what up?'),
                       user: student, content_type: 'application/msword', context: student)
  end

  let(:shardattachment3) do
    Attachment.create!(filename: 'terrible.txt', uploaded_data: StringIO.new('yo, what up?'),
                       user: student, content_type: 'application/msword', context: student)
  end

  let!(:crocodocument) do
    cd = shardattachment.create_crocodoc_document
    cd.update_attributes(uuid: 'some stuff', process_state: 'ERROR')
    cd
  end
  let!(:crocodocument2) do
    cd = shardattachment2.create_crocodoc_document
    cd.update_attributes(uuid: 'some stuff', process_state: 'ERROR')
    cd
  end
  let!(:crocodocument3) do
    cd = shardattachment3.create_crocodoc_document
    cd.update_attributes(uuid: 'some stuff', process_state: 'PROCESSING')
    cd
  end

  describe "#resubmit_attachment" do
    it 'resubmits the attachment to crocodoc' do
      fixer = SupportHelpers::Crocodoc::CrocodocFixer.new('email')
      crocodocument.expects(:update_attribute).returns(true)
      shardattachment.expects(:submit_to_crocodoc).returns(true)

      fixer.resubmit_attachment(shardattachment)
      expect(fixer.attempted_resubmit).to eql(1)
    end
  end

  describe "ShardFixer" do
    it 'resubmits crocodocs in an error state' do
      fixer = SupportHelpers::Crocodoc::ShardFixer.new('email')
      fixer.expects(:resubmit_attachment).twice.returns(nil)

      fixer.fix
    end
  end

  describe "SubmissionFixer" do
    it 'resubmits crodocodcs for a given assignment and user' do
      fixer =
        SupportHelpers::Crocodoc::SubmissionFixer.new('email', nil, assignment.id, student.id)

      fixer.expects(:resubmit_attachment).once.returns(nil)
      fixer.fix
    end

    it 'does not resubmit processing crodocodcs' do
      fixer =
        SupportHelpers::Crocodoc::SubmissionFixer.new('email', nil, assignment2.id, student.id)

      fixer.expects(:resubmit_attachment).never
      fixer.fix
    end

    it 'resubmits processing crodocodcs if stuck for more than a day' do
      crocodocument3.update_attributes(updated_at: 4.days.ago)

      fixer =
        SupportHelpers::Crocodoc::SubmissionFixer.new('email', nil, assignment2.id, student.id)

      fixer.expects(:resubmit_attachment).once.returns(nil)
      fixer.fix
    end
  end
end
