module DataFixup
  module FixNanGroupWeights
    def self.run
      while AssignmentGroup.where(group_weight: Float::NAN).limit(1000).update_all(group_weight: 0) > 0; end
    end
  end
end
