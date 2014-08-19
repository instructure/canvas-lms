require "rest-client"
require "httpclient"
require Pathname(File.dirname(__FILE__)) + "rest"

module SFU

  class Course
    class << self
      def terms(sfuid)
        terms = REST.json REST.terms_url, "&username=#{sfuid}"
        if terms == 404 || terms.empty?
          404
        elsif terms == 500
          500
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

      def sections_exists?(json_data, section_code)
        json_data.any? do |info|
          info["course"]["section"].to_s.downcase.eql?(section_code)
        end
      end

      def have_tutorials?(json_data, associated_class)
        json_data.any? do |info|
          class_type = info["course"]["classType"].to_s.downcase
          section_code = info["course"]["sectionCode"].to_s.downcase
          associated_class == info["course"]["associatedClass"] && class_type.eql?("n") && section_code.eql?("tut")
        end
      end

      def have_labs?(json_data, associated_class)
        json_data.any? do |info|
          class_type = info["course"]["classType"].to_s.downcase
          section_code = info["course"]["sectionCode"].to_s.downcase
          associated_class == info["course"]["associatedClass"] && class_type.eql?("n") && section_code.eql?("lab")
        end
      end

      def is_enrollment_section?(json_data, section_code)
        json_data.any? do |info|
          info["course"]["section"].to_s.downcase.eql?(section_code) && info["course"]["classType"].to_s.downcase.eql?("e")
        end
      end

      def associated_class_for_section(json_data, section_code)
        associated_class = nil
        json_data.each do |info|
          associated_class = info["course"]["associatedClass"] if info["course"]["section"].to_s.downcase.eql?(section_code)
        end
        associated_class
      end

      def section_tutorials(course_code, term_code, section_code)
        details = info(course_code, term_code)
        sections = []
        has_no_child_sections = true

        if details != "[]" && is_enrollment_section?(details, section_code)
          associated_class = associated_class_for_section(details, section_code)
          have_tutorials = have_tutorials?(details, associated_class)
          have_labs = have_labs?(details, associated_class)

          details.each do |info|
            class_type = info["course"]["classType"]
            section_code = info["course"]["sectionCode"].to_s.downcase

            if class_type.eql?("n") && associated_class == info["course"]["associatedClass"]
              if have_tutorials && have_labs
                # Only return tutorials for enrollment sections that have both labs and tutorials
                sections << info["course"]["section"] if section_code.eql?("tut")
                has_no_child_sections = false
              else
                sections << info["course"]["section"]
                has_no_child_sections = false
              end
            end
          end
        end

        # Return main section e.g. d100 only for courses with no tutorial/lab sections
        sections << section_code.upcase if has_no_child_sections && sections_exists?(details, section_code)

        sections
      end

      def title(course_code, term_code, section_code)
        details = info(course_code, term_code)
        title = nil
        if details == 500
          title = 500
        elsif details == 404
          title == 404
        elsif details != "[]"
          details.each do |info|
            section = info["course"]["section"].downcase
            title = info["course"]["title"] if section.eql? section_code.downcase
          end
        end
        title
      end

    end
  end

  class User
    class << self
      def roles(sfuid)
        account = REST.json REST.account_url, "&username=#{sfuid}"
        if account == 500
          roles = 500
        elsif account == 404 || account.nil?
          roles = 404
        else
          roles = account["roles"]
        end
        roles
      end

      def info(sfuid)
        REST.json(REST.account_url, "&username=#{sfuid}")
      end

      def belongs_to_maillist?(username, maillist)
        membership = REST.text(REST.maillist_membership_url, "&address=#{username}&listname=#{maillist}")
        !(membership == '""')
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
