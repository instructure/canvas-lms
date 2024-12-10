/*
 * Copyright (C) 2024 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {type LtiPlacement} from './LtiPlacement'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('external_tools')

export const LtiPlacementTranslations: Record<LtiPlacement, string> = {
  account_navigation: I18n.t('Account Navigation'),
  analytics_hub: I18n.t('Analytics Hub'),
  assignment_edit: I18n.t('Assignment Edit'),
  assignment_selection: I18n.t('Assignment Selection'),
  assignment_view: I18n.t('Assignment View'),
  similarity_detection: I18n.t('Similarity Detection'),
  assignment_menu: I18n.t('Assignment Menu'),
  assignment_index_menu: I18n.t('Assignments Index Menu'),
  assignment_group_menu: I18n.t('Assignments Group Menu'),
  collaboration: I18n.t('Collaboration'),
  conference_selection: I18n.t('Conference Selection'),
  course_assignments_menu: I18n.t('Course Assignments Menu'),
  course_home_sub_navigation: I18n.t('Course Home Sub Navigation'),
  course_navigation: I18n.t('Course Navigation'),
  course_settings_sub_navigation: I18n.t('Course Settings Sub Navigation'),
  discussion_topic_menu: I18n.t('Discussion Topic Menu'),
  discussion_topic_index_menu: I18n.t('Discussions Index Menu'),
  editor_button: I18n.t('Editor Button'),
  file_menu: I18n.t('File Menu'),
  file_index_menu: I18n.t('Files Index Menu'),
  global_navigation: I18n.t('Global Navigation'),
  homework_submission: I18n.t('Homework Submission'),
  link_selection: I18n.t('Link Selection'),
  migration_selection: I18n.t('Migration Selection'),
  module_group_menu: I18n.t('Modules Group Menu'),
  module_index_menu: I18n.t('Modules Index Menu (Tray)'),
  module_index_menu_modal: I18n.t('Modules Index Menu (Modal)'),
  module_menu: I18n.t('Module Menu'),
  module_menu_modal: I18n.t('Module Menu (Modal)'),
  post_grades: I18n.t('Sync Grades'),
  quiz_menu: I18n.t('Quiz Menu'),
  quiz_index_menu: I18n.t('Quizzes Index Menu'),
  submission_type_selection: I18n.t('Submission Type Selection'),
  student_context_card: I18n.t('Student Context Card'),
  tool_configuration: I18n.t('Tool Configuration'),
  top_navigation: I18n.t('Top Navigation'),
  user_navigation: I18n.t('User Navigation'),
  wiki_page_menu: I18n.t('Page Menu'),
  wiki_index_menu: I18n.t('Pages Index Menu'),
  ActivityAssetProcessor: I18n.t('Activity Asset Processor'),
}
export const i18nLtiPlacement = (placement: LtiPlacement): string =>
  LtiPlacementTranslations[placement]
