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

import {render, screen} from '@testing-library/react'
import React from 'react'
import PageNameContainer from '../PageNameContainer'
import userEvent from '@testing-library/user-event'

describe('PageNameContainer', () => {
  const onSave = jest.fn()
  const onCancel = jest.fn()

  const props = {
    pageName: 'Page Name',
    onPreview: jest.fn(),
    onSave,
    onCancel,
    onKeepEditing: jest.fn(),
    setHidden: jest.fn(),
  }

  const renderComponent = () => {
    const contentBtnNode = document.createElement('div')
    const sideBtnNode = document.createElement('div')
    return render(
      <React.Fragment>
        <div ref={node => node && node.appendChild(sideBtnNode)} />
        <div ref={node => node && node.appendChild(contentBtnNode)} />
        <PageNameContainer {...props} contentBtnNode={contentBtnNode} sideBtnNode={sideBtnNode} />
      </React.Fragment>,
    )
  }

  afterEach(() => {
    jest.resetAllMocks()
  })

  it('renders correct buttons and input if in preview', () => {
    const {getByTestId, queryAllByText} = renderComponent()

    // editing
    const input = getByTestId('page-name-input')
    const previewButtons = queryAllByText('Preview')
    expect(input).toBeVisible()
    expect(queryAllByText('Keep Editing')).toHaveLength(0)
    expect(previewButtons).toHaveLength(2)
    expect(queryAllByText('Cancel')).toHaveLength(2)
    expect(queryAllByText('Save')).toHaveLength(2)

    // previewing
    previewButtons[0].click()
    expect(input).not.toBeVisible()
    expect(queryAllByText('Preview')).toHaveLength(0)
    expect(queryAllByText('Keep Editing')).toHaveLength(2)
    expect(queryAllByText('Cancel')).toHaveLength(2)
    expect(queryAllByText('Save')).toHaveLength(2)
  })

  it('calls onSave when save button is clicked', () => {
    const {getAllByText} = renderComponent()

    getAllByText('Save')[0].click()
    expect(onSave).toHaveBeenCalled()
  })

  it('does not call onSave when save button is clicked if input is blank', async () => {
    const {getByTestId, getAllByText} = renderComponent()

    // delete pre-filled input
    const input = getByTestId('page-name-input')
    await userEvent.clear(input)

    getAllByText('Save')[0].click()
    expect(onSave).not.toHaveBeenCalled()
  })

  it('calls onCancel when cancel button is clicked', () => {
    const {getAllByText} = renderComponent()

    getAllByText('Cancel')[0].click()
    expect(onCancel).toHaveBeenCalled()
  })
})
