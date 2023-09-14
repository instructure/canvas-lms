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
export interface EnvCommon {
  ASSET_HOST: string
  active_brand_config_json_url: string
  active_brand_config: object
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
  current_user_id: string
  current_user_global_id: string
  current_user_roles: string[]
  current_user_is_student: boolean
  current_user_types: string[]
  current_user_disabled_inbox: boolean
  current_user_visited_tabs: null | unknown
  discussions_reporting: boolean
  files_domain: string
  group_information: {
    id: string
    label: string
  }[]
  DOMAIN_ROOT_ACCOUNT_ID: string
  k12: false
  help_link_name: string
  help_link_icon: string
  use_high_contrast: boolean
  auto_show_cc: boolean
  disable_celebrations: boolean
  disable_keyboard_shortcuts: boolean
  LTI_LAUNCH_FRAME_ALLOWANCES: string[]
  DEEP_LINKING_POST_MESSAGE_ORIGIN: string
  DEEP_LINKING_LOGGING: null | unknown
  comment_library_suggestions_enabled: boolean
  INCOMPLETE_REGISTRATION: boolean
  SETTINGS: {
    open_registration: boolean
    collapse_global_nav: boolean
    release_notes_badge_disabled: boolean
  }
  FULL_STORY_ENABLED: boolean
  RAILS_ENVIRONMENT: 'development' | 'CD' | 'Beta' | 'Production' | string
  IN_PACED_COURSE: boolean

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

  API_GATEWAY_URI?: string
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
    pronouns: null | unknown
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

  FEATURES: Partial<
    Record<
      SiteAdminFeatureId | RootAccountFeatureId | BrandAccountFeatureId | OtherFeatureId,
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
}

/**
 * From ApplicationController#JS_ENV_SITE_ADMIN_FEATURES
 */
export type SiteAdminFeatureId =
  | 'featured_help_links'
  | 'lti_platform_storage'
  | 'calendar_series'
  | 'account_level_blackout_dates'
  | 'account_calendar_events'
  | 'rce_ux_improvements'
  | 'render_both_to_do_lists'
  | 'course_paces_redesign'
  | 'course_paces_for_students'
  | 'module_publish_menu'
  | 'explicit_latex_typesetting'
  | 'dev_key_oidc_alert'
  | 'media_links_use_attachment_id'
  | 'permanent_page_links'
  | 'improved_no_results_messaging'
  | 'differentiated_modules'
  | 'enhanced_course_creation_account_fetching'
  | 'instui_for_import_page'

/**
 * From ApplicationController#JS_ENV_ROOT_ACCOUNT_FEATURES
 */
export type RootAccountFeatureId =
  | 'product_tours'
  | 'usage_rights_discussion_topics'
  | 'granular_permissions_manage_users'
  | 'create_course_subaccount_picker'
  | 'lti_deep_linking_module_index_menu_modal'
  | 'lti_multiple_assignment_deep_linking'
  | 'lti_overwrite_user_url_input_select_content_dialog'
  | 'buttons_and_icons_root_account'
  | 'extended_submission_state'
  | 'scheduled_page_publication'
  | 'send_usage_metrics'
  | 'rce_transform_loaded_content'
  | 'mobile_offline_mode'

/**
 * From ApplicationController#JS_ENV_BRAND_ACCOUNT_FEATURES
 */
export type BrandAccountFeatureId = 'embedded_release_notes'

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
