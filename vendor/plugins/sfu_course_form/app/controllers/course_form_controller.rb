require Pathname(File.dirname(__FILE__)) + "../../../sfu_api/app/model/sfu/course"

class CourseFormController < ApplicationController

  def new
    @user = User.find(@current_user.id)
    @sfuid = @user.pseudonym.unique_id
    @course_list = Array.new
    @terms = Account.find_by_name('Simon Fraser University').enrollment_terms.delete_if {|t| t.name == 'Default Term'}
    if SFU::User.student_only? @sfuid
      flash[:error] = "You don't have permission to access that page"
      redirect_to dashboard_url
    end
  end

  def create
    selected_courses = []
    sections = []
    account_id = Account.find_by_name('Simon Fraser University').id
    teacher_username = params[:username]
    teacher2_username = params[:enroll_me]
    teacher_sis_user_id = sis_user_id(teacher_username, account_id)
    teacher2_sis_user_id = sis_user_id(teacher2_username, account_id) unless teacher2_username.nil?
    cross_list = params[:cross_list]
    params.each do |key, value|
      if key.to_s.starts_with? "selected_course"
        selected_courses.push value
      end
    end

    course_array = ["course_id,short_name,long_name,account_id,term_id,status"]
    section_array = ["section_id,course_id,name,status,start_date,end_date"]
    enrollment_array = ["course_id,user_id,role,section_id,status"]
    default_section_id = ""

    unless cross_list
      selected_courses.compact.uniq.each do |course|
        # 1131:::ensc:::351:::d100:::Real Time and Embedded Systems
        unless course == "sandbox"
          logger.info "[SFU Course Form] Creating single course container : #{course}"
          course_info = course.split(":::")
          term = course_info[0]
          name = course_info[1].to_s
          number = course_info[2]
          section_name = course_info[3].to_s
          title = course_info[4].to_s
          section_tutorials = course_info[5]

          course_id = "#{term}-#{name}-#{number}-#{section_name}"
          section_id = "#{term}-#{name}-#{number}-#{section_name}:::section"
          short_name = "#{name.upcase}#{number} #{section_name.upcase}"
          long_name =  "#{short_name} #{title}"
          # Default Section set D100, D200, E300, G800 or if only 1 section (i.e. no section tutorials)
          default_section_id = section_id if section_name.end_with? "00" || section_tutorials.nil?

          sections.push "#{section_id}:_:#{section_name.upcase}"

          # add section tutorials csv
          unless section_tutorials.nil?
            section_tutorials.split(",").each do |tutorial_name|
              section_id = "#{term}-#{name}-#{number}-#{tutorial_name.downcase}:::section"
              sections.push "#{section_id}:_:#{tutorial_name.upcase}"
            end
          end

          # create course csv
          course_array.push "#{course_id},#{short_name},#{long_name},#{account_id},#{term},active"

          # create section csv
          sections.compact.uniq.each do  |section|
            section_info = section.split(":_:")
            section_array.push "#{section_info[0]},#{course_id},#{section_info[1]},active,,,"
          end

          # create enrollment csv to default section
          enrollment_array.push "#{course_id},#{teacher_sis_user_id},teacher,#{default_section_id},active"
          # enroll other teacher/ta to default section
          enrollment_array.push "#{course_id},#{teacher2_sis_user_id},teacher,#{default_section_id},active" unless teacher2_username.nil?
        else
          logger.info "[SFU Course Form] Creating sandbox for #{teacher_username}"
          datestamp = "1"
          course_id = "sandbox-#{teacher_username}-#{datestamp}"
          short_long_name = "Sandbox - #{teacher_username}"

          course_array.push "#{course_id},#{short_long_name},#{short_long_name},#{account_id},,active"
          # create enrollment csv to default section
          enrollment_array.push "#{course_id},#{teacher_sis_user_id},teacher,#{default_section_id},active"
          # enroll other teacher/ta to default section
          enrollment_array.push "#{course_id},#{teacher2_sis_user_id},teacher,#{default_section_id},active" unless teacher2_sis_user_id.nil?
        end
      end
    else
      logger.info "[SFU Course Form] Creating cross-list container : #{selected_courses.inspect}"
      course_id = ""
      short_name = ""
      long_name = ""
      term = ""

      selected_courses.each do |course|
        course_info = course.split(":::")
        term = course_info[0]
        name = course_info[1].to_s
        number = course_info[2]
        section_name = course_info[3].to_s
        title = course_info[4].to_s
        section_tutorials = course_info[5]

        course_id.concat "#{term}-#{name}-#{number}-#{section_name}:"
        section_id = "#{term}-#{name}-#{number}-#{section_name}:::section"
        short_name.concat "#{name.upcase}#{number} #{section_name.upcase} / "
        long_name.concat  "#{name.upcase}#{number} #{section_name.upcase} #{title} / "

        sections.push "#{section_id}:_:#{name.upcase}#{number} #{section_name.upcase}"

        # add section tutorials csv
        unless section_tutorials.nil?
          section_tutorials.split(",").compact.uniq.each do |tutorial_name|
            section_id = "#{term}-#{name}-#{number}-#{tutorial_name.downcase}:::section"
            sections.push "#{section_id}:_:#{tutorial_name.upcase}"
          end
        end
      end

      # create course csv
      course_id.concat "::course"
      course_array.push "#{course_id},#{short_name[0..-4]},#{long_name[0..-4]},#{account_id},#{term},active"

      # create section csv
      sections.compact.uniq.each do  |section|
          section_info = section.split(":_:")
          section_array.push "#{section_info[0]},#{course_id},#{section_info[1]},active,,,"
      end

      # create enrollment csv to default section
      enrollment_array.push "#{course_id},#{teacher_sis_user_id},teacher,#{default_section_id},active\n"
      # enroll other teacher/ta to default section
      enrollment_array.push "#{course_id},#{teacher2_sis_user_id},teacher,#{default_section_id},active\n" unless teacher2_sis_user_id.nil?

    end

    unless teacher_sis_user_id.nil?
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
      flash[:notice] = "Course request submitted successfully"
    else
      flash[:error] = "Course request failed. Please try agin."
      redirect_to "/sfu/course/new"
    end
  end

  def sis_user_id(username, account_id)
    user = Pseudonym.find_by_unique_id_and_account_id(username, account_id)
    user.sis_user_id unless user.nil?
  end
end
