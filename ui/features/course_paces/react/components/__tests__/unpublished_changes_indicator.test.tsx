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

import {render} from '@testing-library/react'
import {UnpublishedChangesIndicator} from '../unpublished_changes_indicator'
import React from 'react'
import userEvent from '@testing-library/user-event'

const onUnpublishedNavigation = jest.fn()

const defaultProps = {
  changeCount: 2,
  onUnpublishedNavigation,
  pacePublishing: false,
  newPace: false,
  blackoutDatesSyncing: false,
  isSyncing: false,
}

afterEach(() => {
  jest.clearAllMocks()
})

describe('UnpublishedChangesIndicator', () => {
  it('pluralizes and formats correctly', () => {
    expect(
      render(<UnpublishedChangesIndicator {...defaultProps} changeCount={0} />).getByText(
        'All changes published'
      )
    ).toBeInTheDocument()
    expect(
      render(<UnpublishedChangesIndicator {...defaultProps} changeCount={1} />).getByText(
        '1 unpublished change'
      )
    ).toBeInTheDocument()
    expect(
      render(<UnpublishedChangesIndicator {...defaultProps} changeCount={2500} />).getByText(
        '2,500 unpublished changes'
      )
    ).toBeInTheDocument()
  })

  describe('onClick callback', () => {
    let onClick: () => void
    beforeEach(() => (onClick = jest.fn()))

    it('is called when clicked if there are pending changes', async () => {
      const {getByRole} = render(
        <UnpublishedChangesIndicator {...defaultProps} changeCount={3} onClick={onClick} />
      )

      await userEvent.click(getByRole('button', {name: '3 unpublished changes'}))
      expect(onClick).toHaveBeenCalled()
    })

    it('is not called when clicked if there are no pending changes', async () => {
      const {getByText} = render(
        <UnpublishedChangesIndicator {...defaultProps} changeCount={0} onClick={onClick} />
      )

      await userEvent.click(getByText('All changes published'))
      expect(onClick).not.toHaveBeenCalled()
    })
  })

  describe('when leaving the page', () => {
    it('should trigger a browser warning when there are unpublished changes', () => {
      render(<UnpublishedChangesIndicator {...defaultProps} />)

      window.dispatchEvent(new window.Event('beforeunload'))
      expect(onUnpublishedNavigation).toHaveBeenCalled()
    })

    it('should not trigger a browser warning when there are no unpublished changes', () => {
      render(<UnpublishedChangesIndicator {...defaultProps} changeCount={0} />)

      window.dispatchEvent(new window.Event('beforeunload'))
      expect(onUnpublishedNavigation).not.toHaveBeenCalled()
    })
  })

  it('throws when a negative changeCount is specified', () => {
    expect(() =>
      render(<UnpublishedChangesIndicator {...defaultProps} changeCount={-1} />)
    ).toThrow()
  })

  it('displays a spinner indicating ongoing publishing when isSyncing is true', () => {
    const {getAllByText} = render(
      <UnpublishedChangesIndicator {...defaultProps} isSyncing={true} />
    )
    expect(getAllByText('Publishing...')[0]).toBeInTheDocument()
  })

  it('renders new pace message if pace has not yet been published', () => {
    const {getByText} = render(
      <UnpublishedChangesIndicator {...defaultProps} changeCount={0} newPace={true} />
    )
    expect(getByText('Pace is new and unpublished')).toBeInTheDocument()
  })

  describe('with course_paces_redesign flag enabled', () => {
    beforeAll(() => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.course_paces_redesign = true
    })

    it('renders "No pending changes to apply" text', () => {
      const {getByText} = render(<UnpublishedChangesIndicator {...defaultProps} changeCount={0} />)
      expect(getByText('No pending changes to apply')).toBeInTheDocument()
    })
  })
})
