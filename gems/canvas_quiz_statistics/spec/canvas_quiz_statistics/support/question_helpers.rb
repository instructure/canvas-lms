# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require 'json'

module QuestionHelpers
  FixturePath = File.join(File.dirname(__FILE__), 'fixtures')

  # Loads a question data fixture from support/fixtures/*_data.json, just pass
  # it the type of the question, e.g:
  #
  #   @question_data = question_data_fixture('multiple_choice_question')
  #   # now you have a valid question data to analyze.
  #
  #   # and you can munge and customize it:
  #   @question_data[:answers].each { |a| ... }
  #
  # @return [Hash]
  def self.fixture(question_type)
    path = File.join(FixturePath, "#{question_type}_data.json")

    unless File.exist?(path)
      raise '' <<
        "Missing question data fixture for question of type #{question_type}" <<
        ", expected file to be located at #{path}"
    end

    JSON.parse(File.read(path)).with_indifferent_access
  end
end