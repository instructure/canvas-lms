/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React from 'react'
import {MockedProvider} from '@apollo/client/testing'
import {render as rtlRender} from '@testing-library/react'
import OutcomesContext, {
  ACCOUNT_GROUP_ID,
  ROOT_GROUP_ID,
} from '@canvas/outcomes/react/contexts/OutcomesContext'
import {createCache} from '@canvas/apollo-v3'
import {findModalMocks} from '@canvas/outcomes/mocks/Outcomes'
import {findOutcomesMocks, groupMocks, treeGroupMocks} from '@canvas/outcomes/mocks/Management'
import resolveProgress from '@canvas/progress/resolve_progress'

export const delayImportOutcomesProgress = () => {
  let realResolve
  resolveProgress.mockReturnValueOnce(
    new Promise(resolve => {
      realResolve = resolve
    }),
  )

  return realResolve
}

export const defaultTreeGroupMocks = () =>
  treeGroupMocks({
    groupsStruct: {
      100: [200],
      200: [300],
      300: [400, 401, 402],
    },
    detailsStructure: {
      100: [1, 2, 3],
      200: [1, 2, 3],
      300: [1, 2, 3],
      400: [1],
      401: [2],
      402: [3],
    },
    contextId: '1',
    contextType: 'Course',
    findOutcomesTargetGroupId: '0',
    groupOutcomesNotImportedCount: {
      200: 3,
      300: 3,
    },
    withGroupDetailsRefetch: true,
  })

export const WITH_FIND_GROUP_REFETCH = true

export const courseImportMocks = [
  ...findModalMocks(),
  ...groupMocks({groupId: '100'}),
  ...findOutcomesMocks({
    groupId: '300',
    isImported: false,
    contextType: 'Course',
    outcomesCount: 51,
    withFindGroupRefetch: WITH_FIND_GROUP_REFETCH,
  }),
]

export const createDefaultProps = (
  onCloseHandlerMock,
  setTargetGroupIdsToRefetchMock,
  setImportsTargetGroupMock,
) => {
  return (props = {}) => ({
    open: true,
    importsTargetGroup: {},
    onCloseHandler: onCloseHandlerMock,
    setTargetGroupIdsToRefetch: setTargetGroupIdsToRefetchMock,
    setImportsTargetGroup: setImportsTargetGroupMock,
    ...props,
  })
}

export const renderWithContext = (
  children,
  {
    contextType = 'Account',
    contextId = '1',
    mocks = findModalMocks(),
    renderer = rtlRender,
    globalRootId = '',
    rootOutcomeGroup = {id: '0'},
    rootIds = [ACCOUNT_GROUP_ID, ROOT_GROUP_ID, globalRootId],
    isMobileView = false,
    cache = createCache(),
  } = {},
) => {
  return renderer(
    <OutcomesContext.Provider
      value={{
        env: {
          contextType,
          contextId,
          isMobileView,
          globalRootId,
          rootIds,
          rootOutcomeGroup,
          treeBrowserRootGroupId: ROOT_GROUP_ID,
          treeBrowserAccountGroupId: ACCOUNT_GROUP_ID,
        },
      }}
    >
      <MockedProvider cache={cache} mocks={mocks}>
        {children}
      </MockedProvider>
    </OutcomesContext.Provider>,
  )
}
