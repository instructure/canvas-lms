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
import fakeENV from '@canvas/test-utils/fakeENV'

/**
 * Creates a render function for FindOutcomesModal tests
 * @param {object} cache - Apollo cache instance
 * @returns {function} render function
 */
export const createFindOutcomesModalRenderer = cache => {
  return (
    children,
    {
      contextType = 'Account',
      contextId = '1',
      mocks = [],
      renderer = rtlRender,
    } = {},
  ) => {
    return renderer(
      <OutcomesContext.Provider
        value={{
          env: {
            contextType,
            contextId,
            isMobileView: false,
            rootIds: [ACCOUNT_GROUP_ID, ROOT_GROUP_ID],
            rootOutcomeGroup: {id: '0'},
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
}

/**
 * Sets up common test environment for FindOutcomesModal tests
 * @returns {object} setup utilities
 */
export const setupFindOutcomesModalTest = () => {
  let cache
  let onCloseHandlerMock
  let setTargetGroupIdsToRefetchMock
  let setImportsTargetGroupMock

  const setup = () => {
    onCloseHandlerMock = vi.fn()
    setTargetGroupIdsToRefetchMock = vi.fn()
    setImportsTargetGroupMock = vi.fn()
    cache = createCache()
    return {
      cache,
      onCloseHandlerMock,
      setTargetGroupIdsToRefetchMock,
      setImportsTargetGroupMock,
    }
  }

  const defaultProps = (props = {}) => ({
    open: true,
    importsTargetGroup: {},
    onCloseHandler: onCloseHandlerMock,
    setTargetGroupIdsToRefetch: setTargetGroupIdsToRefetchMock,
    setImportsTargetGroup: setImportsTargetGroupMock,
    ...props,
  })

  return {
    setup,
    defaultProps,
    get cache() {
      return cache
    },
  }
}

export {fakeENV, ACCOUNT_GROUP_ID, ROOT_GROUP_ID}
