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
import {act, render as rtlRender} from '@testing-library/react'
import {MockedProvider} from '@apollo/client/testing'
import {createCache} from '@canvas/apollo-v3'
import CreateOutcomeModal from '../CreateOutcomeModal'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

vi.useFakeTimers()

describe('CreateOutcomeModal', () => {
  let onCloseHandlerMock
  let onSuccessMock
  let cache
  const defaultProps = (props = {}) => ({
    isOpen: true,
    onCloseHandler: onCloseHandlerMock,
    onSuccess: onSuccessMock,
    ...props,
  })

  const render = (
    children,
    {
      contextType = 'Account',
      contextId = '1',
      friendlyDescriptionFF = true,
      accountLevelMasteryScalesFF = true,
      mocks = [],
      isMobileView = false,
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
            friendlyDescriptionFF,
            accountLevelMasteryScalesFF,
            isMobileView,
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

  beforeEach(() => {
    onCloseHandlerMock = vi.fn()
    onSuccessMock = vi.fn()
    cache = createCache()
    vi.clearAllTimers()
  })

  afterEach(() => {
    vi.clearAllMocks()
    vi.clearAllTimers()
  })

  describe('Mobile', () => {
    describe('Account Level Mastery Scales Feature Flag', () => {
      describe('when feature flag disabled - display tests', () => {
        it('displays Calculation Method selection form', async () => {
          const {getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
            accountLevelMasteryScalesFF: false,
            isMobileView: true,
          })
          await act(async () => vi.runOnlyPendingTimers())
          expect(getByLabelText('Calculation Method')).toBeInTheDocument()
        })

        it('displays Proficiency Ratings selection form', async () => {
          const {getByTestId} = render(<CreateOutcomeModal {...defaultProps()} />, {
            accountLevelMasteryScalesFF: false,
            isMobileView: true,
          })
          await act(async () => vi.runOnlyPendingTimers())
          expect(getByTestId('outcome-management-ratings')).toBeInTheDocument()
        })

        it('displays horizontal divider between ratings and calculation method which is hidden from screen readers', async () => {
          const {getByTestId} = render(<CreateOutcomeModal {...defaultProps()} />, {
            accountLevelMasteryScalesFF: false,
            isMobileView: true,
          })
          await act(async () => vi.runOnlyPendingTimers())
          expect(getByTestId('outcome-create-modal-horizontal-divider')).toBeInTheDocument()
        })
      })
    })
  })
})
