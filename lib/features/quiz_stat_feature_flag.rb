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

module Features
  class QuizStatFeatureFlag
    def register!
      Feature.register(definition) if should_register?
    end

    private
    def definition
      @definition ||= {
        'quiz_stats' =>
        {
          display_name: -> { I18n.t('features.new_quiz_statistics', 'New Quiz Statistics Page') },
          description: -> { I18n.t('new_quiz_statistics_desc', <<-END) },
When Draft State is allowed/on, this enables the new quiz statistics page for an account.
          END
          applies_to: 'Course',
          state: 'allowed',
          development: true,
          beta: true
        }
      }
    end

    def should_register?
      Rails.env.test? || Rails.env.development? || in_beta?
    end

    def in_beta?
      Rails.env.production? && (!ApplicationController.respond_to?(:test_cluster?) || ApplicationController.test_cluster?)
    end
  end
end

Features::QuizStatFeatureFlag.new.register!
