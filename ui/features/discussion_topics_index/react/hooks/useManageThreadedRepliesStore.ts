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
import {devtools} from 'zustand/middleware'

type State = {
  showAlert: boolean
  selectedDiscussions: string[]
  discussionStates: Record<string, 'not_set' | 'threaded' | 'not_threaded'>
  loading: boolean
  isValid: boolean
  isDirty: boolean
  errorCount: number
}

type Actions = {
  initialize: (discussions: string[]) => void
  setDiscussionState: (discussionId: string, state: 'threaded' | 'not_threaded') => void
  toggleSelectedDiscussion: (discussionId: string) => void
  toggleSelectedDiscussions: (discussionIds: string[]) => void
  setShowAlert: (showAlert: boolean) => void
  setModalClose: (closeAlert?: boolean) => void
  validate: () => boolean
}

export const useManageThreadedRepliesStore = create<State & Actions>()(
  devtools(
    set => ({
      selectedDiscussions: [],
      discussionStates: {},
      isValid: false,
      showAlert: true, // defautl to true the component itself hides if there is no discussion, but we want to hide it later
      loading: false,
      isDirty: false,
      errorCount: 0,

      initialize: discussions =>
        set(() => ({
          isValid: false,
          discussionStates: discussions.reduce(
            (acc, discussionId) => {
              acc[discussionId] = 'not_set'
              return acc
            },
            {} as Record<string, 'not_set' | 'threaded' | 'not_threaded'>,
          ),
        })),

      setDiscussionState: (discussionId, state) => {
        if (!['threaded', 'not_threaded'].includes(state)) {
          return
        }

        return set(prevState => {
          let isValid = prevState.isValid

          const discussionStates = {
            ...prevState.discussionStates,
            [discussionId]: state,
          }

          if (!isValid && Object.values(discussionStates).every(s => s !== 'not_set')) {
            isValid = true
          }

          const errorCount = !prevState.isDirty
            ? 0
            : Object.values(discussionStates).filter(s => s === 'not_set').length

          return {
            isValid,
            discussionStates,
            errorCount,
          }
        })
      },

      toggleSelectedDiscussion: discussionId =>
        set(prevState => {
          const isSelected = prevState.selectedDiscussions.includes(discussionId)
          return {
            selectedDiscussions: isSelected
              ? prevState.selectedDiscussions.filter(id => id !== discussionId)
              : [...prevState.selectedDiscussions, discussionId],
          }
        }),

      toggleSelectedDiscussions: discussionIds =>
        set(() => ({
          selectedDiscussions: discussionIds,
        })),

      setShowAlert: showAlert => set({showAlert}),

      setModalClose: (closeAlert = false) =>
        set({
          loading: false,
          isValid: false,
          isDirty: false,
          errorCount: 0,
          showAlert: !closeAlert,
          selectedDiscussions: [],
        }),

      validate: () => {
        let canContinue = false

        set(prevState => {
          const isValid = Object.values(prevState.discussionStates).every(
            state => state !== 'not_set',
          )

          if (isValid) {
            canContinue = true
          }

          const errorCount = isValid
            ? 0
            : Object.values(prevState.discussionStates).filter(s => s === 'not_set').length

          return {
            isValid,
            isLoading: isValid,
            isDirty: true,
            errorCount,
          }
        })

        return canContinue
      },
    }),
    {name: 'ManageThreadedRepliesStore'},
  ),
)
