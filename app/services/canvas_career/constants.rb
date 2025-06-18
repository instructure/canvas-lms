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
#

module CanvasCareer
  module Constants
    module App
      CAREER_LEARNER = "career_learner"
      CAREER_LEARNING_PROVIDER = "career_learning_provider"
      ACADEMIC = "academic"
    end

    module Experience
      CAREER = "career"
      ACADEMIC = "academic"

      def self.all
        [CAREER, ACADEMIC]
      end

      def self.valid?(value)
        all.include?(value)
      end
    end

    module Role
      LEARNER = "learner"
      LEARNING_PROVIDER = "learning_provider"

      def self.all
        [LEARNER, LEARNING_PROVIDER]
      end

      def self.valid?(value)
        all.include?(value)
      end
    end
  end
end
