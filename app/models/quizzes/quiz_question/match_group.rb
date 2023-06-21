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
#

class Quizzes::QuizQuestion::MatchGroup
  def initialize(matches = [])
    build_matches(matches)
  end

  def add(properties)
    return if has_text?(properties[:text])

    match_id = properties[:match_id] || generate_id
    match = Match.new(properties[:text], match_id)
    matches.push(match) unless matches.include?(match)
  end

  def matches
    @matches ||= []
  end

  def to_a
    matches.map(&:to_hash)
  end

  private

  def build_matches(matches)
    matches.each { |m| add(m) }
  end

  def has_text?(text)
    matches.detect { |m| m.text == text }
  end

  def has_id?(id)
    matches.detect { |m| m.id == id }
  end

  def generate_id
    proposed_id = id_generator
    while has_id?(proposed_id)
      proposed_id = id_generator
    end
    proposed_id
  end

  def id_generator
    rand(10_000)
  end

  class Match
    include Comparable

    attr_reader :text, :id

    def initialize(text, id)
      @text, @id = text, id
    end

    def <=>(other)
      id <=> other.id
    end

    def to_hash
      { text:, match_id: id }
    end
  end
end
