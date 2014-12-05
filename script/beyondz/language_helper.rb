require 'yaml'

thing = YAML.load(File.read('canvas-lms/config/locales/bz.in.yml'))

def recursive_replacement(root)
    root.each do |key, value|
        if value.kind_of? String
            changed = false

            original_value = String.new(value)

            changed = value.gsub!("Quizzes", "Practices") || changed
            changed = value.gsub!("Quiz", "Practice") || changed
            changed = value.gsub!(/quizzes(?!([a-z1-9\._])*\})/, "practices") || changed
            changed = value.gsub!(/quiz(?!([a-z1-9\._])*\})/, "practice") || changed

            changed = value.gsub!("Grades", "Points") || changed
            changed = value.gsub!("Graded", "Scored") || changed
            # changed = value.gsub!("Grade", "Point") || changed
            changed = value.gsub!(/grades(?!([a-z1-9\._])*\})/, "points") || changed
            changed = value.gsub!(/graded(?!([a-z1-9\._])*\})/, "scored") || changed
            # changed = value.gsub!(/grade(?!([a-z1-9\._])*\})/, "point") || changed

            changed = value.gsub!("Syllabus", "Roadmap") || changed
            changed = value.gsub!("syllabus", "roadmap") || changed

            changed = value.gsub!("Assignments", "Artifacts") || changed
            changed = value.gsub!("Assignment", "Artifact") || changed
            changed = value.gsub!(/assignments(?!([a-z1-9\._])*\})/, "artifacts") || changed
            changed = value.gsub!(/assignment(?!([a-z1-9\._])*\})/, "assignment") || changed

            if value == original_value
              changed = false
            end

            if changed
                puts("#{key}: \033[33m#{original_value}\033[39m ==> \033[32m#{value}\033[39m")

                approve = gets
                if approve.nil?
                  raise "done"
                end
                approve = approve.chop
                if !approve.empty?
                  value.sub!(/.*/, original_value)
                else
                  puts "APPROVED!"
                end
            end
        end

        if value.kind_of? Hash
            recursive_replacement(value)
        end
    end
end

begin
  recursive_replacement(thing)
rescue
end

File.write('canvas-lms/config/locales/bz.in.yml', YAML.dump(thing))
