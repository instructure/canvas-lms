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

/**
 * Common ENV variables, from ApplicationController#js_env
 *
 * Optional variables are best-effort marked as such.
 */

type Setting =
  | 'manual_mark_as_read'
  | 'release_notes_badge_disabled'
  | 'collapse_global_nav'
  | 'collapse_course_nav'
  | 'hide_dashcard_color_overlays'
  | 'comment_library_suggestions_enabled'
  | 'elementary_dashboard_disabled'
  | 'suppress_assignments'

type Role = {
  addable_by_user: boolean
  base_role_name: string
  deleteable_by_user: boolean
  id: string
  label: string
  name: string
  plural_label: string
}

type ToolPlacement = 'top_navigation'

export type Tool = {
  id: string
  title: string
  base_url: string
  icon_url: string
  pinned?: boolean
  placement?: ToolPlacement
}

export type GroupOutcome = {
  id: string
  title: string
  vendor_guid: string
  url: string
  subgroups_url: string
  outcomes_url: string
  can_edit: boolean
  import_url: string
  context_id: string
  context_type: string
  description: string
}

export interface BlueprintCourse {
  id: number | string
  name: string
  enrollment_term_id: number | string
}

export interface SubAccount {
  id: number | string
  name: string
}

export interface Term {
  id: number | string
  name: string
}

export interface BlueprintCoursesData {
  isMasterCourse: boolean
  isChildCourse: boolean
  accountId: number | string
  masterCourse: BlueprintCourse
  course: BlueprintCourse
  subAccounts?: SubAccount[]
  terms?: Term[]
  canManageCourse?: boolean
  canAutoPublishCourses?: boolean
  itemNotificationFeatureEnabled?: boolean
}

export interface EnvCommon {
  ASSET_HOST: string
  DOMAIN_ROOT_ACCOUNT_SFID: string
  active_brand_config_json_url: string
  active_brand_config: {
    variables: Record<string, string>
  }
  badge_counts?: {
    discussions: number
    assignments: number
    conversations: number
    grades: number
    alerts: number
    announcements: number
    submissions: number
    total: number
  }
  confetti_branding_enabled: boolean
  url_to_what_gets_loaded_inside_the_tinymce_editor_css: string
  url_for_high_contrast_tinymce_editor_css: string
  csp?: string
  current_user_id: string | null
  current_user_global_id: string
  current_user_usage_metrics_id: string
  COURSE_ROLES: Role[]
  COURSE_USERS_PATH?: string
  current_user_roles: string[]
  current_user_is_student: boolean
  current_user_is_admin: boolean
  current_user_types: string[]
  current_user_disabled_inbox: boolean
  current_user_visited_tabs: null | string[]
  discussions_reporting: boolean
  files_domain: string
  group_information: {
    id: string
    label: string
  }[]
  ACCOUNT_ID: string
  DOMAIN_ROOT_ACCOUNT_ID: string
  DOMAIN_ROOT_ACCOUNT_UUID: string
  ROOT_ACCOUNT_ID: string
  PENDO_APP_ID: string
  ROOT_OUTCOME_GROUP: GroupOutcome
  k12: false
  help_link_name: string
  help_link_icon: string
  use_high_contrast: boolean
  use_dyslexic_font?: boolean
  auto_show_cc: boolean
  disable_celebrations: boolean
  disable_keyboard_shortcuts: boolean
  LTI_LAUNCH_FRAME_ALLOWANCES: string[]
  LTI_TOOL_SCOPES?: {[key: string]: string[]}
  DEEP_LINKING_POST_MESSAGE_ORIGIN: string
  HORIZON_DOMAIN: string
  comment_library_suggestions_enabled: boolean
  INCOMPLETE_REGISTRATION: boolean
  SETTINGS: Record<Setting, boolean>
  RAILS_ENVIRONMENT: 'development' | 'CD' | 'Beta' | 'Production' | string
  IN_PACED_COURSE: boolean
  CONDITIONAL_RELEASE_SERVICE_ENABLED?: boolean
  PARSE_LINK_HEADER_THROW_ON_MAXLEN_EXCEEDED?: boolean
  PREFERENCES?: {
    hide_dashcard_color_overlays: boolean
    custom_colors: unknown
  }

  SENTRY_FRONTEND?: {
    /**
     * Example: "https://332kjh4j3k2hkj4kh@relay-pdx.sentry.insops.net/123",
     */
    dsn: string
    /**
     * Example: "instructure",
     */
    org_slug: string
    /**
     * Example: "https://sentry.insops.net",
     */
    base_url: string
    /**
     * Example: "/courses/{course_id}/pages/{id}/edit",
     */
    normalized_route: string
    /**
     * Example: "0.0005",
     */
    errors_sample_rate: string
    /**
     * Example: "0.0005",
     */
    traces_sample_rate: string
    /**
     * Example: "instructure-uploads.*amazonaws.com",
     */
    url_deny_pattern: string
    /**
     * Example: "canvas-lms@20230412.123"
     */
    revision: string
  }

  DATA_COLLECTION_ENDPOINT?: string

  /**
   * In milliseconds
   */
  flashAlertTimeout?: number
  KILL_JOY: boolean
  DIRECT_SHARE_ENABLED: boolean
  CAN_VIEW_CONTENT_SHARES: boolean
  current_user: {
    id: string
    anonymous_id: string
    display_name: string
    avatar_image_url: string
    html_url: string
    pronouns: null | string
    fake_student: boolean
    avatar_is_fallback: boolean
    email?: string
  }
  page_view_update_url: string
  IS_LARGE_ROSTER: boolean
  context_asset_string: string
  ping_url: string
  TIMEZONE: string
  CONTEXT_TIMEZONE?: string

  LOCALE: string
  LOCALES: string[]
  BIGEASY_LOCALE: string
  FULLCALENDAR_LOCALE: string
  MOMENT_LOCALE: string

  lolcalize: boolean
  rce_auto_save_max_age_ms: number
  K5_USER: boolean
  USE_CLASSIC_FONT: string
  K5_HOMEROOM_COURSE: string
  K5_SUBJECT_COURSE: string
  LOCALE_TRANSLATION_FILE: string
  DEFAULT_DUE_TIME?: string
  TIMEZONES: Array<{name: string; name_with_hour_offset: string}>
  DEFAULT_TIMEZONE_NAME: string
  captcha_site_key: string

  FEATURES: Partial<
    Record<
      | SiteAdminFeatureId
      | RootAccountFeatureId
      | RootAccountServiceId
      | BrandAccountFeatureId
      | OtherFeatureId,
      boolean
    >
  >

  /**
   * Referenced by ui/shared/rails-flash-notifications/jquery/index.ts but doesn't appear to be defined anywhere.
   * Perhaps some rails magic?
   */
  notices?: Array<{
    content?: {
      timeout?: number
    }
    type?: string
    classes?: string
  }>
  breadcrumbs?: {name: string; url: string}[]
  enhanced_rubrics_enabled?: boolean
  enhanced_rubrics_copy_to?: boolean
  rubric_imports_exports?: boolean

  /**
   * Used by ui/features/top_navigation_tools/react/TopNavigationTools.tsx
   * and ui/shared/trays/react/ContentTypeExternalToolDrawer.tsx
   */
  top_navigation_tools: Tool[]

  BLUEPRINT_COURSES_DATA: BlueprintCoursesData | undefined
  AI_FEEDBACK_LINK?: string
}

/**
 * From ApplicationController#JS_ENV_SITE_ADMIN_FEATURES
 */
export type SiteAdminFeatureId =
  | 'account_calendar_events'
  | 'account_level_blackout_dates'
  | 'enhanced_course_creation_account_fetching'
  | 'explicit_latex_typesetting'
  | 'instui_for_import_page'
  | 'instui_nav'
  | 'media_links_use_attachment_id'
  | 'multiselect_gradebook_filters'
  | 'permanent_page_links'
  | 'render_both_to_do_lists'
  | 'instui_header'
  | 'lti_registrations_discover_page'
  | 'courses_popout_sisid'
  | 'dashboard_graphql_integration'
  | 'speedgrader_studio_media_capture'
  | 'validate_call_to_action'
  | 'new_quizzes_navigation_updates'
  | 'create_wiki_page_mastery_path_overrides'
  | 'create_external_apps_side_tray_overrides'
  | 'files_a11y_rewrite_toggle'
  | 'files_a11y_rewrite'
/**
 * From ApplicationController#JS_ENV_ROOT_ACCOUNT_FEATURES
 */
export type RootAccountFeatureId =
  | 'buttons_and_icons_root_account'
  | 'create_course_subaccount_picker'
  | 'extended_submission_state'
  | 'instui_nav'
  | 'lti_deep_linking_module_index_menu_modal'
  | 'lti_registrations_next'
  | 'lti_registrations_page'
  | 'lti_registrations_usage_data'
  | 'mobile_offline_mode'
  | 'product_tours'
  | 'rce_transform_loaded_content'
  | 'scheduled_page_publication'
  | 'send_usage_metrics'
  | 'account_level_mastery_scales'
  | 'non_scoring_rubrics'
  | 'rubric_criterion_range'
  | 'rce_lite_enabled_speedgrader_comments'
  | 'login_registration_ui_identity'
  | 'course_paces_skip_selected_days'
  | 'course_pace_download_document'
  | 'course_pace_draft_state'
  | 'course_pace_time_selection'
  | 'course_pace_pacing_status_labels'
  | 'course_pace_pacing_with_mastery_paths'
  | 'modules_requirements_allow_percentage'
  | 'lti_asset_processor'
  | 'course_pace_weighted_assignments'
  | 'course_pace_allow_bulk_pace_assign'
  | 'disable_iframe_sandbox_file_show'
  | 'ams_service'
  | 'lti_apps_page_ai_translation'
  | 'open_tools_in_new_tab'

/**
 * From ApplicationController#JS_ENV_ROOT_ACCOUNT_SERVICES
 */
export type RootAccountServiceId = 'account_survey_notifications'

/**
 * From ApplicationController#JS_ENV_BRAND_ACCOUNT_FEATURES
 */
export type BrandAccountFeatureId =
  | 'embedded_release_notes'
  | 'consolidated_media_player'
  | 'discussion_checkpoints'

/**
 * Feature id exported in ApplicationController that aren't mentioned in
 * JS_ENV_SITE_ADMIN_FEATURES or JS_ENV_ROOT_ACCOUNT_FEATURES or JS_ENV_BRAND_ACCOUNT_FEATURES
 */
export type OtherFeatureId = 'canvas_k6_theme' | 'new_math_equation_handling'

/**
 * From ApplicationHelper#set_tutorial_js_env
 */
export interface EnvCommonNewUserTutorial {
  NEW_USER_TUTORIALS: {is_enabled: boolean}
}
