require "rest-client"
require "httpclient"
require Pathname(File.dirname(__FILE__)) + "rest"

module SFU

  class Course
    class << self
      def terms(sfuid)
        terms = Rest.json Rest.terms_url, "&username=#{sfuid}"
        if terms.empty? || terms["teachingSemester"].nil?
          {}
        else
          terms["teachingSemester"]
        end
      end

      def for_instructor(sfuid, term_code = nil)
        terms(sfuid).map do |term|
          if term_code.nil?
            courses = Rest.json Rest.courses_url, "&username=#{sfuid}&term=#{term["peopleSoftCode"]}"
            courses["teachingCourse"]
          else
            if term["peopleSoftCode"] == term_code
              courses = Rest.json Rest.courses_url, "&username=#{sfuid}&term=#{term["peopleSoftCode"]}"
              courses["teachingCourse"]
            end
          end
        end
      end

      def info(course, term)
        Rest.json Rest.course_info_url, "&course=#{course}&term=#{term}"
      end

    end
  end

  class User
    class << self
      def roles(sfuid)
        account = Rest.json Rest.account_url, "&username=#{sfuid}"
        account != "[]" ? account["roles"] : account
      end

      def info(sfuid)
        Rest.json Rest.account_url, "&username=#{sfuid}"
      end

      def student_only?(sfuid)
        result = roles sfuid
        if result.to_a.join("").eql? "undergrad"
          return true
        end
        false
      end

    end
  end

  class Canvas
    class << self
      def sis_import(csv_data)
        auth_header = "Bearer #{Rest.canvas_oauth_token}"
        client = HTTPClient.new
        client.post Rest.canvas_sis_import_url, csv_data, { 'Authorization' => auth_header, 'Content-Type' => 'text/csv'}
      end
    end
  end
end
