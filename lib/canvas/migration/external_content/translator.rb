module Canvas::Migration::ExternalContent
  class Translator

    attr_reader :content_migration
    def initialize(cm=nil)
      @content_migration = cm
    end

    # recursively searches for keys matching our special format -
    #   $canvas_TYPE_id
    # e.g. $canvas_assignment_id

    # this indicates that they are originally ids for objects of type TYPE
    # and we'll translate them into migration ids for export and translate back into the new ids for import

    # translate_type is either :export or :import
    def translate_data(data, translate_type)
      case data
      when Array
        data.each{|item| translate_data(item, translate_type)}
      when Hash
        data.each do |key, item|
          if item.is_a?(Hash) || item.is_a?(Array)
            translate_data(item, translate_type)
          elsif obj_class = object_class_for_translation(key)
            data[key] =
              case translate_type
              when :export
                get_migration_id_from_canvas_id(obj_class, item)
              when :import
                get_canvas_id_from_migration_id(obj_class, item)
              end
          end
        end
      end
      data
    end

    # probably not a comprehensive list
    TYPES_TO_CLASSES = {
      "announcement" => Announcement,
      "assessment_question_bank" => AssessmentQuestionBank,
      "assignment" => Assignment,
      "assignment_group" => AssignmentGroup,
      "attachment" => Attachment,
      "calendar_event" => CalendarEvent,
      "context_external_tool" => ContextExternalTool,
      "context_module" => ContextModule,
      "context_module_tag" => ContentTag,
      "discussion_topic" => DiscussionTopic,
      "grading_standard" => GradingStandard,
      "learning_outcome" => LearningOutcome,
      "quiz" => Quizzes::Quiz,
      "rubric" => Rubric,
      "wiki_page" => WikiPage
    }.freeze

    CLASSES_TO_TYPES = TYPES_TO_CLASSES.invert.freeze

    ALIASED_TYPES = {
      'context_module_item' => 'context_module_tag',
      'file' => 'attachment',
      'page' => 'wiki_page'
    }

    def object_class_for_translation(key)
      if match = key.to_s.match(/^\$canvas_(\w+)_id$/)
        type = match[1]
        TYPES_TO_CLASSES[ALIASED_TYPES[type] || type]
      end
    end

    def get_migration_id_from_canvas_id(obj_class, canvas_id)
      CC::CCHelper.create_key("#{obj_class.reflection_type_name}_#{canvas_id}")
    end

    NOT_FOUND = "$OBJECT_NOT_FOUND"

    def get_canvas_id_from_migration_id(obj_class, migration_id)
      if item = content_migration.find_imported_migration_item(obj_class, migration_id)
        return item.id
      end
      # most of the time, the new canvas object have been imported with the current import
      # but it may have been imported earlier as a selective import
      # so we can search for it in the course just to be sure
      obj_type = TYPES_TO_CLASSES.detect{|k, v| v == obj_class}.first
      if item = content_migration.context.send(obj_type.pluralize).where(:migration_id => migration_id).first
        return item.id
      end
      NOT_FOUND
    end
  end
end