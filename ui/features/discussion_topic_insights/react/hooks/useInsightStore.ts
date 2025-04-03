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

import {create} from 'zustand'
import {InsightEntry} from './useFetchInsights'

type ActionFromState<T> = {
  [K in keyof T as `set${Capitalize<string & K>}`]: (value: T[K]) => void
}

type GlobalEnv = {
  context_type: string
  context_id: string
  discussion_topic_id: string
}

declare const ENV: GlobalEnv

const emptyInsightEntry: InsightEntry = {
  id: 0,
  entry_content: '',
  entry_url: '',
  entry_updated_at: '',
  student_id: 0,
  student_name: '',
  relevance_ai_classification: 'irrelevant',
  relevance_ai_evaluation_notes: '',
  relevance_human_reviewer: null,
  relevance_human_feedback_liked: false,
  relevance_human_feedback_disliked: false,
  relevance_human_feedback_notes: '',
}

type ReadOnlyState = Readonly<{
  context: string
  contextId: string
  discussionId: string
}>

type State = {
  modalOpen: boolean
  entry: InsightEntry
  entries: InsightEntry[] | []
  feedback: boolean | null
}

type Action = ActionFromState<State>

const useInsightStore = create<ReadOnlyState & State & Action>(set => ({
  context: ENV.context_type === 'Course' ? 'courses' : 'groups',
  contextId: ENV.context_id,
  discussionId: ENV.discussion_topic_id,
  modalOpen: false,
  entry: emptyInsightEntry,
  entries: [],
  feedback: null,
  setModalOpen: isOpen => set(() => ({modalOpen: isOpen})),
  setEntry: entry => set(() => ({entry})),
  setEntries: entries => set(() => ({entries})),
  setFeedback: feedback => set(() => ({feedback})),
}))

export default useInsightStore
