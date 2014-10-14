require File.expand_path(File.dirname(__FILE__) + '/common')

describe "grade exchange course settings tab" do
  include_examples "in-process server selenium tests"

  def getpseudonym(user_sis_id)
    pseudo = Pseudonym.find_by_sis_user_id(user_sis_id)
    expect(pseudo).not_to be_nil
    pseudo
  end

  def getuser(user_sis_id)
    user = getpseudonym(user_sis_id).user
    expect(user).not_to be_nil
    user
  end

  def getsection(section_sis_id)
    section = CourseSection.find_by_sis_source_id(section_sis_id)
    expect(section).not_to be_nil
    section
  end

  def getenroll(user_sis_id, section_sis_id)
    e = Enrollment.find_by_user_id_and_course_section_id(getuser(user_sis_id).id, getsection(section_sis_id).id)
    expect(e).not_to be_nil
    e
  end

  def grade_passback_setup(wait_for_success)

    process_csv_data_cleanly(
      "user_id,login_id,password,first_name,last_name,email,status",
      "T1,Teacher1,,T,1,t1@example.com,active",
      "S1,Student1,,S,1,s1@example.com,active",
      "S2,Student2,,S,2,s2@example.com,active",
      "S3,Student3,,S,3,s3@example.com,active",
      "S4,Student4,,S,4,s4@example.com,active",
      "S5,Student5,,S,5,s5@example.com,active",
      "S6,Student6,,S,6,s6@example.com,active")
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C1,C1,C1,,,active")
    @course = Course.find_by_sis_source_id("C1")
    @course.assignment_groups.create(:name => "Assignments")
    @teacher = getuser("T1")
    process_csv_data_cleanly(
      "section_id,course_id,name,status,start_date,end_date",
      "S1,C1,S1,active,,",
      "S2,C1,S2,active,,",
      "S3,C1,S3,active,,",
      "S4,C1,S4,active,,")
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status",
      ",T1,teacher,S1,active",
      ",S1,student,S1,active",
      ",S2,student,S2,active",
      ",S3,student,S2,active",
      ",S4,student,S1,active",
      ",S5,student,S3,active",
      ",S6,student,S4,active")
    a1 = @course.assignments.create!(:title => "A1", :points_possible => 10)
    a2 = @course.assignments.create!(:title => "A2", :points_possible => 10)

    a1.grade_student(getuser("S1"), { :grade => "6", :grader => @teacher })
    a1.grade_student(getuser("S2"), { :grade => "6", :grader => @teacher })
    a1.grade_student(getuser("S3"), { :grade => "7", :grader => @teacher })
    a1.grade_student(getuser("S5"), { :grade => "7", :grader => @teacher })
    a1.grade_student(getuser("S6"), { :grade => "8", :grader => @teacher })
    a2.grade_student(getuser("S1"), { :grade => "8", :grader => @teacher })
    a2.grade_student(getuser("S2"), { :grade => "9", :grader => @teacher })
    a2.grade_student(getuser("S3"), { :grade => "9", :grader => @teacher })
    a2.grade_student(getuser("S5"), { :grade => "10", :grader => @teacher })
    a2.grade_student(getuser("S6"), { :grade => "10", :grader => @teacher })

    @stud5, @stud6, @sec4 = nil, nil, nil
    Pseudonym.find_by_sis_user_id("S5").tap do |p|
      @stud5 = p
      p.sis_user_id = nil
      p.save
    end

    Pseudonym.find_by_sis_user_id("S6").tap do |p|
      @stud6 = p
      p.sis_user_id = nil
      p.save
    end

    getsection("S4").tap do |s|
      @sec4 = s
      sec4id = s.sis_source_id
      s.sis_source_id = nil
      s.save
    end

    @course.grading_standard_enabled = true
    @course.save!
    GradeCalculator.recompute_final_score(["S1", "S2", "S3", "S4"].map{|x|getuser(x).id}, @course.id)
    @course.reload

    @plugin = Canvas::Plugin.find!('grade_export')
    @ps = PluginSetting.new(:name => @plugin.id, :settings => @plugin.default_settings)
    @ps.posted_settings = @plugin.default_settings.merge({
        :format_type => "instructure_csv",
        :wait_for_success => wait_for_success ? "yes" : "no",
        :publish_endpoint => "http://localhost/endpoint"
      })
    @ps.save!

    @course.offer!
    user_session(@teacher)

    @course.grading_standard_id = 0
    @course.save!

    get "/courses/#{@course.id}/settings"
    f("#tab-grade-publishing-link").click
    wait_for_ajaximations

    expect(f("#publish_grades_messages").text).to eq "Unpublished - 6"
    driver.execute_script "window.confirm = function(msg) { return true; }"

    csv =
        "publisher_id,publisher_sis_id,section_id,section_sis_id,student_id," +
        "student_sis_id,enrollment_id,enrollment_status,score,grade\n" +
        "#{@teacher.id},T1,#{getsection("S1").id},S1,#{getpseudonym("S1").user.id},S1,#{getenroll("S1", "S1").id},active,70,C-\n" +
        "#{@teacher.id},T1,#{getsection("S2").id},S2,#{getpseudonym("S2").user.id},S2,#{getenroll("S2", "S2").id},active,75,C\n" +
        "#{@teacher.id},T1,#{getsection("S2").id},S2,#{getpseudonym("S3").user.id},S3,#{getenroll("S3", "S2").id},active,80,B-\n" +
        "#{@teacher.id},T1,#{getsection("S1").id},S1,#{getpseudonym("S4").user.id},S4,#{getenroll("S4", "S1").id},active,0,F\n" +
        "#{@teacher.id},T1,#{getsection("S3").id},S3,#{@stud5.id},,#{Enrollment.find_by_user_id_and_course_section_id(@stud5.user.id, getsection("S3").id).id},active,85,B\n" +
        "#{@teacher.id},T1,#{@sec4.id},,#{@stud6.id},,#{Enrollment.find_by_user_id_and_course_section_id(@stud6.user.id, @sec4.id).id},active,90,A-\n"
    SSLCommon.expects(:post_data).with("http://localhost/endpoint", csv, "text/csv", {})
    f("#publish_grades_link").click
    wait_for_ajaximations
    expect(f("#publish_grades_messages").text).to eq(wait_for_success ? "Publishing - 6" : "Published - 6")
  end

  it "should support grade submission" do
    skip "spec being rewritten in a refactor"
    grade_passback_setup(false)
  end

  it "should support grade submission and result writeback" do
    skip "spec being rewritten in a refactor"
    grade_passback_setup(true)
    process_csv_data_cleanly(
      "enrollment_id,grade_publishing_status,message",
      "#{getenroll("S1", "S1").id},published,",
      "#{getenroll("S2", "S2").id},published,",
      "#{getenroll("S3", "S2").id},published,Grade modified",
      "#{getenroll("S4", "S1").id},error,Invalid user",
      "#{Enrollment.find_by_user_id_and_course_section_id(@stud5.user.id, getsection("S3").id).id},error,Invalid user",
      "#{Enrollment.find_by_user_id_and_course_section_id(@stud6.user.id, @sec4.id).id},error,")
    keep_trying_until { f("#publish_grades_messages").text.strip.split("\n").to_set == "Error: Invalid user - 2\nPublished - 2\nPublished: Grade modified - 1\nError - 1".split("\n").to_set }
  end
end
