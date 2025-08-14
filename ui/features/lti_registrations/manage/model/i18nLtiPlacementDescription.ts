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
import type {LtiPlacement} from './LtiPlacement'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('lti_registrations')

export const LtiPlacementDescriptionTranslations: Record<LtiPlacement, string> = {
  account_navigation: I18n.t('Accessed from the administrator menu of the account.'),
  analytics_hub: I18n.t(
    'Similar to account navigation, but allows for better analytics of what tools use this type of placement.',
  ),
  assignment_edit: I18n.t(
    'This allows the tool to provide content in an iframe within the assignment edit page',
  ),
  assignment_selection: I18n.t(
    'From the edit page of an assignment this placement is available when the Submission Type is set to External Tool by clicking the Find button',
  ),
  assignment_view: I18n.t(
    'This allows the tool to provide content in an iframe on the Assignment page. It is visible to students.',
  ),
  similarity_detection: I18n.t('Provides similarity detection functionality for assignments.'),
  assignment_menu: I18n.t(
    'On the assignments page this placement is available from the dropdown on any assignment',
  ),
  assignment_index_menu: I18n.t(
    'On the assignments page this placement is available from the dropdown at the top of the page and opens a panel on the right side of the screen',
  ),
  assignment_group_menu: I18n.t(
    'On the assignments page when assignments are grouped, this placement is available in the dropdown menu from the assignment group header',
  ),
  collaboration: I18n.t(
    'This allows the tool to provide content in an iframe on the Collaborations page. It is visible to students.',
  ),
  conference_selection: I18n.t('Allows the tool to be selected when creating conferences.'),
  course_assignments_menu: I18n.t(
    'On the assignments page launching the tool from the dropdown at the top of the page opens a modal over the current page.',
  ),
  course_home_sub_navigation: I18n.t(
    'Accessed from the Home page of a course on the right side of the screen next to options to import existing content, choose home page, etc. It is visible to students.',
  ),
  course_navigation: I18n.t(
    'Accessed from the navigation bar in a course. It is visible to students.',
  ),
  course_settings_sub_navigation: I18n.t(
    'Accessed from the Settings page of a course on the right side of the screen next to options to import existing content, choose home page, etc.',
  ),
  discussion_topic_menu: I18n.t(
    'From the discussions page the tool can be launched from the dropdown next to a topic.',
  ),
  discussion_topic_index_menu: I18n.t(
    'From the discussions page the tool can be launched from the dropdown at the top of the page. It is visible to students',
  ),
  editor_button: I18n.t(
    'The tool can be launched from the Rich Content Editor in any area of Canvas. It is visible to students.',
  ),
  file_menu: I18n.t('The tool can be launched from the dropdown next to a file'),
  file_index_menu: I18n.t('The tool can be launched from the menu at the top of the Files page'),
  global_navigation: I18n.t(
    'The tool can be launched from the global navigation panel at the very left of the screen on all pages. It is visible to students.',
  ),
  homework_submission: I18n.t(
    'When an assignment uses online submission the tool can be selected and display an iframe on the page. It is visible to students',
  ),
  link_selection: I18n.t(
    'From the Modules page when the plus icon is selected from a module header and External Tool is selected, a tool can be launched.',
  ),
  migration_selection: I18n.t(
    'When importing content to a course, the tool can be selected from the content type dropdown and the Find a Course button will launch the tool',
  ),
  module_group_menu: I18n.t(
    'On the modules page this placement is available from the dropdown next to a module header and opens a panel on the right side of the screen',
  ),
  module_index_menu: I18n.t(
    'On the modules page this placement is available from the dropdown at the top of the page and opens a panel on the right side of the screen',
  ),
  module_index_menu_modal: I18n.t(
    'On the modules page this placement is available from the dropdown at the top of the page and opens a modal above the current screen',
  ),
  module_menu: I18n.t(
    'On the modules page this placement is available from the dropdown next to a module header and opens the tool in a full screen',
  ),
  module_menu_modal: I18n.t(
    'On the modules page this placement is available from the dropdown next to a module header and opens a modal above the current screen',
  ),
  post_grades: I18n.t(
    'From the gradebook when you click the actions button this provides an option to sync grades to the tool',
  ),
  quiz_menu: I18n.t(
    'On the Quizzes page within a course the tool can be launched from the dropdown next to a quiz',
  ),
  quiz_index_menu: I18n.t(
    'On the Quizzes page within a course the tool can be launched from the dropdown at the top of the screen',
  ),
  submission_type_selection: I18n.t(
    'This adds an option to pick the tool from the the Submission Type dropdown list',
  ),
  student_context_card: I18n.t(
    "From the gradebook when you click on a student's name the tool can be launched from the card",
  ),
  tool_configuration: I18n.t(
    'From the settings > Apps > Manage Apps page on the level the tool is installed at this provides a "Configure" button from the gear next to the tool',
  ),
  top_navigation: I18n.t(
    'When the feature flag is enabled and a tool using this placement is enabled, most pages in Canvas will have a tool icon available at the top of the page where the tool can be launched. This is visible to students',
  ),
  user_navigation: I18n.t(
    'The tool can be launched from the panel that opens when the user clicks account in the main navigation bar. This is visible to students.',
  ),
  wiki_page_menu: I18n.t(
    'On pages within a course the tool can be launched from the dropdown next to a Page',
  ),
  wiki_index_menu: I18n.t(
    'On Pages within a course the tool can be launched from the dropdown at the top of the screen',
  ),
  ActivityAssetProcessor: I18n.t('Processes assignment documents for enhanced functionality.'),
  ActivityAssetProcessorContribution: I18n.t(
    'Processes discussion documents for enhanced functionality.',
  ),
}

export const i18nLtiPlacementDescription = (placement: LtiPlacement): string =>
  LtiPlacementDescriptionTranslations[placement]
