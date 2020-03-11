#
# Copyright (C) 2020 - present Instructure, Inc.
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

module NewQuizzesFeaturesHelper
  def new_quizzes_enabled?
      @context.feature_enabled?(:quizzes_next) && @context.quiz_lti_tool.present? && !new_quizzes_require_migration?
  end

  def new_quizzes_import_enabled?
      @context.root_account.feature_allowed?(:quizzes_next) && @context.root_account.feature_enabled?(:import_to_quizzes_next)
  end

  def new_quizzes_migration_enabled?
      @context.root_account.feature_allowed?(:quizzes_next) && @context.root_account.feature_enabled?(:new_quizzes_migration)
  end

  def new_quizzes_import_third_party?
      @context.root_account.feature_allowed?(:quizzes_next) && @context.root_account.feature_enabled?(:new_quizzes_third_party_imports)
  end

  def new_quizzes_migration_default
      @context.root_account.feature_enabled?(:migrate_to_new_quizzes_by_default) || new_quizzes_require_migration?
  end

  def new_quizzes_require_migration?
      @context.root_account.feature_enabled?(:require_migration_to_new_quizzes)
  end
end
