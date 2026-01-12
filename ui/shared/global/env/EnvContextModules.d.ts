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
 * Context modules environment data.
 *
 * From ContextModulesController::ModuleIndexHelper#load_modules
 */
export interface EnvContextModules {
  course_id: string
  CONTEXT_IS_AVAILABLE: boolean
  PAGE_TITLE: string | null
  CONTEXT_URL_ROOT: string
  ALLOW_ASSIGN_TO_DIFFERENTIATION_TAGS: boolean
  CONTENT_MIGRATIONS_EXPIRE_DAYS: number
  CAN_MANAGE_DIFFERENTIATION_TAGS: boolean
  FILES_CONTEXTS: Array<{asset_string: string}>
  MODULE_FILE_DETAILS: Record<
    string,
    {
      content_id: string
      module_id: string
    }
  >
  MODULE_FILE_PERMISSIONS: {
    usage_rights_required: boolean
    manage_files_edit: boolean
  }
  MODULES_PERMISSIONS:
    | {
        readAsAdmin: boolean
        canAdd: boolean
        canEdit: boolean
        canDelete: boolean
        canView: boolean
        canViewUnpublished: boolean
        canDirectShare: boolean
        canManageSpeedGrader: boolean
      }
    | undefined
  NEW_QUIZZES_BY_DEFAULT: boolean | undefined
  NEW_QUIZZES_ENABLED: boolean | undefined
  DEFAULT_POST_TO_SIS: boolean | undefined
  MODULE_TOOLS: Record<string, unknown>

  MASTER_COURSE_SETTINGS?: {
    IS_MASTER_COURSE: boolean
    IS_CHILD_COURSE: boolean
    MASTER_COURSE_DATA_URL: string
  }
  PUBLISH_FINAL_GRADE: boolean
  HAS_GRADING_PERIODS?: boolean
  VALID_DATE_RANGE: {
    start_at: {date: string; date_context: string}
    end_at?: {date: string; date_context: string}
  }
  POST_TO_SIS: boolean
  DEFAULT_DUE_TIME?: string
  FEATURE_MODULES_PERF?: boolean
  IS_STUDENT?: boolean
  MODULE_FEATURES?: {
    STUDENT_MODULE_SELECTION: boolean
    TEACHER_MODULE_SELECTION: boolean
    MODULES_ARE_PAGINATED?: boolean
    PAGE_SIZE?: number
    SEAMLESS_EXTERNAL_URL_REDIRECT?: boolean
  }
  MODULES_OBSERVER_INFO?: {
    isObserver: boolean
    observedStudent: {id: string; name: string} | null
    courseName: string
  }
  OBSERVER_OPTIONS?: {
    OBSERVED_USERS_LIST: Array<{id: string; name: string; avatar_url?: string | null}>
    CAN_ADD_OBSERVEE: boolean
  }
  CONTEXT_MODULES_HEADER_PROPS?: any
}
