module DataFixup
  module FixImportedQuestionMediaComments
    def self.get_fixed_hash(bad_yaml)
      return unless bad_yaml
      placeholders = []

      # tl;dr - search for the imported media comment links and re-substitute them in the right way so the yaml still works
      # so first make a placeholder without quotes so we deserialize the yaml again
      bad_yaml.gsub!(/\<a.*?\<\/a\>/m) do |link_str|
        placeholder = "somuchsadness_#{Digest::MD5.hexdigest(link_str)}"
        placeholders << {:placeholder => placeholder, :new_value => link_str}
        placeholder
      end

      bad_yaml.gsub!(/\<a.*?\>/m) do |link_str| # for empty/unmatched tags
        placeholder = "somuchsadness_#{Digest::MD5.hexdigest(link_str)}"
        placeholders << {:placeholder => placeholder, :new_value => link_str}
        placeholder
      end

      return unless hash = (YAML.load(bad_yaml) rescue nil)

      # now make the substitutions correctly and return the serialized yaml
      Importers::LinkReplacer.new(nil).recursively_sub_placeholders!(hash, placeholders)
      hash
    end

    def self.run
      quiz_ids_to_fix = []
      still_broken_aq_ids = []
      still_broken_qq_ids = []
      still_broken_quiz_ids = []

      date_of_sadness = DateTime.parse("2015-07-17") # day before the borked link refactoring was released

      AssessmentQuestion.find_ids_in_ranges(:batch_size => 10000) do |min_id, max_id|
        AssessmentQuestion.where(id: min_id..max_id).where("migration_id IS NOT NULL").
            where("updated_at > ?", date_of_sadness).where("question_data LIKE ?", "%media_comment%").each do |aq|
          next unless (aq['question_data'] rescue nil).nil? # deserializing the attribute will fail silently in Rails 3 but not Rails 4

          unless hash = get_fixed_hash(aq.attributes_before_type_cast['question_data'])
            still_broken_aq_ids << aq.id
            next
          end

          AssessmentQuestion.where(:id => aq).update_all(:question_data => hash)
        end
      end

      Quizzes::QuizQuestion.find_ids_in_ranges(:batch_size => 10000) do |min_id, max_id|
        Quizzes::QuizQuestion.where(id: min_id..max_id).where("migration_id IS NOT NULL").
            where("updated_at > ?", date_of_sadness).where("question_data LIKE ?", "%media_comment%").each do |qq|
          next unless (qq['question_data'] rescue nil).nil?

          unless hash = get_fixed_hash(qq.attributes_before_type_cast['question_data'])
            still_broken_qq_ids << qq.id
            next
          end

          quiz_ids_to_fix << qq.quiz_id
          Quizzes::QuizQuestion.where(:id => qq).update_all(:question_data => hash)
        end
      end

      quiz_ids_to_fix.uniq.each_slice(100) do |quiz_ids|
        Quizzes::Quiz.where("quiz_data IS NOT NULL").where(:id => quiz_ids).each do |quiz|
          next unless (quiz['quiz_data'] rescue nil).nil?
          unless hash = get_fixed_hash(quiz.attributes_before_type_cast['quiz_data'])
            still_broken_quiz_ids << quiz.id
            next
          end

          Quizzes::Quiz.where(:id => quiz).update_all(:quiz_data => hash)
        end
      end

      Rails.logger.error("Problem running FixImportedQuestionMediaComments: could not fix quiz questions #{still_broken_qq_ids}") if still_broken_qq_ids.any?
      Rails.logger.error("Problem running FixImportedQuestionMediaComments: could not fix assessment questions #{still_broken_aq_ids}") if still_broken_aq_ids.any?
      Rails.logger.error("Problem running FixImportedQuestionMediaComments: could not fix quizzes #{still_broken_quiz_ids}") if still_broken_quiz_ids.any?
    end
  end
end
