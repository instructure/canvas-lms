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
  isValid: boolean
}

type Actions = {
  initialize: (discussions: string[]) => void
  setDiscussionState: (discussionId: string, state: 'threaded' | 'not_threaded') => void
  toggleSelectedDiscussion: (discussionId: string) => void
  toggleSelectedDiscussions: (discussionIds: string[]) => void
  setIsValid: (isValid: boolean) => void
  setShowAlert: (showAlert: boolean) => void
}

export const useManageThreadedRepliesStore = create<State & Actions>()(
  devtools(
    set => ({
      selectedDiscussions: [],
      discussionStates: {},
      isValid: false,
      showAlert: true, // defautl to true the component itself hides if there is no discussion, but we want to hide it later

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
        return set(prevState => ({
          discussionStates: {
            ...prevState.discussionStates,
            [discussionId]: state,
          },
        }))
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

      setIsValid: isValid => set({isValid}),

      setShowAlert: showAlert => set({showAlert}),
    }),
    {name: 'ManageThreadedRepliesStore'},
  ),
)
