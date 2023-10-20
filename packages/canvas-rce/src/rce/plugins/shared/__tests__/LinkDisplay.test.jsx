/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {LinkDisplay} from '../LinkDisplay'
import {render, fireEvent} from '@testing-library/react'
import {showFlashAlert} from '../../../../common/FlashAlert'

jest.mock('../../../../common/FlashAlert')

describe('LinkDisplay', () => {
  let props

  beforeEach(() => {
    props = {
      linkText: 'default text',
      linkFileName: 'default link filename',
      placeholderText: 'default placeholder',
      published: true,
      handleTextChange: jest.fn(),
      linkType: 'wikiPages',
    }
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  afterAll(() => {
    jest.resetAllMocks()
  })

  const renderComponent = overrideProps => {
    return render(<LinkDisplay {...props} {...overrideProps} />)
  }

  it('text input displays link text prop', () => {
    const {getByLabelText} = renderComponent()
    const textInput = getByLabelText(/text \(optional\)/i)
    expect(textInput.value).toEqual('default text')
  })

  it('placeholder text matches the prop', () => {
    const {getByLabelText} = renderComponent()
    const textInput = getByLabelText(/text \(optional\)/i)
    expect(textInput.placeholder).toEqual('default placeholder')
  })

  it('link file name inside the component matches the prop', () => {
    const {getByTestId} = renderComponent()
    const linkName = getByTestId('selected-link-name')
    expect(linkName.innerHTML).toEqual('default link filename')
  })

  it('icon color is success when published', () => {
    const {getByTestId} = renderComponent()
    const iconWrapper = getByTestId('icon-wrapper')
    expect(iconWrapper).toHaveAttribute('color', 'success')
  })

  it('icon color is primary when not published', () => {
    const {getByTestId} = renderComponent({published: false})
    const iconWrapper = getByTestId('icon-wrapper')
    expect(iconWrapper).toHaveAttribute('color', 'primary')
  })

  it('handletextchange prop is called when user types in textinput', () => {
    const callback = jest.fn()
    const {getByLabelText} = renderComponent({handleTextChange: callback})
    const textInput = getByLabelText(/text \(optional\)/i)
    fireEvent.input(textInput, {target: {value: 'something'}})
    expect(callback).toHaveBeenCalledWith('something')
  })

  it('announces selection changes', () => {
    const {rerender} = renderComponent()
    rerender(<LinkDisplay {...props} linkFileName="Course Link 2" />)
    expect(showFlashAlert).toHaveBeenLastCalledWith({
      message: 'Selected Course Link 2',
      srOnly: true,
      type: 'info',
    })
  })

  it('renders the appropriate icon based on linkType', () => {
    const {rerender, getByTestId} = renderComponent()
    let iconContainer = getByTestId('icon-wrapper')
    expect(iconContainer.querySelector('svg')).toHaveAttribute('name', 'IconDocument')
    rerender(<LinkDisplay {...props} linkType="assignments" />)
    iconContainer = getByTestId('icon-wrapper')
    expect(iconContainer.querySelector('svg')).toHaveAttribute('name', 'IconAssignment')
  })

  describe('screenreader content', () => {
    it('describes the linkType and publish status', () => {
      const {rerender, getByTestId} = renderComponent()
      expect(getByTestId('screenreader_content').textContent).toEqual('link type: Pagepublished')
      rerender(<LinkDisplay {...props} linkType="quizzes" published={false} />)
      expect(getByTestId('screenreader_content').textContent).toEqual('link type: Quizunpublished')
    })

    it('is not present if linkType is falsy', () => {
      const {rerender, queryByTestId} = renderComponent({linkType: undefined})
      expect(queryByTestId('screenreader_content')).not.toBeInTheDocument()
      rerender(<LinkDisplay {...props} linkType={null} />)
      expect(queryByTestId('screenreader_content')).not.toBeInTheDocument()
    })

    it('does not describe publish status if linkType is navigation', () => {
      const {getByTestId} = renderComponent({linkType: 'navigation'})
      expect(getByTestId('screenreader_content').textContent).toEqual('link type: Navigation')
    })
  })
})
