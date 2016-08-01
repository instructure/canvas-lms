require "spec_helper"

describe DataFixup::CreateCanvadocsSubmissionsRecords do
  before :once do
    student_in_course active_all: true
    @assignment = @course.assignments.create! title: "ASSIGNMENT"
    @attachment = crocodocable_attachment_model user: @student, context: @student
  end

  def make_submission
    @submission = @assignment.submit_homework @student,
      submission_type: "online_upload",
      attachments: [@attachment]
  end

  def test_associations(type)
    run_jobs

    #clear out the records created by callbacks
    CanvadocsSubmission.delete_all

    DataFixup::CreateCanvadocsSubmissionsRecords.run
    expect(@attachment.send(type).submissions).to eq [@submission]
  end

  it "creates records for canvadocs" do
    PluginSetting.create! :name => 'canvadocs',
                          :settings => {"api_key" => "blahblahblahblahblah",
                                        "base_url" => "http://example.com",
                                        "annotations_supported" => true}
    make_submission
    test_associations('canvadoc')
  end

  it "creates records for crocodoc_documents" do
    PluginSetting.create! :name => 'crocodoc',
                          :settings => { :api_key => "blahblahblahblahblah" }
    make_submission
    test_associations('crocodoc_document')
  end
end
