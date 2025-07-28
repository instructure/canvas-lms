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

import {LtiLaunchDefinition} from '@canvas/select-content-dialog/jquery/select_content_dialog'

// Tagged union of the state of the modal
export type AssetProcessorsAddModalState =
  | {
      tag: 'closed'
    }
  | {
      tag: 'toolList'
    }
  | {
      tag: 'toolLaunch'
      tool: LtiLaunchDefinition
    }
  | {
      tag: 'invalidDeepLinkingResponse'
      tool: LtiLaunchDefinition
    }

// Since these don't change, you can efficiently do
//   const {close} = useAssetProcessorsAddModalState(s => s.actions)
interface AssetProcessorsAddModalActions {
  showToolList: () => void
  close: () => void
  launchTool: (tool: LtiLaunchDefinition) => void
  showInvlidDeepLinkingResponse: (tool: LtiLaunchDefinition) => void
}

export const useAssetProcessorsAddModalState = create<
  {state: AssetProcessorsAddModalState} & {actions: AssetProcessorsAddModalActions}
>(set => ({
  state: {
    tag: 'closed',
  },

  actions: {
    showToolList: () => {
      set({state: {tag: 'toolList'}})
    },
    close: () => {
      set({state: {tag: 'closed'}})
    },
    launchTool: tool => {
      set({state: {tag: 'toolLaunch', tool}})
    },
    showInvlidDeepLinkingResponse: tool => {
      set({state: {tag: 'invalidDeepLinkingResponse', tool}})
    },
  },
}))
