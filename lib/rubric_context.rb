# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

module RubricContext
  def self.included(klass)
    if klass < ActiveRecord::Base
      klass.has_many :rubrics, as: :context, inverse_of: :context
      klass.has_many :rubric_associations_with_deleted, -> { preload(:rubric) }, as: :context, inverse_of: :context, class_name: "RubricAssociation"
      klass.has_many :rubric_associations, -> { where(workflow_state: "active").preload(:rubric) }, as: :context, inverse_of: :context, dependent: :destroy
      klass.include InstanceMethods
    end
  end

  module InstanceMethods
    # return the rubric but only if it's available in either the context or one
    # of the context's associated accounts.
    def available_rubric(rubric_id, opts = {})
      outcome = rubrics.where(id: rubric_id).first
      return outcome if outcome

      unless opts[:recurse] == false
        (associated_accounts.uniq - [self]).each do |context|
          rubric = context.available_rubric(rubric_id, recurse: false)
          return rubric if rubric
        end
      end

      nil
    end

    def available_rubrics
      [self, *associated_accounts].uniq.map do |context|
        [context.rubrics]
      end.flatten.uniq
    end
  end
end
