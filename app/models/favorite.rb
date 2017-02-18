class Favorite < ActiveRecord::Base
  belongs_to :context, polymorphic: [:course, :group]
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Course', 'Group'].freeze
  scope :by, lambda { |type| where(:context_type => type) }
end
