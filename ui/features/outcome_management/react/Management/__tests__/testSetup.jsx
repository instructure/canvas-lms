/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {render as rtlRender, cleanup} from '@testing-library/react'
import {createCache} from '@canvas/apollo-v3'
import fakeEnv from '@canvas/test-utils/fakeENV'
import OutcomeManagementPanel from '../index'
import OutcomesContext, {ACCOUNT_GROUP_ID} from '@canvas/outcomes/react/contexts/OutcomesContext'
import {
  accountMocks,
  courseMocks,
  groupDetailMocks,
  groupMocks,
} from '@canvas/outcomes/mocks/Management'

// Note: jest.mock calls must be in each test file for proper hoisting

// Track current cache for teardown
let currentCache = null

/**
 * Creates the default props for OutcomeManagementPanel
 */
export const createDefaultProps = (overrides = {}, mocks = {}) => {
  const {
    onLhsSelectedGroupIdChangedMock = jest.fn(),
    handleFileDropMock = jest.fn(),
    setTargetGroupIdsToRefetchMock = jest.fn(),
    setImportsTargetGroupMock = jest.fn(),
  } = mocks

  return {
    importNumber: 0,
    createdOutcomeGroupIds: [],
    onLhsSelectedGroupIdChanged: onLhsSelectedGroupIdChangedMock,
    handleFileDrop: handleFileDropMock,
    targetGroupIdsToRefetch: [],
    setTargetGroupIdsToRefetch: setTargetGroupIdsToRefetchMock,
    importsTargetGroup: {},
    setImportsTargetGroup: setImportsTargetGroupMock,
    ...overrides,
  }
}

/**
 * Creates default mocks for Course context
 */
export const createDefaultCourseMocks = () => [
  ...courseMocks({childGroupsCount: 2}),
  ...groupMocks({
    title: 'Course folder 0',
    groupId: '200',
    parentOutcomeGroupTitle: 'Root course folder',
    parentOutcomeGroupId: '2',
  }),
  ...groupDetailMocks({
    title: 'Course folder 0',
    groupDescription: 'Course folder 0 group description',
    groupId: '200',
    contextType: 'Course',
    contextId: '2',
    withMorePage: false,
  }),
  ...groupDetailMocks({
    title: 'Course folder 1',
    groupDescription: 'Course folder 1 group description',
    groupId: '2',
    contextType: 'Course',
    contextId: '2',
    withMorePage: false,
  }),
]

/**
 * Creates default props for group detail scenarios
 */
export const createGroupDetailDefaultProps = defaultMocks => ({
  contextType: 'Course',
  contextId: '2',
  mocks: defaultMocks,
})

/**
 * Render helper for OutcomeManagementPanel tests
 */
export const createRenderFunction = (cache, isMobileView = false) => {
  return (
    children,
    {
      contextType = 'Account',
      contextId = '1',
      canManage = true,
      mocks = accountMocks({childGroupsCount: 0}),
      renderer = rtlRender,
      treeBrowserRootGroupId = '1',
    } = {},
  ) => {
    return renderer(
      <OutcomesContext.Provider
        value={{
          env: {
            contextType,
            contextId,
            canManage,
            isMobileView,
            rootIds: [ACCOUNT_GROUP_ID],
            treeBrowserRootGroupId,
          },
        }}
      >
        <MockedProvider cache={cache} mocks={mocks}>
          {children}
        </MockedProvider>
      </OutcomesContext.Provider>,
    )
  }
}

/**
 * Teardown hook for tests - call this in afterEach to prevent memory leaks
 */
export const teardownTest = () => {
  cleanup()
  if (currentCache) {
    currentCache.reset()
    currentCache = null
  }
  fakeEnv.teardown()
}

/**
 * Setup hook for tests - call this in beforeEach
 */
export const setupTest = (options = {}) => {
  const {isMobileView = false} = options
  const cache = createCache()
  currentCache = cache
  const onLhsSelectedGroupIdChangedMock = jest.fn()
  const handleFileDropMock = jest.fn()
  const setTargetGroupIdsToRefetchMock = jest.fn()
  const setImportsTargetGroupMock = jest.fn()

  fakeEnv.setup({
    PERMISSIONS: {
      manage_outcomes: true,
    },
  })

  const defaultMocks = createDefaultCourseMocks()
  const groupDetailDefaultProps = createGroupDetailDefaultProps(defaultMocks)
  const render = createRenderFunction(cache, isMobileView)

  const defaultProps = (props = {}) =>
    createDefaultProps(props, {
      onLhsSelectedGroupIdChangedMock,
      handleFileDropMock,
      setTargetGroupIdsToRefetchMock,
      setImportsTargetGroupMock,
    })

  return {
    cache,
    defaultMocks,
    groupDetailDefaultProps,
    render,
    defaultProps,
    onLhsSelectedGroupIdChangedMock,
    handleFileDropMock,
    setTargetGroupIdsToRefetchMock,
    setImportsTargetGroupMock,
  }
}

// Re-export commonly used items
export {OutcomeManagementPanel}
export {
  accountMocks,
  courseMocks,
  groupDetailMocks,
  groupMocks,
} from '@canvas/outcomes/mocks/Management'
export {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
export {clickWithPending} from '@canvas/outcomes/react/helpers/testHelpers'
