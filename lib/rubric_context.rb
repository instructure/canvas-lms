module RubricContext
  def self.included(klass)
    if klass < ActiveRecord::Base
      klass.has_many :rubrics, :as => :context, :inverse_of => :context
      klass.has_many :rubric_associations, -> { preload(:rubric) }, as: :context, inverse_of: :context, dependent: :destroy
      klass.send :include, InstanceMethods
    end
  end
  module InstanceMethods
    # return the rubric but only if it's available in either the context or one
    # of the context's associated accounts.
    def available_rubric(rubric_id, opts={})
      outcome = rubrics.where(id: rubric_id).first
      return outcome if outcome

      unless opts[:recurse] == false
        (associated_accounts.uniq - [self]).each do |context|
          rubric = context.available_rubric(rubric_id, :recurse => false)
          return rubric if rubric
        end
      end

      return nil
    end

    def available_rubrics
      [self, *associated_accounts].uniq.map do |context|
        [context.rubrics]
      end.flatten.uniq
    end
  end
end
