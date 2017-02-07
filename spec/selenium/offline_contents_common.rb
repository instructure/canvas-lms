require_relative 'common'
require_relative 'helpers/shared_examples_common'

# ======================================================================================================================
# Shared Examples
# ======================================================================================================================

shared_examples 'show courses for ePub generation' do |context|
  include SharedExamplesCommon
  
  it "should show the courses the user is enrolled in and feature enabled in ePub exports page",
                            priority: "1", test_id: pick_test_id(context, teacher: "417579", student: "498316") do
    @course2 = course_model(name: 'Second Course')
    @course2.offer!
    enroll_context_user(context)
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

  def enroll_context_user(context)
    case context
    when :student
      @course2.enroll_student(@student1).accept!
    when :teacher
      @course2.enroll_teacher(@teacher1).accept!
    else
      raise('Error: Invalid context')
    end
  end
end

shared_examples 'generate and download ePub' do |context|
  include SharedExamplesCommon

  it "should show progress", priority: "1", test_id: pick_test_id(context, teacher: "417580", student: "498317") do
    get '/epub_exports'
    f('.ig-admin .Button').click
    expect(f('.progress-bar__bar')).to be_present
  end

  it "should generate ePub file", priority: "1", test_id: pick_test_id(context, teacher: "588916", student: "588917") do
    get '/epub_exports'
    f('.ig-admin .Button').click
    wait_for_ajaximations
    run_jobs
    expect(f('.ig-details')).to include_text('Generated')
    expect(f('.icon-download')).to be_present
    expect(f('.ig-admin .Button')).to include_text('Regenerate ePub')
  end
end

