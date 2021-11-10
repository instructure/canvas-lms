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
import {act, render, within} from '@testing-library/react'

import {Footer} from '../footer'

const publishPlan = jest.fn()
const resetPlan = jest.fn()

const defaultProps = {
  autoSaving: false,
  planPublishing: false,
  publishPlan,
  resetPlan,
  showLoadingOverlay: false,
  unpublishedChanges: true
}

afterEach(() => {
  jest.clearAllMocks()
})

describe('Footer', () => {
  it('renders cancel and publish buttons when there are unpublished changes', () => {
    const {getByRole} = render(<Footer {...defaultProps} />)

    const cancelButton = getByRole('button', {name: 'Cancel'})
    expect(cancelButton).toBeInTheDocument()
    act(() => cancelButton.click())
    expect(resetPlan).toHaveBeenCalled()

    const publishButton = getByRole('button', {name: 'Publish'})
    expect(publishButton).toBeInTheDocument()
    act(() => publishButton.click())
    expect(publishPlan).toHaveBeenCalled()
  })

  it('disables cancel and publish buttons when there are no unpublished changes or there is network activity', () => {
    Object.entries({
      autoSaving: true,
      showLoadingOverlay: true,
      unpublishedChanges: false
    }).forEach(([prop, value]) => {
      const overrideProps = {...defaultProps, [prop]: value}
      const {getByRole, unmount} = render(<Footer {...overrideProps} />)
      expect(getByRole('button', {name: 'Cancel'})).toBeDisabled()
      expect(getByRole('button', {name: 'Publish'})).toBeDisabled()
      unmount()
    })
  })

  it('renders a loading spinner inside the publish button when publishing is ongoing', () => {
    const {getByRole} = render(<Footer {...defaultProps} planPublishing />)

    const publishButton = getByRole('button', {name: 'Publishing plan...'})
    expect(publishButton).toBeInTheDocument()

    const spinner = within(publishButton).getByRole('img', {name: 'Publishing plan...'})
    expect(spinner).toBeInTheDocument()
  })
})
