/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

export interface QuizConfig {
  ajax?: (options: JQuery.AjaxSettings) => JQuery.jqXHR
  quizUrl?: string
  submissionUrl?: string
  eventsUrl?: string
  questionsUrl?: string
  attempt?: number
  loadOnStartup?: boolean
  allowMatrixView?: boolean
  useHashRouter?: boolean
}

export interface QuizEvent {
  id: string | number
  event_type: string
  event_data: Record<string, unknown>
  created_at: string
}

export interface Question {
  id: string | number
  question_type: string
  question_text: string
  position: number
  answers?: QuestionAnswer[]
  matches?: QuestionMatch[]
}

export interface QuestionAnswer {
  id: string | number
  text?: string
  html?: string
  [key: string]: unknown
}

export interface QuestionMatch {
  match_id: string | number
  text: string
  [key: string]: unknown
}

export interface SubmissionData {
  id: string | number
  started_at: string
  attempt: number
  startedAt?: string
}

export interface QueryParams {
  attempt?: string | number
  question?: string | number
}
