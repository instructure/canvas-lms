/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import * as z from 'zod'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('external_tools')

// TODO: this list is duplicated in ui/features/external_apps/react/components/ExternalToolPlacementList.jsx
// We should consolidate some of the lti "models" into a shared package that both features depend on

/**
 * Within an { @see LtiImsRegistration }, all Canvas-specific placements are prefixed by this string.
 * Note that the { @see LtiToolConfiguration } does *not* have this prefix, as any placements within that
 * object are known to be Canvas-specific already.
 */
export const canvasPlacementPrefix = 'https://canvas.instructure.com/lti/'

/**
 * A record where the keys are placement identifiers
 * and the values are the internationalized human-readable
 * names of those placements
 */
export const LtiPlacements = {
  /**
   * Account-level navigation
   */
  AccountNavigation: 'account_navigation',
  /**
   * Renders a frame on the assignment edit page, under
   * the native assignment options
   */
  AssignmentEdit: 'assignment_edit',
  /**
   * Appears under the "External Tool" submission type for assignments
   */
  AssignmentSelection: 'assignment_selection',
  /**
   * Renders a frame under every assignment, when viewing
   */
  AssignmentView: 'assignment_view',
  SimilarityDetection: 'similarity_detection',
  /**
   * Appears as an option in the Assignment ellipsis (for every assignment)
   * when viewing the list of course assignments
   */
  AssignmentMenu: 'assignment_menu',
  /**
   * Appears as an option in the Assignment ellipsis menu when viewing an assignment
   * Like course_assignments_menu, but launches into a tray modal
   */
  AssignmentIndexMenu: 'assignment_index_menu',
  /**
   * Appears as an option in the Assignment Group ellipsis menu when viewing the list of course assigments
   */
  AssignmentGroupMenu: 'assignment_group_menu',
  Collaboration: 'collaboration',
  ConferenceSelection: 'conference_selection',
  /**
   * Appears as an option in the Assignment ellipsis menu when viewing an assignment
   */
  CourseAssignmentsMenu: 'course_assignments_menu',
  /**
   * Appears in the right side-bar of the Course home page
   */
  CourseHomeSubNavigation: 'course_home_sub_navigation',
  /**
   * Appears in the left sidebar of a Course
   */
  CourseNavigation: 'course_navigation',
  /**
   * Appears in the right sidebar of the Course settings page
   */
  CourseSettingsSubNavigation: 'course_settings_sub_navigation',
  /**
   * Appears in the ellipsis menu on a Discussion Topic page,
   * and also in the ellipsis menu on each Discussion Topic
   * on the Discussion Topic Index page
   */
  DiscussionTopicMenu: 'discussion_topic_menu',
  /**
   * Appears in the top-level ellipsis menu on the Discussion Topic Index page
   */
  DiscussionTopicIndexMenu: 'discussion_topic_index_menu',
  /**
   * Appears as an option in the RCE toolbar
   */
  EditorButton: 'editor_button',
  FileMenu: 'file_menu',
  FileIndexMenu: 'file_index_menu',
  /**
   * Appears in the global left sidebar
   */
  GlobalNavigation: 'global_navigation',
  /**
   * Appears on the submission page for an assigment.
   * Users can use it to submit an assignment.
   */
  HomeworkSubmission: 'homework_submission',
  LinkSelection: 'link_selection',
  MigrationSelection: 'migration_selection',
  ModuleGroupMenu: 'module_group_menu',
  ModuleIndexMenu: 'module_index_menu',
  ModuleIndexMenuModal: 'module_index_menu_modal',
  ModuleMenu: 'module_menu',
  ModuleMenuModal: 'module_menu_modal',
  PostGrades: 'post_grades',
  QuizMenu: 'quiz_menu',
  QuizIndexMenu: 'quiz_index_menu',
  SubmissionTypeSelection: 'submission_type_selection',
  StudentContextCard: 'student_context_card',
  ToolConfiguration: 'tool_configuration',
  TopNavigation: 'top_navigation',
  UserNavigation: 'user_navigation',
  WikiPageMenu: 'wiki_page_menu',
  WikiIndexMenu: 'wiki_index_menu',
  DefaultPlacements: 'default_placements',
  ContentArea: 'ContentArea',
  RichTextEditor: 'RichTextEditor',
} as const

export const AllLtiPlacements = [
  LtiPlacements.AccountNavigation,
  LtiPlacements.AssignmentEdit,
  LtiPlacements.AssignmentSelection,
  LtiPlacements.AssignmentView,
  LtiPlacements.SimilarityDetection,
  LtiPlacements.AssignmentMenu,
  LtiPlacements.AssignmentIndexMenu,
  LtiPlacements.AssignmentGroupMenu,
  LtiPlacements.Collaboration,
  LtiPlacements.ConferenceSelection,
  LtiPlacements.CourseAssignmentsMenu,
  LtiPlacements.CourseHomeSubNavigation,
  LtiPlacements.CourseNavigation,
  LtiPlacements.CourseSettingsSubNavigation,
  LtiPlacements.DiscussionTopicMenu,
  LtiPlacements.DiscussionTopicIndexMenu,
  LtiPlacements.EditorButton,
  LtiPlacements.FileMenu,
  LtiPlacements.FileIndexMenu,
  LtiPlacements.GlobalNavigation,
  LtiPlacements.HomeworkSubmission,
  LtiPlacements.LinkSelection,
  LtiPlacements.MigrationSelection,
  LtiPlacements.ModuleGroupMenu,
  LtiPlacements.ModuleIndexMenu,
  LtiPlacements.ModuleIndexMenuModal,
  LtiPlacements.ModuleMenu,
  LtiPlacements.ModuleMenuModal,
  LtiPlacements.PostGrades,
  LtiPlacements.QuizMenu,
  LtiPlacements.QuizIndexMenu,
  LtiPlacements.SubmissionTypeSelection,
  LtiPlacements.StudentContextCard,
  LtiPlacements.ToolConfiguration,
  LtiPlacements.TopNavigation,
  LtiPlacements.UserNavigation,
  LtiPlacements.WikiPageMenu,
  LtiPlacements.WikiIndexMenu,
  LtiPlacements.DefaultPlacements,
  LtiPlacements.ContentArea,
  LtiPlacements.RichTextEditor,
] as const

export const ZLtiPlacement = z.enum(AllLtiPlacements)
export type LtiPlacement = z.infer<typeof ZLtiPlacement>

export const LtiPlacementsWithIcons = [
  LtiPlacements.GlobalNavigation,
  LtiPlacements.CourseHomeSubNavigation,
  LtiPlacements.AssignmentIndexMenu,
  LtiPlacements.CourseSettingsSubNavigation,
  LtiPlacements.DiscussionTopicMenu,
  LtiPlacements.DiscussionTopicIndexMenu,
  LtiPlacements.EditorButton,
  LtiPlacements.FileIndexMenu,
] as const

export type LtiPlacementWithIcon = (typeof LtiPlacementsWithIcons)[number]

const LtiPlacementTranslations: Record<LtiPlacement, string> = {
  account_navigation: I18n.t('Account Navigation'),
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
  default_placements: I18n.t('Assignment and Link Selection'),
  ContentArea: I18n.t('Content Area'),
  RichTextEditor: I18n.t('Rich Text Editor'),
}

export const i18nLtiPlacement = (placement: LtiPlacement): string =>
  LtiPlacementTranslations[placement]
