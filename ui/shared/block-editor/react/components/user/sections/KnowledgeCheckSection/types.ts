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

export type QuestionProps = {
  id: string
  entry_editable: boolean
  entry_type: string
  points_possible: number
  position: number
  properties: object
  status: string
  stimulus_quiz_entry_id: string
  entry: {
    id: string
    title: string | null
    answer_feedback: object
    calculator_type: string
    feedback: {
      neutral: string
      correct: string
      incorrect: string
    }
    interaction_data: {
      true_choice: string
      false_choice: string
    }
    interaction_type_slug: string
    item_body: string | null
    properties: object
    scoring_algorithm: string
    scoring_data: {
      value: boolean
    }
  }
}

export type KnowledgeCheckSectionProps = {
  id?: string
  entry: {
    answer_feedback: any
    calculator_type: string
    feedback: {
      correct: string
      incorrect: string
      neutral: string
    }
    interaction_data: any
    interaction_type_slug: string
    item_body: string | null
    properties: any
    scoring_algorithm: string
    scoring_data: any
    title: string | null
  }
}
