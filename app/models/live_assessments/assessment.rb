#
# Copyright (C) 2014 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

module LiveAssessments
  class Assessment < ActiveRecord::Base
    attr_accessible :context, :key, :title

    belongs_to :context, polymorphic: true
    has_many :submissions, class_name: 'LiveAssessments::Submission'
    has_many :results, class_name: 'LiveAssessments::Result'

    has_many :learning_outcome_alignments, :as => :content, :class_name => 'ContentTag', :conditions => ['content_tags.tag_type = ? AND content_tags.workflow_state != ?', 'learning_outcome', 'deleted'], :include => :learning_outcome

    validates_presence_of :context_id, :context_type, :key, :title
    validates_length_of :title, maximum: maximum_string_length
    validates_length_of :key, maximum: maximum_string_length

    scope :for_context, lambda { |context| where(:context_id => context, :context_type => context.class.to_s) }

    set_policy do
      given { |user, session| self.context.grants_right?(user, session, :manage_assignments) }
      can :create and can :update

      given { |user, session| self.context.grants_right?(user, session, :view_all_grades) }
      can :read
    end

    def generate_submissions_for(users)
      # if we aren't aligned, we don't need submissions
      return unless learning_outcome_alignments.any?
      Assessment.transaction do
        users.each do |user|
          submission = submissions.where(user_id: user.id).first_or_initialize

          user_results = results.for_user(user).to_a
          next unless user_results.any?
          submission.possible = user_results.count
          submission.score = user_results.count(&:passed)
          submission.assessed_at = user_results.map(&:assessed_at).max
          submission.save!

          # it's likely that there is only one alignment per assessment, but we
          # have to deal with any number of them
          learning_outcome_alignments.each do |alignment|
            submission.create_outcome_result(alignment)
          end
        end
      end
    end
  end
end
