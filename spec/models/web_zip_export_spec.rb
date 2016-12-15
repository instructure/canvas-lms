require 'spec_helper'

describe WebZipExport do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
  end

  describe "#generate" do
    let_once(:web_zip_export) do
      @course.web_zip_exports.create({
        user: @student
      }).tap do |web_zip_export|
        web_zip_export.update_attribute(:workflow_state, 'exported')
      end
    end

    it "should update job_progress completion" do
      web_zip_export.generate_without_send_later
      expect(web_zip_export.job_progress.completion).to eq WebZipExport::PERCENTAGE_COMPLETE[:generating]
    end

    it "should set state to generating" do
      web_zip_export.generate_without_send_later
      expect(web_zip_export.generating?).to be_truthy
    end

    it 'should create and associate an attachment' do
      web_zip_export.export_without_send_later
      web_zip_export.content_export.export_without_send_later
      expect(web_zip_export.zip_attachment).to be_nil, 'precondition'
      expect{web_zip_export.convert_to_offline_web_zip_without_send_later}.to change{Attachment.count}.by(1)
      web_zip_export.reload
      expect(web_zip_export.zip_attachment).not_to be_nil
    end
  end
end
