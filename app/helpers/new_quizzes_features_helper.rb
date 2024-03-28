# frozen_string_literal: true

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
  def new_quizzes_import_enabled?
    @context.instance_of?(Course) && @context.feature_enabled?(:quizzes_next)
  end

  def new_quizzes_migration_enabled?
    @context.root_account.feature_allowed?(:quizzes_next) && @context.root_account.feature_enabled?(:new_quizzes_migration)
  end

  def new_quizzes_migration_default
    @context.root_account.feature_enabled?(:migrate_to_new_quizzes_by_default) || new_quizzes_require_migration?
  end

  def new_quizzes_navigation_placements_enabled?(context = @context)
    Account.site_admin.feature_enabled?(:new_quizzes_account_course_level_item_banks) && context.feature_enabled?(:quizzes_next)
  end

  def new_quizzes_by_default?
    @context.feature_enabled?(:quizzes_next) && @context.feature_enabled?(:new_quizzes_by_default)
  end

  module_function

  def new_quizzes_enabled?(context = @context)
    context.feature_enabled?(:quizzes_next) && context.quiz_lti_tool.present?
  end

  def new_quizzes_require_migration?(context = @context)
    context.root_account.feature_enabled?(:require_migration_to_new_quizzes)
  end

  def new_quizzes_bank_migrations_enabled?(context = @context)
    context.feature_enabled?(:quizzes_next) && context.root_account.feature_enabled?(:new_quizzes_migration) && Account.site_admin.feature_enabled?(:new_quizzes_bank_migrations)
  end

  def disable_content_rewriting?(context = @context)
    context.feature_enabled?(:quizzes_next) && Account.site_admin.feature_enabled?(:new_quizzes_migrate_without_content_rewrite)
  end

  def new_quizzes_common_cartridge_enabled?(context = @context)
    context.feature_enabled?(:quizzes_next) && Account.site_admin.feature_enabled?(:new_quizzes_common_cartridge)
  end

  def common_cartridge_qti_new_quizzes_import_enabled?(context = @context)
    context.feature_enabled?(:quizzes_next) && context.root_account.feature_enabled?(:new_quizzes_migration) && Account.site_admin.feature_enabled?(:common_cartridge_qti_new_quizzes_import)
  end
end
