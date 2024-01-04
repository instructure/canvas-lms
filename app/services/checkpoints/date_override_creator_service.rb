# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class Checkpoints::DateOverrideCreatorService < ApplicationService
  class SetTypeRequiredError < StandardError; end
  class SetTypeNotSupportedError < StandardError; end

  def initialize(checkpoint:, overrides:)
    super()
    @checkpoint = checkpoint
    @overrides = overrides
  end

  def call
    @overrides.each do |override|
      set_type = override.fetch(:set_type) { raise SetTypeRequiredError, "set_type is required, but was not provided" }
      service = services.fetch(set_type) { |key| raise SetTypeNotSupportedError, "set_type of '#{key}' not supported. Supported types: #{services.keys}" }
      service.call(checkpoint: @checkpoint, override:)
    end
  end

  private

  def services
    {
      "CourseSection" => Checkpoints::SectionOverrideCreatorService,
      "Group" => Checkpoints::GroupOverrideCreatorService,
      "ADHOC" => Checkpoints::AdhocOverrideCreatorService,
    }
  end
end
