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

# This service class is for reading and persisting the user's experience and role preferences.
module CanvasCareer
  class UserPreferenceManager
    EXPERIENCE_PREFERENCE_SESSION_KEY = :career_experience_preference
    ROLE_PREFERENCE_SESSION_KEY = :canvas_career_role_preference

    def initialize(session)
      @session = session
    end

    Constants::Experience.all.each do |preference|
      define_method("prefers_#{preference}?") do
        preferred_experience == preference
      end
    end

    Constants::Role.all.each do |preference|
      define_method("prefers_#{preference}?") do
        preferred_role == preference
      end
    end

    def save_preferred_experience(experience)
      return unless Constants::Experience.valid?(experience)

      @session[EXPERIENCE_PREFERENCE_SESSION_KEY] = experience
    end

    def save_preferred_role(role)
      return unless Constants::Role.valid?(role)

      @session[ROLE_PREFERENCE_SESSION_KEY] = role
    end

    private

    def preferred_experience
      return Constants::Experience::ACADEMIC if @session[EXPERIENCE_PREFERENCE_SESSION_KEY] == Constants::Experience::ACADEMIC

      Constants::Experience::CAREER
    end

    def preferred_role
      return Constants::Role::LEARNER if @session[ROLE_PREFERENCE_SESSION_KEY] == Constants::Role::LEARNER

      Constants::Role::LEARNING_PROVIDER
    end
  end
end
