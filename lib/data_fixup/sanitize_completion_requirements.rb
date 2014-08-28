module DataFixup
  module SanitizeCompletionRequirements
    def self.run
      ContextModule.
        where("completion_requirements LIKE '%min\_score%' OR completion_requirements LIKE '%max\_score%'").
        find_each do |cm|
          cm.completion_requirements = cm.completion_requirements
          cm.save!
      end
    end
  end
end
