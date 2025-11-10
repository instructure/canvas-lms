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

module NewQuizzesHelper
  def add_new_quizzes_bundle
    return unless @context.respond_to?(:root_account)
    return unless @context.root_account.feature_enabled?(:new_quizzes_native_experience)

    js_bundle :new_quizzes
    css_bundle :native_new_quizzes
    remote_env(new_quizzes: {
                 launch_url: Services::NewQuizzes.launch_url
               })
  end
end
