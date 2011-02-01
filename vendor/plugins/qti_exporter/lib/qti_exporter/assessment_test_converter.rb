module Qti
class AssessmentTestConverter
  TEST_FILE = "/home/bracken/projects/QTIMigrationTool/assessments/out/assessmentTests/assmnt_URN-X-WEBCT-VISTA_V2-790EA1350A1A681DE0440003BA07D9B4.xml"
  DEFAULT_POINTS_POSSIBLE = 1

  attr_reader :base_dir, :identifier, :href, :interaction_type, :title, :quiz

  def initialize(manifest_node, base_dir, is_webct=true)
    @log = Canvas::Migration::logger
    @manifest_node = manifest_node
    @base_dir = base_dir
    @href = File.join(@base_dir, @manifest_node['href'])
    @is_webct = is_webct

    @quiz = {
            :questions=>[],
            :quiz_type=>nil,
            :question_count=>0
    }
  end

  def create_instructure_quiz
    begin
      # Get manifest data
      if md = @manifest_node.at_css("instructuremetadata")
        if item = md.at_css('instructurefield[name=show_score] @value')
          @quiz[:show_score] = item.text =~ /true/i ? true : false
        end
        if item = md.at_css('instructurefield[name=quiz_type] @value') or  item = md.at_css('instructurefield[name=bb8_assessment_type] @value')
          # known possible values: Self-assessment, Survey, Examination (practice is instructure default)
          # BB8: Test, Pool
          @quiz[:quiz_type] = "assignment" if item.text =~ /examination|test|quiz/i
          if item.text =~ /pool/i
            # if it's pool we don't need to make a quiz object.
            return nil
          end
        end
        if item = md.at_css('instructurefield[name=which_attempt_to_keep] @value')
          # known possible values: Highest, First, Last (highest is instructure default)
          @quiz[:which_attempt_to_keep] = "keep_latest" if item.text =~ /last/i
        end
        if item = md.at_css('instructurefield[name=max_score] @value')
          @quiz[:points_possible] = item.text
        end
        if item = md.at_css('instructurefield[name=bb8_object_id] @value')
          @quiz[:alternate_migration_id] = item.text
        end
      end

      # Get the actual assessment file
      doc = Nokogiri::HTML(open(@href))
      parse_quiz_data(doc)
      
      if @quiz[:quiz_type] == 'assignment'
        grading = {}
        grading[:migration_id] = @quiz[:migration_id]
        grading[:points_possible] = @quiz[:points_possible]
        grading[:weight] = nil
        grading[:due_date] = nil
        grading[:title] = @quiz[:title]
        grading[:grade_type] = 'numeric' if grading[:points_possible]
        @quiz[:grading] = grading
      end
    rescue
      @quiz[:qti_error] = "Error converting QTI quiz: #{$!}: #{$!.backtrace.join("\n\t")}" 
      @log.error "Error converting QTI quiz: #{$!}: #{$!.backtrace.join("\n\t")}"
    end

    @quiz
  end

  def parse_quiz_data(doc)
    @quiz[:title] = @title || doc.at_css('assessmenttest @title').text
    @quiz[:quiz_name] = @quiz[:title]
    @quiz[:migration_id] = doc.at_css('assessmenttest @identifier').text
    if part = doc.at_css('testpart[identifier=BaseTestPart]')
      if control = part.at_css('itemsessioncontrol')
        if max = control.at_css('@maxattempts')
          max = max.text.to_i
          # -1 means no limit in instructure, 0 means no limit in QTI
          @quiz[:allowed_attempts] = max >= 1 ? max : -1
        end
        if show = control.at_css('@showSolution')
          show = show.text
          @quiz[:show_correct_answers] = show.downcase == "true" ? true : false
        end
        if limit = doc.search('timelimits').first
          limit = limit['maxtime'].to_i
          #instructure uses minutes, QTI uses seconds
          @quiz[:time_limit] = limit / 60
        end
      end

      process_section(part)
    else
      @quiz[:qti_error] = "Instructure doesn't support QTI importing from this source." 
      @log.error "Attempted to convert QTI from non-supported source. (it wasn't run through the python conversion tool.)"
    end
  end

  def process_section(section)
    group = nil
    questions_list = @quiz[:questions]
    
    if shuffle = section.at_css('ordering @shuffle')
      @quiz[:shuffle_answers] = true if shuffle.text =~ /true/i
    end
    if select = section.children.find {|child| child.name == "selection"}
      select = select['select'].to_i
      if select > 0
        group = {:questions=>[], :pick_count => select, :question_type => 'question_group'}
        group[:question_points] = DEFAULT_POINTS_POSSIBLE
        if weight = section.at_css('weight @value')
          group[:question_points] = convert_weight_to_points(weight)
        end
        if bank_id = section.at_css('sourcebank_ref')
          group[:question_bank_migration_id] = bank_id.text
        end
        group[:migration_id] = section['identifier'] && section['identifier'] != "" ? section['identifier'] : rand(100_000)
        questions_list = group[:questions]
      end
    end
    if section['visible'] and section['visible'] =~ /true/i
      if title = section['title']
        #Create an empty question with a title in it
        @quiz[:questions] << {:question_type => 'text_only_question', :question_text => title, :migration_id => rand(100_000)}
      end
    end
    
    section.children.each do |child|
      if child.name == "assessmentsection"
        process_section(child)
      elsif child.name == "assessmentitemref"
        process_question(child, questions_list)
      end
    end
    
    @quiz[:questions] << group if group and (!group[:questions].empty? || group[:question_bank_migration_id])
    
    questions_list
  end
  
  def process_question(item_ref, questions_list)
    question = {:question_type => 'question_reference'}
    questions_list << question
    @quiz[:question_count] += 1
    # The colons are replaced with dashes in the conversion from QTI 1.2
    question[:migration_id] = item_ref['identifier'].gsub(/:/, '-')
    if weight = item_ref.at_css('weight @value')
      question[:points_possible] = convert_weight_to_points(weight)
    end
  end
  
  # the weight from a webct system is represented as a float like 0.05,
  # but the point value for that float is actually 5. So if it's from
  # webct multiply it by 100
  def convert_weight_to_points(weight)
    begin
      weight = weight.text.to_f
      if @is_webct
        weight = weight * 100 
      end
    rescue
      weight = DEFAULT_POINTS_POSSIBLE
    end
    weight
  end

end
end
