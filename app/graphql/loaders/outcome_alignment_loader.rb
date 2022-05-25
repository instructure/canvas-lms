# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

class Loaders::OutcomeAlignmentLoader < GraphQL::Batch::Loader
  include OutcomesFeaturesHelper

  VALID_CONTEXT_TYPES = ["Course", "Account"].freeze

  def initialize(context_id, context_type)
    super()
    @context_id = context_id
    @context_type = context_type
    @context = VALID_CONTEXT_TYPES.include?(context_type) ? context_type.constantize.active.find_by(id: context_id) : nil
  end

  def perform(outcomes)
    if @context.nil? || !outcome_alignment_summary_enabled?(@context)
      fulfill_nil(outcomes)
      return
    end

    outcomes.each do |outcome|
      alignments = outcome.alignments.active.where(context: @context).order("title ASC").to_a
      alignments.each do |alignment|
        alignment.url = [
          "/#{alignment.context_type.downcase.pluralize}",
          alignment.context_id,
          "outcomes",
          alignment.learning_outcome_id,
          "alignments",
          alignment.id
        ].join("/")
      end
      fulfill(outcome, alignments)
    end
  end

  def fulfill_nil(outcomes)
    outcomes.each do |outcome|
      fulfill(outcome, nil) unless fulfilled?(outcome)
    end
  end
end
