require Pathname(File.dirname(__FILE__)) + "../model/sfu/sfu"

class AmaintController < ApplicationController
  before_filter :require_user
  include Common

  def course_info
    course_hash = amaint_course_info(params[:sis_id], params[:property])

    if course_hash == 404
      raise(ActiveRecord::RecordNotFound)
    elsif course_hash == 500
      raise(RuntimeError)
    end

    respond_to do |format|
      format.json { render :json => course_hash }
    end
  end

  def user_info
    user_array =[]
    sfu_id = params[:sfu_id]
    roles = SFU::User.roles sfu_id

    if roles == 500 || roles == 404
      user_array = roles
    else
      if params[:property].nil?
        user_hash = {}
        user_hash["sfu_id"] = sfu_id
        user_hash["roles"] = roles
        user_array = user_hash
      elsif params[:property].to_s.eql? "roles"
        user_array = roles
      elsif params[:filter].nil? && params[:property].to_s.start_with?("term")
        user_array = teaching_terms_for sfu_id
      elsif params[:property].to_s.start_with?("term")
        user_array = courses_for_user(sfu_id, params[:filter])
      end
    end

    if user_array == 500
      raise(RuntimeError)
    elsif user_array == 404
      raise(ActiveRecord::RecordNotFound)
    end

    respond_to do |format|
      format.json { render :json => user_array }
    end
  end

  def amaint_course_info(sis_id, property=nil)
    # sis_id format 1131:::math:::100:::d300:::Precalculus
    # or format 1131-math-100-d300
    sis_id.gsub!(":::","-")    
    course_hash = {}
    course_info = sis_id.split("-")
    course_hash["name"] = course_info[1]
    course_hash["number"] = course_info[2]
    course_hash["section"] = course_info[3]
    course_hash["peopleSoftCode"] = course_info.first
    course_hash["sis_source_id"] = course_hash["peopleSoftCode"] + "-" +
        course_hash["name"].downcase +  "-" +
        course_hash["number"] + "-" +
        course_hash["section"].downcase

    # If asking for a specific property then clear hash
    course_hash = {} unless property.nil?
    section_tutorials = SFU::Course.section_tutorials(course_info[1] + course_info[2], course_info.first, course_info[3]) if property.nil? || property.downcase.eql?("sectiontutorials")
    course_hash["sectionTutorials"] = section_tutorials if !section_tutorials.empty?
    course_title = SFU::Course.title(course_info[1] + course_info[2], course_info.first, course_info[3]) #if property.nil? || property.downcase.eql?("title")
    course_hash["title"] = course_title if property.nil? || property.downcase.eql?("title")

    if course_title.nil?
      # If course section doesn't exist in Amaint, then return 404
      course_hash = 404
    elsif course_title == 500 || course_title == 404
      # If REST server app is unavailable, its webserver returns a 404.
      # Therefore return 500 so client will know something is wrong with REST server and not a false 404 (i.e. section doesn't exists)
      course_hash = 500
    end

    course_hash
  end

  def courses_for_user(sfu_id, term_code=nil)
    course_array = []
    exclude_sectionCode = ["STL", "LAB", "TUT"]

    if term_code.nil?
      courses = SFU::Course.for_instructor(sfu_id)
    else
      courses = SFU::Course.for_instructor(sfu_id, term_code)
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
        course_hash["sectionCode"] = c["course"].first["sectionCode"]

        course_code = course_hash["name"]+course_hash["number"]

        if course_hash["section"].end_with? "00"
          if term_code.nil?
            course_hash["sectionTutorials"] = SFU::Course.section_tutorials(course_code, course_hash["peopleSoftCode"], course_hash["section"])
          else
            course_hash["sectionTutorials"] = SFU::Course.section_tutorials(course_code, term_code, course_hash["section"])
          end
        end

        course_hash["key"] = course_hash["peopleSoftCode"] + ":::" +
                             course_hash["name"].downcase +  ":::" +
                             course_hash["number"] + ":::" +
                             course_hash["section"].downcase + ":::" +
                             course_hash["title"]
        course_hash["key"].concat ":::" + course_hash["sectionTutorials"].join(',').downcase unless course_hash["sectionTutorials"].empty?

        # hide course if already exists in Canvas or is a Tutorial/Lab
        course_array.push course_hash unless course_exists? course_hash["sis_source_id"] unless exclude_sectionCode.include? c["course"].first["sectionCode"].to_s
      end
    end
    course_array
  end

  def teaching_terms_for(sfu_id)
    term_array = []
    terms = SFU::Course.terms sfu_id
    if terms == 500 || terms == 404
      term_array = terms
    else
      terms.each do |term|
        term_array.push term
      end
    end
    term_array
  end

end
