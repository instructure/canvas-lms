require "spec_helper"
require "#{Rails.root}/lib/data_fixup/create_canvadocs_submissions_records.rb"

describe DataFixup::CreateCanvadocsSubmissionsRecords do
  before :once do
    student_in_course active_all: true
    @assignment = @course.assignments.create! title: "ASSIGNMENT"
    @attachment = crocodocable_attachment_model user: @student, context: @student
    @submission = @assignment.submit_homework @student,
      submission_type: "online_upload",
      attachments: [@attachment]
  end

  def test_associations(type)
    run_jobs
    DataFixup::CreateCanvadocsSubmissionsRecords.run
    expect(@submission.send(type.pluralize)).to eq [@submission.attachments.first.send(type)]
    expect(@submission.send(type.pluralize).first.submissions).to eq [@submission]
  end

  it "creates records for canvadocs" do
    PluginSetting.create! :name => 'canvadocs',
                          :settings => {"api_key" => "blahblahblahblahblah",
                                        "base_url" => "http://example.com",
                                        "annotations_supported" => true}
    test_associations('canvadoc')
  end

  it "creates records for crocodoc_documents" do
    PluginSetting.create! :name => 'crocodoc',
                          :settings => { :api_key => "blahblahblahblahblah" }
    test_associations('crocodoc_document')
  end
end
