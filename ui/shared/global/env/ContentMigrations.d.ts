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
 * From content_migrations_controller.rb
 */
export interface EnvContentMigrations {
  SHOW_SELECTABLE_OUTCOMES_IN_IMPORT?: boolean
  UPLOAD_LIMIT?: number
  QUESTION_BANKS?: {
    assessment_question_bank: {
      id: number
      title: string
    }
  }[]
  NEW_QUIZZES_IMPORT?: boolean
  NEW_QUIZZES_MIGRATION?: boolean
  QUIZZES_NEXT_ENABLED?: boolean
  NEW_QUIZZES_MIGRATION_DEFAULT?: boolean
  EXPORT_WARNINGS?: string[]
}
