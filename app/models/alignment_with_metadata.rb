# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

# Value object that wraps a ContentTag with alignment type metadata
#
# This class provides a clean way to associate alignment type information
# (direct, indirect, external) with alignments without modifying the
# underlying ActiveRecord objects.
class AlignmentWithMetadata
  module AlignmentTypes
    DIRECT = "direct"
    INDIRECT = "indirect"
    EXTERNAL = "external"

    PREFIX_MAP = {
      DIRECT => "D",
      INDIRECT => "I",
      EXTERNAL => "E"
    }.freeze

    ALL = [DIRECT, INDIRECT, EXTERNAL].freeze
  end

  attr_reader :content_tag, :alignment_type

  delegate :id,
           :content,
           :content_id,
           :content_type,
           :context,
           :learning_outcome_id,
           to: :content_tag

  def initialize(content_tag:, alignment_type:)
    unless AlignmentTypes::ALL.include?(alignment_type)
      raise ArgumentError, "Invalid alignment_type: #{alignment_type}. Must be one of: #{AlignmentTypes::ALL.join(", ")}"
    end

    @content_tag = content_tag
    @alignment_type = alignment_type
  end

  # Generates a prefixed alignment ID matching GraphQL OutcomeAlignmentLoader format
  #
  # Returns a string in the format: "D_<id>", "I_<id>", or "E_<id>"
  # where the prefix indicates:
  #   D = Direct alignment
  #   I = Indirect alignment (via question bank)
  #   E = External alignment (via Outcome Service)
  def prefixed_id
    prefix = AlignmentTypes::PREFIX_MAP[alignment_type]
    base_id = id || content_id
    "#{prefix}_#{base_id}"
  end

  # Creates an AlignmentWithMetadata for an assignment without a persisted ContentTag
  #
  # Used for indirect and external alignments that don't have real ContentTag records
  def self.for_assignment(assignment:, alignment_type:, outcome_id:, context:)
    tag = ContentTag.new(
      content: assignment,
      content_id: assignment.id,
      content_type: "Assignment",
      context:,
      learning_outcome_id: outcome_id
    )
    new(content_tag: tag, alignment_type:)
  end

  def ==(other)
    other.is_a?(AlignmentWithMetadata) &&
      content_id == other.content_id &&
      content_type == other.content_type &&
      context.id == other.context.id &&
      context.name == other.context.name &&
      alignment_type == other.alignment_type &&
      learning_outcome_id == other.learning_outcome_id
  end

  def hash
    [content_id, content_type, context.id, context.name, alignment_type, learning_outcome_id].hash
  end

  alias_method :eql?, :==
end
