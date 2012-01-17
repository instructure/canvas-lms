require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ContentZipper do
  # Note that EportfoliosController#export,
  # SubmissionsController#submission_zip, and FoldersController#download are
  # all ALMOST exactly the same code, copied and pasted with slight changes.
  #
  # This really needs to get refactored at some point.
  def grab_zip
    expect { yield }.to change(Delayed::Job, :count).by(1)
    response.should be_success
    attachment_id = json_parse['attachment']['id']
    attachment_id.should be_present

    a = Attachment.find attachment_id
    a.should be_to_be_zipped

    # a second query should just return status
    expect { yield }.to change(Delayed::Job, :count).by(0)
    response.should be_success
    json_parse['attachment']['id'].should == a.id
  end

  context "submission zips" do
    it "should schedule a job on the first request, and then respond with progress updates" do
      course_with_teacher_logged_in(:active_all => true)
      submission_model(:course => @course)
      grab_zip { get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions.json?zip=1&compile=1" }
    end
  end

  context "eportfolio zips" do
    it "should schedule a job on the first request, and then respond with progress updates" do
      eportfolio_model
      user_session(@user)
      grab_zip { get "/eportfolios/#{@eportfolio.id}/export.json?compile=1" }
    end
  end
end
