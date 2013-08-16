require "rest-client"
require "httpclient"
require Pathname(File.dirname(__FILE__)) + "rest"

module SFU

  class Course
    class << self
      def terms(sfuid)
        terms = REST.json REST.terms_url, "&username=#{sfuid}"
        if terms.empty? || terms["teachingSemester"].nil?
          {}
        else
          terms["teachingSemester"]
        end
      end

      def for_instructor(sfuid, term_code = nil)
        terms(sfuid).map do |term|
          if term_code.nil?
            courses = REST.json REST.courses_url, "&username=#{sfuid}&term=#{term["peopleSoftCode"]}"
            courses["teachingCourse"]
          else
            if term["peopleSoftCode"] == term_code
              courses = REST.json REST.courses_url, "&username=#{sfuid}&term=#{term["peopleSoftCode"]}"
              courses["teachingCourse"]
            end
          end
        end
      end

      def info(course, term)
        REST.json REST.course_info_url, "&course=#{course}&term=#{term}"
      end

      def section_tutorials(course_code, term_code, section_code)
        details = info(course_code, term_code)
        # Used to match against sections starting with e.g. 'd1' for 'd100'
        main_section = section_code[0..1].downcase 
        sections = []

        if details != "[]" && section_code.end_with?("00")
          details.each do |info|
            code = info["course"]["name"] + info["course"]["number"]
            section = info["course"]["section"].downcase
            if code.downcase == course_code.downcase && section.start_with?(main_section) && section.downcase != section_code.downcase
              sections << info["course"]["section"]
            end
          end
        end
        sections
      end

      def title(course_code, term_code)
        details = info(course_code, term_code)
        title = ""
        unless details == "[]"
	  title = details.first["course"]["title"]
        end
	title
      end

    end
  end

  class User
    class << self
      def roles(sfuid)
        account = REST.json REST.account_url, "&username=#{sfuid}"
        account != "[]" ? account["roles"] : account
      end

      def info(sfuid)
        REST.json(REST.account_url, "&username=#{sfuid}")
      end
    end
  end

  class Canvas
    class << self
      def sis_import(csv_data)
        auth_header = "Bearer #{REST.canvas_oauth_token}"
        client = HTTPClient.new
        client.post REST.canvas_sis_import_url, csv_data, { 'Authorization' => auth_header, 'Content-Type' => 'text/csv'}
      end
    end
  end
end
