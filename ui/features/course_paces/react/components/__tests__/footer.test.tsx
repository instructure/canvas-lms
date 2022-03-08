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

const publishPace = jest.fn()
const resetPace = jest.fn()

const defaultProps = {
  autoSaving: false,
  pacePublishing: false,
  publishPace,
  resetPace,
  showLoadingOverlay: false,
  studentPace: false,
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
    expect(resetPace).toHaveBeenCalled()

    const publishButton = getByRole('button', {name: 'Publish'})
    expect(publishButton).toBeInTheDocument()
    act(() => publishButton.click())
    expect(publishPace).toHaveBeenCalled()
  })

  it('shows cannot cancel and publish tooltip when there are no unpublished changes', () => {
    const {getByText} = render(<Footer {...defaultProps} unpublishedChanges={false} />)
    expect(getByText('There are no pending changes to cancel')).toBeInTheDocument()
    expect(getByText('There are no pending changes to publish')).toBeInTheDocument()
  })

  it('shows cannot cancel and publish tooltip while publishing', () => {
    const {getByText} = render(<Footer {...defaultProps} pacePublishing />)
    expect(getByText('You cannot cancel while publishing')).toBeInTheDocument()
    expect(getByText('You cannot publish while publishing')).toBeInTheDocument()
  })

  it('shows cannot cancel and publish tooltip while auto saving', () => {
    const {getByText} = render(<Footer {...defaultProps} autoSaving />)
    expect(getByText('You cannot cancel while publishing')).toBeInTheDocument()
    expect(getByText('You cannot publish while publishing')).toBeInTheDocument()
  })

  it('shows cannot cancel and publish tooltip while loading', () => {
    const {getByText} = render(<Footer {...defaultProps} showLoadingOverlay />)
    expect(getByText('You cannot cancel while loading the pace')).toBeInTheDocument()
    expect(getByText('You cannot publish while loading the pace')).toBeInTheDocument()
  })

  it('renders a loading spinner inside the publish button when publishing is ongoing', () => {
    const {getByRole} = render(<Footer {...defaultProps} pacePublishing />)

    const publishButton = getByRole('button', {name: 'Publishing pace...'})
    expect(publishButton).toBeInTheDocument()

    const spinner = within(publishButton).getByRole('img', {name: 'Publishing pace...'})
    expect(spinner).toBeInTheDocument()
  })

  it('renders nothing for student paces', () => {
    const {queryByRole} = render(<Footer {...defaultProps} studentPace />)
    expect(queryByRole('button')).not.toBeInTheDocument()
  })

  it('keeps focus on Cancel button after clicking', () => {
    const {getByRole} = render(<Footer {...defaultProps} />)

    const cancelButton = getByRole('button', {name: 'Cancel'})
    act(() => {
      cancelButton.focus()
      cancelButton.click()
    })
    expect(document.activeElement).toBe(cancelButton)
  })

  it('keeps focus on Publish button after clicking', () => {
    const {getByRole} = render(<Footer {...defaultProps} />)

    const pubButton = getByRole('button', {name: 'Publish'})
    act(() => {
      pubButton.focus()
      pubButton.click()
    })
    expect(document.activeElement).toBe(pubButton)
  })
})
