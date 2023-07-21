/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import {merge} from 'lodash'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import OutcomeGroupHeader from '../OutcomeGroupHeader'

describe('OutcomeGroupHeader', () => {
  let onMenuHandlerMock, isMobileView, hideOutcomesViewMock
  const defaultProps = (props = {}) =>
    merge(
      {
        title: 'Group Title',
        description: 'Group Description',
        onMenuHandler: onMenuHandlerMock,
        canManage: true,
        hideOutcomesView: hideOutcomesViewMock,
      },
      props
    )

  beforeEach(() => {
    onMenuHandlerMock = jest.fn()
    hideOutcomesViewMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const renderWithContext = children => {
    return render(
      <OutcomesContext.Provider value={{env: {isMobileView}}}>{children}</OutcomesContext.Provider>
    )
  }

  it('renders Outcome Group custom title when title prop provided', () => {
    const {getByText} = render(<OutcomeGroupHeader {...defaultProps()} />)
    expect(getByText('Group Title Outcomes')).toBeInTheDocument()
  })

  it('renders Outcome Group default title when title prop not provided', () => {
    const {getByText} = render(<OutcomeGroupHeader {...defaultProps({title: null})} />)
    expect(getByText('Outcomes')).toBeInTheDocument()
  })

  describe('OutcomeKebabMenu', () => {
    it('renders OutcomeKebabMenu with functional move/edit/delete when canManage is true', () => {
      const {getByText} = render(<OutcomeGroupHeader {...defaultProps({})} />)
      const actions = ['Edit', 'Remove', 'Move']
      actions.forEach(action => {
        fireEvent.click(getByText('Menu for group Group Title'))
        fireEvent.click(getByText(action))
      })
      expect(onMenuHandlerMock).toHaveBeenCalledTimes(3)
    })

    it('does not render OutcomeKebabMenu when canManage is false', () => {
      const {queryByText} = render(<OutcomeGroupHeader {...defaultProps({canManage: false})} />)
      expect(queryByText('Menu for group Group Title')).not.toBeInTheDocument()
    })
  })

  describe('mobile view', () => {
    beforeAll(() => {
      isMobileView = true
    })

    it('renders the group title', () => {
      const {getByText} = renderWithContext(<OutcomeGroupHeader {...defaultProps()} />)
      expect(getByText('Group Title')).toBeInTheDocument()
    })

    it('renders a caret', () => {
      const {getByText} = renderWithContext(<OutcomeGroupHeader {...defaultProps({})} />)
      expect(getByText('Select another group')).toBeInTheDocument()
    })

    it('hideOutcomeView is called when the caret is clicked', () => {
      const {getByText} = renderWithContext(<OutcomeGroupHeader {...defaultProps({})} />)
      fireEvent.click(getByText('Select another group'))
      expect(hideOutcomesViewMock).toHaveBeenCalled()
    })

    it('focuses on the caret on mount', () => {
      const {getByText} = renderWithContext(<OutcomeGroupHeader {...defaultProps({})} />)
      expect(getByText('Select another group').closest('button')).toHaveFocus()
    })
  })
})
