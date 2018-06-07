module Export
  module GradeDownload
    class << self
      def csv user, params
        assignments_info = []

        students = []

        if params[:assignment_id]
          assignments_info << get_assignment_info(user, params[:assignment_id])
          students = Course.find(Assignment.find(params[:assignment_id]).context_id).students.active
        elsif params[:course_id]
          Course.find(params[:course_id]).assignments.active.each do |a|
            assignments_info << get_assignment_info(user, a.id)
          end
          students = Course.find(params[:course_id]).students.active
        end

        output = CSV.generate do |output|
          # header
          row = []
          row << "Student ID"
          row << "Student Name"
          row << "Student Email"

          assignments_info.each do |assignment_info|
            assignment = assignment_info[:assignment]
            criteria = assignment_info[:criteria]
            sections = assignment_info[:sections]

            row << "Total Score -- #{assignment.name}"

            sections.each do |section|
              row << "Category #{section} Average -- #{assignment.name}"
            end

            criteria.each do |criterion|
              row << "#{criterion["description"]} -- #{assignment.name}"
            end
          end

          output << row

          # data
          students_done = {}
          students.each do |student_obj|
            next if students_done[student_obj.id]
            students_done[student_obj.id] = true

            row = []
            # name
            row << student_obj.id
            row << student_obj.name
            row << student_obj.email

            assignments_info.each do |assignment_info|
              sg = assignment_info[:sg]
              assignment = assignment_info[:assignment]
              rubric = assignment_info[:rubric]
              criteria = assignment_info[:criteria]
              sections = assignment_info[:sections]
              sections_points_available = assignment_info[:sections_points_available]

              student = nil

              sg["context"]["students"].each do |student_sg|
                if student_sg["id"].to_i == student_obj.id.to_i
                  student = student_sg
                  break
                end
              end
              if student.nil?
                student = {}
                student["name"] = student_obj.name
                student["rubric_assessments"] = []
              end

              latest_assessment = student["rubric_assessments"].last

              # total score
              if latest_assessment
                row << "#{(latest_assessment["score"].to_f * 100 / assignment.points_possible.to_f).round(2)}%"
              else
                row << "0"
              end

              # section averages...

              section_scores = []

              criteria.each do |criterion|
                points = 0.0
                if latest_assessment
                  latest_assessment["data"].each do |datum|
                    points = datum["points"].to_f if datum["criterion_id"] == criterion["criterion_id"]
                  end
                end
                if section_scores[criterion["section"].to_i].nil?
                  section_scores[criterion["section"].to_i] = 0.0
                end
                section_scores[criterion["section"].to_i] += points # zero-based array of one-based sections
              end


              sections.each do |idx|
                ss = section_scores[idx.to_i]
                if sections_points_available[idx.to_i].nil?
                  row << ss
                else
                  row << "#{(ss * 100 / sections_points_available[idx.to_i]).round(2)}%"
                end
              end

              # individual breakdown...

              criteria.each do |criterion|
                points = 0.0
                if latest_assessment
                  latest_assessment["data"].each do |datum|
                    points = datum["points"].to_f if datum["criterion_id"] == criterion["criterion_id"]
                  end
                end
                row << points
              end
            end
            output << row
          end
        end
      
        output
      end
    
      def get_assignment_info(user, assignment_id)
        assignment = Assignment.find(assignment_id)
        sg = Assignment::SpeedGrader.new(
          assignment,
          user,
          avatars: false,
          grading_role: :grader
        ).json

        rubric = assignment.rubric

        criteria = []
        if rubric
          rubric.data.each do |criterion|
            obj = {}
            obj["description"] = criterion["description"]
            obj["criterion_id"] = criterion["id"]
            if criterion["description"]
              obj["section"] = criterion["description"][/^([0-9]+)/, 1]
              obj["subsection"] = criterion["description"][/^[0-9]+\.([0-9]+)/, 1]
            else
              obj["section"] = 0
              obj["subsection"] = 0
            end
            obj["points_available"] = criterion["points"]
            criteria << obj
          end
        end

        criteria = criteria.sort_by { |h| [h["section"], h["subsection"]] }

        sections = []
        criteria.each do |c|
          if sections.length == 0 || sections[-1] != c["section"]
            sections << c["section"]
          end
        end

        sections_points_available = []
        criteria.each do |c|
          sections_points_available[c["section"].to_i] = 0.0 if sections_points_available[c["section"].to_i].nil?
          sections_points_available[c["section"].to_i] += c["points_available"].to_f
        end

        assignment_info = {}
        assignment_info[:sg] = sg
        assignment_info[:assignment] = assignment
        assignment_info[:rubric] = rubric
        assignment_info[:criteria] = criteria
        assignment_info[:sections] = sections
        assignment_info[:sections_points_available] = sections_points_available

        assignment_info
      end
    end
  end
end