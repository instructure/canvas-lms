module SFU
  module CourseForm
    class CSVBuilder

      # Canvas course names and SIS IDs have a limit of 255 characters max.
      CANVAS_COURSE_NAME_MAX = 255
      CANVAS_COURSE_SIS_ID_MAX = 255

      def self.build(req_user, selected_courses, account_id, teacher_username, teacher_sis_user_id, teacher2_sis_user_id, teacher2_role, cross_list)
        builder = self.new
        builder.build(req_user, selected_courses, account_id, teacher_username, teacher_sis_user_id, teacher2_sis_user_id, teacher2_role, cross_list)
      end

      def build(req_user, selected_courses, account_id, teacher_username, teacher_sis_user_id, teacher2_sis_user_id, teacher2_role, cross_list)
        raise 'The main teacher was not found.' if teacher_sis_user_id.nil?

        course_array = [%w(course_id short_name long_name account_id term_id status start_date end_date)]
        section_array = [%w(section_id course_id name status start_date end_date)]
        enrollment_array = [%w(course_id user_id role section_id status)]

        course_name_too_long = false
        course_sis_id_too_long = false

        if cross_list

          Rails.logger.info "[SFU Course Form] Creating cross-list container : #{selected_courses.inspect} requested by #{req_user}"
          course_ids = []
          short_names = []
          long_names = []
          term = ''
          sections = []

          selected_courses.each do |course|
            course_info = course_info(course, account_id, teacher_sis_user_id, teacher2_sis_user_id, teacher2_role)

            course_ids.push course_info[:course_id]
            short_names.push course_info[:short_name]
            long_names.push course_info[:long_name]
            term = course_info[:term]

            sections.push course_info[:sections]
          end

          course_id = course_ids.join(':')
          short_name = short_names.join(' / ')
          long_name = long_names.join(' / ')

          # Use a shorter version (omit subsequent titles) of the long name if it's too long.
          # Original long name: IAT100 D100 Example Course / IAT100 D200 Example Course / IAT100 D300 Example Course
          # Shorter version:    IAT100 D100 Example Course / IAT100 D200 / IAT100 D300
          long_name = (long_names[0, 1] + short_names[1..-1]).join(' / ') if long_name.length > CANVAS_COURSE_NAME_MAX

          # create course csv
          selected_term = self.class.term(term)
          course_array.push [course_id, short_name, long_name, account_id, term, 'active', selected_term.start_at, selected_term.end_at]

          # create section csv
          sections.each { |section| section_array.concat section_csv(term, section, course_id) }

          # create enrollment csv to default section
          enrollment_array.push [course_id, teacher_sis_user_id, 'teacher', nil, 'active']
          enrollment_array.push [course_id, teacher2_sis_user_id, teacher2_role, nil, 'active'] unless teacher2_sis_user_id.nil?

          course_name_too_long = true if long_name.length > CANVAS_COURSE_NAME_MAX
          course_sis_id_too_long = true if course_id.length > CANVAS_COURSE_SIS_ID_MAX

        else

          selected_courses.each do |course|
            if course.starts_with? 'sandbox'
              Rails.logger.info "[SFU Course Form] Creating sandbox for #{teacher_username} requested by #{req_user}"
              sandbox = sandbox_info(course, teacher_username, teacher_sis_user_id, teacher2_sis_user_id, teacher2_role)

              course_array.push sandbox[:course]
              enrollment_array.concat sandbox[:enrollments]

              course_name_too_long = true if sandbox[:short_long_name].length > CANVAS_COURSE_NAME_MAX
              course_sis_id_too_long = true if sandbox[:course_id].length > CANVAS_COURSE_SIS_ID_MAX
            elsif course.starts_with? 'ncc'
              Rails.logger.info "[SFU Course Form] Creating ncc course for #{teacher_username} requested by #{req_user}"
              ncc_course = ncc_info(course, teacher_sis_user_id, teacher2_sis_user_id, teacher2_role)

              course_array.push ncc_course[:course]
              enrollment_array.concat ncc_course[:enrollments]

              course_name_too_long = true if ncc_course[:short_long_name].length > CANVAS_COURSE_NAME_MAX
              course_sis_id_too_long = true if ncc_course[:course_id].length > CANVAS_COURSE_SIS_ID_MAX
            else
              Rails.logger.info "[SFU Course Form] Creating single course container : #{course} requested by #{req_user}"
              course_info = course_info(course, account_id, teacher_sis_user_id, teacher2_sis_user_id, teacher2_role)

              # create course csv
              course_array.push course_info[:course]

              # create section csv
              section_array.concat section_csv(course_info[:term], course_info[:sections], course_info[:course_id])

              enrollment_array.concat course_info[:enrollments]

              course_name_too_long = true if course_info[:long_name].length > CANVAS_COURSE_NAME_MAX
              course_sis_id_too_long = true if course_info[:course_id].length > CANVAS_COURSE_SIS_ID_MAX
            end
          end

        end

        raise 'The course name is too long.' if course_name_too_long
        raise 'The resulting course SIS ID is too long.' if course_sis_id_too_long

        course_csv = csv_string(course_array)
        section_csv = csv_string(section_array)
        enrollment_csv = csv_string(enrollment_array)

        [course_csv, section_csv, enrollment_csv]
      end

      def course_info(course_line, account_id, teacher1, teacher2 = nil, teacher2_role = 'teacher')
        # Example; course_line = 1131:::ensc:::351:::d100:::Real Time and Embedded Systems
        course = { :enrollments => [] }
        course[:sections] = []
        course_arr = course_line.split(':::')
        course[:term] = course_arr[0]
        name = course_arr[1].to_s
        number = course_arr[2]
        section_name = course_arr[3].to_s
        title = course_arr[4].to_s
        child_sections = course_arr[5]

        selected_term = self.class.term(course[:term])

        course[:course_id] = "#{course[:term]}-#{name}-#{number}-#{section_name}"
        course[:main_section_id] = "#{course[:course_id]}:::#{time_stamp}"
        course[:short_name] = "#{name}#{number} #{section_name}".upcase
        course[:long_name] =  "#{course[:short_name]} #{title}"
        course[:default_section_id] = default_section_id(course[:term], course[:main_section_id], section_name, child_sections)
        course[:course] = [course[:course_id], course[:short_name], course[:long_name], account_id, course[:term], 'active', selected_term.start_at, selected_term.end_at]
        course[:enrollments] << [course[:course_id], teacher1, 'teacher', course[:default_section_id], 'active']
        course[:enrollments] << [course[:course_id], teacher2, teacher2_role, course[:default_section_id], 'active'] unless teacher2.nil?

        course[:sections].push [course[:main_section_id], course[:short_name]]

        # add child sections csv
        unless child_sections.nil?
          child_sections.split(',').compact.uniq.each do |tutorial_name|
            section_id = "#{course[:term]}-#{name}-#{number}-#{tutorial_name.downcase}:::#{time_stamp}"
            course[:sections].push [section_id, "#{name}#{number} #{tutorial_name}".upcase]
          end
        end

        course
      end

      def section_csv(term, sections, course_id)
        sections = sections.compact.uniq
        sections.map! do |section_info|
          # Skip Dx00 section if there are other child sections (except in Fall 2013)
          next if term.to_i != 1137 && sections.count > 1 && section_info[1].to_s.end_with?('00')

          [section_info[0], course_id, section_info[1], 'active', nil, nil, nil]
        end
        sections.compact
      end

      # e.g. course_line = sandbox-kipling-71113273
      def sandbox_info(course_line, username, teacher1, teacher2 = nil, teacher2_role = 'teacher')
        account_sis_id = 'sfu:::sandbox:::instructors'
        course_arr = course_line.split('-')
        sandbox = { :enrollments => [] }
        sandbox[:course_id] = course_line
        sandbox[:short_long_name] = "Sandbox - #{username} - #{course_arr.last}"

        sandbox[:course] = [sandbox[:course_id], sandbox[:short_long_name], sandbox[:short_long_name], account_sis_id, nil, 'active']
        sandbox[:enrollments] << [sandbox[:course_id], teacher1, 'teacher', nil, 'active']
        sandbox[:enrollments] << [sandbox[:course_id], teacher2, teacher2_role, nil, 'active'] unless teacher2.nil?
        sandbox
      end

      # e.g. course_line = ncc-kipling-71113273-1134-My special course
      def ncc_info(course_line, teacher1, teacher2 = nil, teacher2_role = 'teacher')
        account_sis_id = 'sfu:::ncc'
        course_arr = course_line.split('-', 5)
        ncc = { :enrollments => [] }
        ncc[:course_id] = course_arr.first(3).join('-')
        ncc[:term] = course_arr[3] # Can be empty!
        ncc[:short_long_name] = course_arr.last

        # Similar to credit courses, we explicitly set the start/end dates (except for "default term")
        selected_term = self.class.term(ncc[:term])
        start_date = selected_term ? selected_term.start_at : ''
        end_date = selected_term ? selected_term.end_at : ''

        ncc[:course] = [ncc[:course_id], ncc[:short_long_name], ncc[:short_long_name], account_sis_id, ncc[:term], 'active', start_date, end_date]
        ncc[:enrollments] << [ncc[:course_id], teacher1, 'teacher', nil, 'active']
        ncc[:enrollments] << [ncc[:course_id], teacher2, teacher2_role, nil, 'active'] unless teacher2.nil?
        ncc
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
          nil
        end
      end

      def self.term(term_code)
        EnrollmentTerm.find(:all, :conditions => ["workflow_state = 'active' AND sis_source_id = :term", {:term => term_code}]).first
      end

      def csv_string(data)
        CSV.generate do |csv|
          data.each { |row| csv << row }
        end
      end

    end
  end
end