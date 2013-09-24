require Pathname(File.dirname(__FILE__)) + "../../../sfu_api/app/model/sfu/sfu"

class CourseFormController < ApplicationController

  # Canvas course names have a limit of 255 characters max.
  CANVAS_COURSE_NAME_MAX = 255

  before_filter :require_user

  def new
    @user = User.find(@current_user.id)
    @sfuid = @user.pseudonym.unique_id
    @sfuid.slice! "@sfu.ca"
    @course_list = Array.new
    @current_term = current_term
    @terms = [@current_term] + future_terms
    # only show current term plus next 2 terms (up to 3 non-nil terms in total)
    @term_options = @terms.compact.take(3).map { |term| [term.name, term.sis_source_id] }
    roles = SFU::User.roles @sfuid
    @is_student = %w(undergrad grad).any? { |role| roles.include? role }
    # deny access to undergrad-only users
    if roles == %w(undergrad)
      flash[:error] = "You don't have permission to access that page"
      redirect_to dashboard_url
    end
  end

  def create
    req_user = User.find(@current_user.id).pseudonym.unique_id
    selected_courses = []
    account_id = Account.find_by_name("Simon Fraser University").id
    teacher_username = params[:username]
    teacher2_username = params[:enroll_me]
    teacher_sis_user_id = sis_user_id(teacher_username, account_id)
    teacher2_sis_user_id = sis_user_id(teacher2_username, account_id) unless teacher2_username.nil?
    teacher2_role = sanitize_role(params[:enroll_me_as])
    cross_list = params[:cross_list]
    course_name_too_long = false

    params.each do |key, value|
      if key.to_s.starts_with? "selected_course"
        selected_courses.push value
      end
    end

    course_array = ["course_id,short_name,long_name,account_id,term_id,status"]
    section_array = ["section_id,course_id,name,status,start_date,end_date"]
    enrollment_array = ["course_id,user_id,role,section_id,status"]

    unless cross_list

      selected_courses.compact.uniq.each do |course|
        if course.starts_with? "sandbox"
          logger.info "[SFU Course Form] Creating sandbox for #{teacher_username} requested by #{req_user}"
          sandbox = sandbox_info(course, teacher_username, teacher_sis_user_id, teacher2_sis_user_id, teacher2_role)

          course_array.push sandbox["csv"]
          enrollment_array.push sandbox["enrollment_csv_1"]
          enrollment_array.push sandbox["enrollment_csv_2"] unless teacher2_sis_user_id.nil?

          course_name_too_long = true if sandbox["short_long_name"].length > CANVAS_COURSE_NAME_MAX
        elsif course.starts_with? "ncc"
          logger.info "[SFU Course Form] Creating ncc course for #{teacher_username} requested by #{req_user}"
          ncc_course = ncc_info(course, teacher_sis_user_id, teacher2_sis_user_id, teacher2_role)

          course_array.push ncc_course["csv"]
          enrollment_array.push ncc_course["enrollment_csv_1"]
          enrollment_array.push ncc_course["enrollment_csv_2"] unless teacher2_sis_user_id.nil?

          course_name_too_long = true if ncc_course["short_long_name"].length > CANVAS_COURSE_NAME_MAX
        else
          logger.info "[SFU Course Form] Creating single course container : #{course} requested by #{req_user}"
          course_info = course_info(course, account_id, teacher_sis_user_id, teacher2_sis_user_id, teacher2_role)

          # create course csv
          course_array.push course_info["course_csv"]

          # create section csv
          section_array.push section_csv(course_info["term"], course_info["sections"], course_info["course_id"])

          enrollment_array.push course_info["enrollment_csv_1"]
          enrollment_array.push course_info["enrollment_csv_2"] unless teacher2_username.nil?

          course_name_too_long = true if course_info["long_name"].length > CANVAS_COURSE_NAME_MAX
        end
      end

    else

      logger.info "[SFU Course Form] Creating cross-list container : #{selected_courses.inspect} requested by #{req_user}"
      course_ids = []
      short_names = []
      long_names = []
      term = ""
      sections = []

      selected_courses.each do |course|
        course_info = course_info(course, account_id, teacher_sis_user_id, teacher2_sis_user_id, teacher2_role)

        course_ids.push course_info["course_id"]
        short_names.push course_info["short_name"]
        long_names.push course_info["long_name"]
        term = course_info["term"]

        sections.push course_info["sections"]
      end

      course_id = course_ids.join(':')
      short_name = short_names.join(' / ')
      long_name = long_names.join(' / ')

      # Use a shorter version (omit subsequent titles) of the long name if it's too long.
      # Original long name: IAT100 D100 Example Course / IAT100 D200 Example Course / IAT100 D300 Example Course
      # Shorter version:    IAT100 D100 Example Course / IAT100 D200 / IAT100 D300
      long_name = (long_names[0, 1] + short_names[1..-1]).join(' / ') if long_name.length > CANVAS_COURSE_NAME_MAX

      # create course csv
      course_array.push "#{course_id},#{short_name},#{long_name},#{account_id},#{term},active"

      # create section csv
      section_array.push section_csv(term, sections, course_id, cross_list)

      # create enrollment csv to default section
      enrollment_array.push "#{course_id},#{teacher_sis_user_id},teacher,,active\n"
      enrollment_array.push "#{course_id},#{teacher2_sis_user_id},#{teacher2_role},,active\n" unless teacher2_sis_user_id.nil?

      course_name_too_long = true if long_name.length > CANVAS_COURSE_NAME_MAX

    end

    if teacher_sis_user_id.nil?
      render :json => {
          :success => false,
          :message => 'The main teacher was not found.'
      }
    elsif course_name_too_long
      render :json => {
          :success => false,
          :message => 'The course name is too long.'
      }
    else
      # Send POST to import
      course_csv = course_array.join("\n")
      section_csv = section_array.join("\n")
      enrollment_csv = enrollment_array.join("\n")

      logger.info "[SFU Course Form] course_csv: #{course_csv.inspect}"
      SFU::Canvas.sis_import course_csv

      logger.info "[SFU Course Form] section_csv: #{section_csv.inspect}"
      SFU::Canvas.sis_import section_csv

      logger.info "[SFU Course Form] enrollment_csv: #{enrollment_csv.inspect}"
      SFU::Canvas.sis_import enrollment_csv

      # give some time for the delayed_jobs to process the import
      sleep 5
      render :json => {
        :success => true,
        :message => 'Course request submitted successfully.'
      }
    end

  end

  def course_info(course_line, account_id, teacher1, teacher2 = nil, teacher2_role = 'teacher')
    # Example; course_line = 1131:::ensc:::351:::d100:::Real Time and Embedded Systems
    course = {}
    sections = []
    course_arr = course_line.split(":::")
    course["term"] = course_arr[0]
    course["name"] = course_arr[1].to_s
    course["number"] = course_arr[2]
    course["section_name"] = course_arr[3].to_s
    course["title"] = course_arr[4].to_s
    course["child_sections"] = course_arr[5]

    course["course_id"] = "#{course["term"]}-#{course["name"]}-#{course["number"]}-#{course["section_name"]}"
    course["main_section_id"] = "#{course["term"]}-#{course["name"]}-#{course["number"]}-#{course["section_name"]}:::#{time_stamp}"
    course["short_name"] = "#{course["name"].upcase}#{course["number"]} #{course["section_name"].upcase}"
    course["long_name"] =  "#{course["short_name"]} #{course["title"]}"
    course["default_section_id"] = default_section_id(course["term"], course["main_section_id"], course["section_name"], course["child_sections"])
    course["course_csv"] = "#{course["course_id"]},#{course["short_name"]},#{course["long_name"]},#{account_id},#{course["term"]},active"
    course["enrollment_csv_1"] = "#{course["course_id"]},#{teacher1},teacher,#{course["default_section_id"]},active"
    course["enrollment_csv_2"] = "#{course["course_id"]},#{teacher2},#{teacher2_role},#{course["default_section_id"]},active" unless teacher2.nil?

    sections.push "#{course["main_section_id"]}:_:#{course["name"].upcase}#{course["number"]} #{course["section_name"].upcase}"

    # add child sections csv
    unless course["child_sections"].nil?
      course["child_sections"].split(",").compact.uniq.each do |tutorial_name|
        section_id = "#{course["term"]}-#{course["name"]}-#{course["number"]}-#{tutorial_name.downcase}:::#{time_stamp}"
        sections.push "#{section_id}:_:#{course["name"].upcase}#{course["number"]} #{tutorial_name.upcase}"
      end
    end

    course["sections"] = sections

    course
  end

  def section_csv(term, sections, course_id, cross_list=nil)
    section_array = []
    num_of_sections = sections.compact.uniq.count
    unless cross_list
      sections.compact.uniq.each do  |section|
        section_info = section.split(":_:")
        if term.to_i != 1137 && !section_info[1].to_s.end_with?("00") && num_of_sections > 1
          # Create only child sections
          section_array.push "#{section_info[0]},#{course_id},#{section_info[1]},active,,,"
        elsif term.to_i != 1137 && num_of_sections == 1
          # No child sections
          section_array.push "#{section_info[0]},#{course_id},#{section_info[1]},active,,,"
        elsif term.to_i == 1137
          section_array.push "#{section_info[0]},#{course_id},#{section_info[1]},active,,,"
        end
      end
    else
      sections.compact.uniq.each do  |section|
        section_array.push (section_csv(term, section, course_id))
      end
    end
    section_array
  end

  # e.g. course_line = sandbox-kipling-71113273
  def sandbox_info(course_line, username, teacher1, teacher2 = nil, teacher2_role = 'teacher')
    account_sis_id = "sfu:::sandbox:::instructors"
    course_arr = course_line.split("-")
    sandbox = {}
    sandbox["course_id"] = course_line
    sandbox["short_long_name"] = "Sandbox - #{username} - #{course_arr.last}"

    sandbox["csv"] = "#{sandbox["course_id"]},#{sandbox["short_long_name"]},#{sandbox["short_long_name"]},#{account_sis_id},,active"
    sandbox["enrollment_csv_1"] = "#{sandbox["course_id"]},#{teacher1},teacher,,active"
    sandbox["enrollment_csv_2"] = "#{sandbox["course_id"]},#{teacher2},#{teacher2_role},,active" unless teacher2.nil?
    sandbox
  end

  # e.g. course_line = ncc-kipling-71113273-1134-My special course
  def ncc_info(course_line, teacher1, teacher2 = nil, teacher2_role = 'teacher')
    account_sis_id = "sfu:::ncc"
    course_arr = course_line.split("-")
    ncc = {}
    ncc["course_id"] = "#{course_arr.first(3).join("-")}"
    ncc["term"] = course_arr[3] # Can be empty!
    ncc["short_long_name"] = course_arr.last

    ncc["csv"] = "#{ncc["course_id"]},#{ncc["short_long_name"]},#{ncc["short_long_name"]},#{account_sis_id},#{ncc["term"]},active"
    ncc["enrollment_csv_1"] = "#{ncc["course_id"]},#{teacher1},teacher,,active"
    ncc["enrollment_csv_2"] = "#{ncc["course_id"]},#{teacher2},#{teacher2_role},,active" unless teacher2.nil?
    ncc
  end

  def sis_user_id(username, account_id)
    user = Pseudonym.find_by_unique_id_and_account_id(username, account_id)
    user.sis_user_id unless user.nil?
  end

  def sanitize_role(role)
    # limit role to teacher (default), TA, and designer
    %w(teacher ta designer).include?(role) ? role : 'teacher'
  end

  def current_term
    EnrollmentTerm.find(:all, :conditions => ["workflow_state = 'active' AND (:date BETWEEN start_at AND end_at)", {:date => DateTime.now}]).first
  end

  def future_terms
    EnrollmentTerm.find(:all, :conditions => ["workflow_state = 'active' AND (:date <= start_at)", {:date => DateTime.now}], :order => 'sis_source_id')
  end

  def time_stamp
    t = Time.new
    "#{t.day}#{t.month}#{t.year}#{t.min}#{t.sec}"
  end

  def default_section_id(term, main_section_id, section_name, child_sections)
    if term == 1137 && (section_name.end_with? "00" || child_sections.nil?)
      # Set default Section to D100, D200, E300, G800
      # e.g. 1137-arch-329-d100:::1762013813
      main_section_id
    else
      ""
    end
  end

end
