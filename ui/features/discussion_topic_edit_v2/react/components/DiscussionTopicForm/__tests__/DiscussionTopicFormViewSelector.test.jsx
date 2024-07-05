// @vitest-environment jsdom
/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {Views, DiscussionTopicFormViewSelector} from '../DiscussionTopicFormViewSelector'
import {render, fireEvent} from '@testing-library/react'
import React from 'react'

describe('DiscussionTopicFormViewSelector', () => {
  const setup = ({
    selectedView = Views.Details,
    setSelectedView = jest.fn(),
    breakpoints = {mobileOnly: false},
    shouldMasteryPathsBeVisible = true,
    shouldMasteryPathsBeEnabled = true,
  } = {}) => {
    return render(
      <DiscussionTopicFormViewSelector
        selectedView={selectedView}
        setSelectedView={setSelectedView}
        breakpoints={breakpoints}
        shouldMasteryPathsBeVisible={shouldMasteryPathsBeVisible}
        shouldMasteryPathsBeEnabled={shouldMasteryPathsBeEnabled}
      />
    )
  }

  it('should render the view selector', () => {
    expect(setup()).toBeTruthy()
  })

  it('should show Mastery Paths when shouldMasteryPathsBeVisible is false', () => {
    const {queryByText} = setup({shouldMasteryPathsBeVisible: true})

    expect(queryByText('Mastery Paths')).toBeTruthy()
  })

  it('should hide Mastery Paths when shouldMasteryPathsBeVisible is false', () => {
    const {queryByText} = setup({shouldMasteryPathsBeVisible: false})

    expect(queryByText('Mastery Paths')).toBeFalsy()
  })

  it('should show the Details tab by default', () => {
    const {queryByText} = setup()

    expect(queryByText('Details')).toBeTruthy()
  })

  it('should show a disabled Mastery Paths tab when shouldMasteryPathsBeEnabled is false', () => {
    const {queryByText} = setup({shouldMasteryPathsBeEnabled: false})
    const tab = queryByText('Mastery Paths')

    expect(tab).toBeTruthy()
    expect(tab).toHaveAttribute('aria-disabled', 'true')
  })

  it('should correctly call setSelectedView when Mastery Paths is clicked', () => {
    const setSelectedView = jest.fn()
    const {queryByText} = setup({setSelectedView})

    fireEvent.click(queryByText('Mastery Paths'))

    expect(setSelectedView).toHaveBeenCalledWith(Views.MasteryPaths)
  })

  it('should correctly call setSelectedView when Details is clicked', () => {
    const setSelectedView = jest.fn()
    const {queryByText} = setup({setSelectedView})

    fireEvent.click(queryByText('Details'))

    expect(setSelectedView).toHaveBeenCalledWith(Views.Details)
  })

  it('should render a select when mobileOnly is true', () => {
    const {queryByTestId} = setup({breakpoints: {mobileOnly: true}})

    expect(queryByTestId('view-select')).toBeTruthy()
  })

  it('should not render a select when mobileOnly is false', () => {
    const {queryByTestId} = setup({breakpoints: {mobileOnly: false}})

    expect(queryByTestId('view-select')).toBeFalsy()
  })
})
