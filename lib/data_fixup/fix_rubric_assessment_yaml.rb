module DataFixup
  module FixRubricAssessmentYAML
    def self.run
      # TODO: can remove when Syckness is removed
      RubricAssessment.find_ids_in_ranges(:batch_size => 10000) do |min_id, max_id|
        RubricAssessment.where(:id => min_id..max_id).
          where("data LIKE ? AND data LIKE ?", "%#{Syckness::TAG}", "%comments_html:%").
          pluck("id", "data as d1").each do |id, yaml|

          new_yaml = yaml.gsub(/\:comments_html\:\s*([^!\s])/) do
            ":comments_html: !str #{$1}"
          end
          if new_yaml != yaml
            RubricAssessment.where(:id => id).update_all(:data => YAML.load(new_yaml))
          end
        end
      end
    end
  end
end