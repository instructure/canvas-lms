module AcademicBenchmarks
  module Standards
    class Standard
      def build_outcomes(ratings={}, parent=nil)
        hash = {
          migration_id: guid,
          vendor_guid: guid,
          low_grade: low_grade,
          high_grade: high_grade,
          is_global_standard: true,
          description: description
        }
        if leaf?
          # create outcome
          hash[:type] = 'learning_outcome'
          hash[:title] = build_num_title
          set_default_ratings(hash, ratings)
        else
          # create outcome group
          hash[:type] = 'learning_outcome_group'
          hash[:title] = build_title
          hash[:outcomes] = children.map {|c| c.build_outcomes(ratings)}
        end

        course_cache = parent.try(:course_cache)
        subject_cache = parent.try(:subject_cache)
        document_cache = parent.try(:document_cache)
        if !course_cache.nil? && !subject_cache.nil? && !course.guid.nil? && !subject_doc.guid.nil?
          # Add subject and and course as intermediate groups between the
          # calling authority/document and this standard
          #
          # authority/document
          # |-> subject
          #     |-> course
          #         |-> standard
          #
          new_course = !course_cache.key?(course.guid)
          new_subject = !subject_cache.key?(subject_doc.guid)
          course_hash = course_cache[course.guid] || course_cache[course.guid] = group_hash(course)
          subject_hash = subject_cache[subject_doc.guid] || subject_cache[subject_doc.guid] = group_hash(subject_doc)
          course_hash[:outcomes] << hash
          subject_hash[:outcomes] << course_hash if new_subject || new_course
          if !document_cache.nil? && !document.try(:guid).nil?
            # Add document as intermediate group between the calling authority
            # and this subject
            #
            # authority
            # |-> document
            #     |-> subject
            #
            new_document = !document_cache.key?(document.guid)
            document_hash = document_cache[document.guid] || document_cache[document.guid] = group_hash(document)
            document_hash[:outcomes] << subject_hash if new_document || new_subject
            return new_document ? document_hash : nil
          end
          return new_subject ? subject_hash : nil
        end

        hash
      end

      # standards don't have titles so they are built from parent standards/groups
      # it is generated like this:
      # if I have a number, use it and all parent nums on standards
      # if I don't have a number, use my description (potentially truncated at 50)
      def build_num_title
        if parent && parent.is_a?(Standard) && parent.number.present?
          base = parent.build_num_title
          if base && number
            number.include?(base) ? number : [base, number].join(".")
          else
            base ? base : number
          end
        elsif number.present?
          number
        else
          cropped_description
        end
      end

      def build_title
        if number
          [build_num_title, cropped_description].join(" - ")
        else
          cropped_description
        end
      end

      def cropped_description
        Standard.crop(description)
      end

      def set_default_ratings(hash, overrides={})
        hash[:ratings] = [{:description => "Exceeds Expectations", :points => 5},
                          {:description => "Meets Expectations", :points => 3},
                          {:description => "Does Not Meet Expectations", :points => 0}]
        hash[:mastery_points] = 3
        hash[:points_possible] = 5
        hash.merge!(overrides)
      end

      def low_grade
        g = grade
        g ? g.low : nil
      end

      def high_grade
        g = grade
        g ? g.high : nil
      end

      def self.crop(text)
        # get the first 50 chars of description in a utf-8 friendly way
        d = text
        d && d[/.{0,50}/u]
      end

      private

      def group_hash(itm)
        {
          type: 'learning_outcome_group',
          title: Standard.crop(itm.try(:description) || itm.try(:title)),
          migration_id: itm.guid,
          vendor_guid: itm.guid,
          is_global_standard: true,
          outcomes: []
        }
      end
    end
  end
end
