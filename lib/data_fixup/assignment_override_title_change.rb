module DataFixup
  module AssignmentOverrideTitleChange
    def self.run
      AssignmentOverride.where(set_type: 'ADHOC').find_each do |o|
        o.title = nil
        o.save!
      end
    end
  end
end