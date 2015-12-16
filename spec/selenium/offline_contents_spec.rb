require File.expand_path(File.dirname(__FILE__) + '/common')

describe "offline contents" do
  include_context "in-process server selenium tests"

  before :each do
    Account.default.enable_feature!(:epub_export)
    @teacher1 = course_with_teacher_logged_in.user
    @course1 = @course
    @course1.name = 'First Course'
    @course1.save!
    @course1.enable_feature!(:epub_export)
  end

  it "should show the courses the user is enrolled in and feature enabled in ePub exports page",
                                                                     priority: "1", test_id: 417579 do
    @course2 = course_model(name: 'Second Course')
    @course2.enroll_teacher(@teacher1).accept!
    @course2.enable_feature!(:epub_export)
    get '/epub_exports'
    first_row = f('.course-epub-exports-app li:nth-of-type(1) .ig-title')
    second_row = f('.course-epub-exports-app li:nth-of-type(2) .ig-title')
    if first_row.text == @course2.name
      expect(second_row.text).to include(@course1.name)
    elsif first_row.text == @course1.name
      expect(second_row.text).to include(@course2.name)
    end
    expect(f('.course-epub-exports-app li:nth-of-type(1) .ig-admin .Button').text).to include('Generate ePub')
    expect(f('.course-epub-exports-app li:nth-of-type(2) .ig-admin .Button').text).to include('Generate ePub')
  end

  it "should generate and download ePub file", priority: "1", test_id: 417580 do
    get '/epub_exports'
    expect(f('.ig-title').text).to include(@course1.name)
    f('.ig-admin .Button').click
    expect(f('.progress-bar__bar')).to be_present
    run_jobs
    keep_trying_until do
      expect(f('.ig-details').text).to include('Generated')
      expect(f('.icon-download')).to be_present
      expect(f('.ig-admin .Button').text).to include('Regenerate ePub')
    end
  end
end