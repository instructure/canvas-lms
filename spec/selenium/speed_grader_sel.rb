require File.expand_path(File.dirname(__FILE__) + '/common')

describe "speedgrader selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  it "should show video and audio recorder for media comments" do
    # trick kaltura into being activated
    Kaltura::ClientV3.stub!(:config).and_return({
          :domain => 'kaltura.example.com',
          :resource_domain => 'kaltura.example.com',
          :partner_id => '100',
          :subpartner_id => '10000',
          :secret_key => 'fenwl1n23k4123lk4hl321jh4kl321j4kl32j14kl321',
          :user_secret_key => '1234821hrj3k21hjk4j3kl21j4kl321j4kl3j21kl4j3k2l1',
          :player_ui_conf => '1',
          :kcw_ui_conf => '1',
          :upload_ui_conf => '1'
    })
    
    course_with_teacher_logged_in
    teacher = @user
    
    assignment = @course.assignments.create(:name => 'assignment with rubric')
    student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwerty')
    @course.enroll_user(student, "StudentEnrollment", :enrollment_state => 'active')
    
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}"
    
    driver.find_element(:css, ".media_comment_link").click
    keep_trying_until { driver.find_element(:id, "audio_record_option") }
    driver.find_element(:id, "audio_record_option").displayed?.should be_true
    driver.find_element(:id, "video_record_option").displayed?.should be_true
  end
end
