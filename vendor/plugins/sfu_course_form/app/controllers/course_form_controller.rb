require "rest_client"
require "json"
require Pathname(File.dirname(__FILE__)) + "../model/sfu/course"

class CourseFormController < ApplicationController
  unloadable

  def new
    @user = User.find(@current_user.id)
    @sfuid = @user.pseudonym.unique_id
    @course_list = Array.new
    @terms = Account.find_by_name('Simon Fraser University').enrollment_terms.delete_if {|t| t.name == 'Default Term'}
  end

  # course.csv
  # course_id,short_name,long_name,account_id,term_id,status
  # section.csv
  # section_id,course_id,name,status,start_date,end_date
  # enrollment.csv
  # course_id,user_id,role,section_id,status
  def create
    selected_courses = []
    sections = []
    account_id = Account.find_by_name('Simon Fraser University').id
    teacher_username = params[:username]
    teacher2_username = params[:enroll_me]
    teacher_sis_user_id = Pseudonym.find_by_unique_id_and_account_id(teacher_username, account_id).sis_user_id
    teacher2_sis_user_id = Pseudonym.find_by_unique_id_and_account_id(teacher2_username, account_id).sis_user_id unless teacher2_username.nil?
    cross_list = params[:cross_list]
    params.each do |key, value|
      if key.to_s.starts_with? "selected_course"
        selected_courses.push value
      end
    end

    course_array = ["course_id,short_name,long_name,account_id,term_id,status"]
    section_array = ["section_id,course_id,name,status,start_date,end_date"]
    enrollment_array = ["course_id,user_id,role,section_id,status"]

    unless cross_list
      selected_courses.each do |course|
        # 20131:::ensc:::351:::d100:::Real Time and Embedded Systems
        unless course == "sandbox"
          logger.info "[SFU Course Form] Creating single course container : #{course}"
          course_info = course.split(":::")
          term = course_info[0]
          name = course_info[1].to_s
          number = course_info[2]
          section = course_info[3].to_s
          title = course_info[4].to_s
          section_tutorials = course_info[5]

          course_id = "#{term}-#{name}-#{number}-#{section}:::course"
          section_id = "#{term}-#{name}-#{number}-#{section}:::section"
          short_name = "#{name.upcase}#{number} #{section.upcase}"
          long_name =  "#{short_name} #{title}"

          sections.push "#{section_id}:::#{section.upcase}"

          # add section tutorials csv
          unless section_tutorials.nil?
            section_tutorials.split(",").each do |tutorial|
              section_id = "#{term}-#{name}-#{number}-#{tutorial.downcase}"
              sections.push "#{section_id}:::#{tutorial.upcase}"
            end
          end

          # create course csv
          course_array.push "#{course_id},#{short_name},#{long_name},#{account_id},#{term},active"

          # create section csv
          section_array.push "#{section_id},#{course_id},#{section.upcase},active,,,"

          # create section csv
          sections.each do  |section|
            section_info = section.split(":::")
            section_array.push "#{section_info[0]}:::section,#{course_id},#{section_info[1]},active,,,"

            # create enrollment csv
            enrollment_array.push "#{course_id},#{teacher_sis_user_id},teacher,#{section_info[0]}:::section,active"

            # enroll other teacher/ta
            enrollment_array.push "#{course_id},#{teacher2_sis_user_id},teacher,#{section_info[0]}:::section,active" unless teacher2_username.nil?
          end
        else
          logger.info "[SFU Course Form] Creating sandbox for #{teacher_username}"
          #t = Time.new
          #datestamp = "#{t.year}#{t.month}#{t.day}"
          datestamp = "1"
          course_id = "sandbox-#{teacher_username}-#{datestamp}:::course"
          short_long_name = "Sandbox - #{teacher_username}"

          course_array.push "#{course_id},#{short_long_name},#{short_long_name},#{account_id},,active"
          enrollment_array.push "#{course_id},#{teacher_sis_user_id},teacher,,active"
          # enroll other teacher/ta
          enrollment_array.push "#{course_id},#{teacher2_sis_user_id},teacher,,active" unless teacher2_sis_user_id.nil?
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
        section = course_info[3].to_s
        title = course_info[4].to_s
        section_tutorials = course_info[5]

        course_id.concat "#{term}-#{name}-#{number}-#{section}:"
        section_id = "#{term}-#{name}-#{number}-#{section}"
        short_name.concat "#{name.upcase}#{number} #{section.upcase} / "
        long_name.concat  "#{name.upcase}#{number} #{section.upcase} #{title} / "

        sections.push "#{section_id}:::#{name.upcase}#{number} - #{section.upcase}"

        # add section tutorials csv
        unless section_tutorials.nil?
          section_tutorials.split(",").each do |tutorial|
            section_id = "#{term}-#{name}-#{number}-#{tutorial.downcase}"
            sections.push "#{section_id}:::#{tutorial.upcase}"
          end
        end
      end

      # create course csv
      course_id.concat "::course"
      course_array.push "#{course_id},#{short_name[0..-4]},#{long_name[0..-4]},#{account_id},#{term},active\n"

      # create section csv
      sections.each do  |section|
          section_info = section.split(":::")
          section_id = "#{section_info[0]}:::section"
          section_array.push "#{section_id},#{course_id},#{section_info[1]},active,,,\n"

          # create enrollment csv
          enrollment_array.push "#{course_id},#{teacher_sis_user_id},teacher,#{section_id},active\n"
          # enroll other teacher/ta
          enrollment_array.push "#{course_id},#{teacher2_sis_user_id},teacher,#{section_id},active\n" unless teacher2_sis_user_id.nil?
      end


    end

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
    
    # redirect to list of courses
    #redirect_to courses_url
  end

  def course_exists?(sis_source_id)
    course = Course.find(:all, :conditions => "sis_source_id='#{sis_source_id}'")
    if course.length == 1
      return true
    end
    false
  end

  # Check if user exists in Canvas
  def user
    user = Pseudonym.find(:all, :conditions => "unique_id='#{params[:sfuid]}'")
    user_hash = {}
    unless user.empty?
      user_hash["login_id"] = user.first["unique_id"]
      user_hash["sis_user_id"] = user.first["sis_user_id"]
    end

    respond_to do |format|
      format.json { render :text => user_hash.to_json }
    end
  end

  # Check if user exists in SFU Amaint
  def sfu_user
    user = SFU::User.info params[:sfuid]
    user_hash = {}

    unless user["sfuid"].nil?
      user_hash["sfuid"] = user["sfuid"]
      user_hash["commonname"] = user["commonname"]
      user_hash["lastname"] = user["lastname"]
      user_hash["status"] = user["status"]
      user_hash["roles"] = user["roles"]
    end

    respond_to do |format|
      format.json { render :text => user_hash.to_json }
    end
  end

  def courses
    course_array = []

    if params[:term].nil?
      courses = SFU::Course.for_instructor params[:sfuid]
    else
      courses = SFU::Course.for_instructor params[:sfuid], params[:term]
    end

    courses.compact.each do |course|
      course.compact.each do |c|
        course_hash = {}
        course_hash["name"] = c["course"].first["name"]
        course_hash["title"] = c["course"].first["title"]
        course_hash["number"] = c["course"].first["number"]
        course_hash["section"] = c["course"].first["section"]
        course_hash["peopleSoftCode"] = c["course"].first["peopleSoftCode"].to_s
        course_hash["sis_source_id"] = course_hash["peopleSoftCode"] + "-" +
                                       course_hash["name"].downcase +  "-" +
                                       course_hash["number"] + "-" +
                                       course_hash["section"].downcase
        course_hash["sectionTutorials"] = ""

        course_code = course_hash["name"]+course_hash["number"]

        if course_hash["section"].end_with? "00"
          if params[:term].nil?
            course_hash["sectionTutorials"] = course_section_tutorials(course_code, course_hash["peopleSoftCode"], course_hash["section"])
          else
            course_hash["sectionTutorials"] = course_section_tutorials(course_code, params[:term], course_hash["section"])
          end
        end

        course_hash["key"] = course_hash["peopleSoftCode"] + ":::" +
            course_hash["name"].downcase +  ":::" +
            course_hash["number"] + ":::" +
            course_hash["section"].downcase + ":::" +
            course_hash["title"]  + ":::" +
            course_hash["sectionTutorials"].downcase.delete(" ")

        unless course_exists? course_hash["sis_source_id"].concat(":::course")
          course_array.push course_hash
        end
      end
    end

    respond_to do |format|
      format.json { render :text => course_array.to_json }
    end

  end

  # course_code : <name><number>
  # iat100
  # term_code : 1131
  def course_section_tutorials(course_code, term_code, section_code)
    details = SFU::Course.info course_code, term_code
    main_section = section_code[0..2].downcase
    sections = ""

   unless details == "[]"
    details.each do |info|
      code = info["course"]["name"] + info["course"]["number"]
      section = info["course"]["section"].downcase
      if code.downcase == course_code.downcase && section.start_with?(main_section) && section.downcase != section_code.downcase
       	sections += info["course"]["section"] + ", "
      end
    end
   end
   sections[0..-3]
  end

  def course_info
    details = SFU::Course.info params[:course_code], params[:term]

    respond_to do |format|
      format.json { render :text => details.to_json }
    end

  end

  def terms
    terms = SFU::Course.terms params[:sfuid]
    term_array = []
    terms.each do |term|
      term_array.push term
    end

    respond_to do |format|
      format.json { render :text => term_array.reverse.to_json }
    end
  end

end
