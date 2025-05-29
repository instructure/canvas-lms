/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import Comments from '../Comments'

import {assessments} from './fixtures'

describe('The Comments component', () => {
  const props = {
    editing: true,
    assessment: assessments.freeForm.data[1],
    savedComments: ['I award you no points', 'May god have mercy on your soul'],
    saveLater: false,
    setComments: jest.fn(),
    setSaveLater: jest.fn(),
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders the root component with a textarea when editing', () => {
    const {getByLabelText} = render(<Comments {...props} />)

    // When editing, it should render a textarea for comments
    const textarea = getByLabelText('Comments')
    expect(textarea).toBeInTheDocument()
    expect(textarea.tagName).toBe('TEXTAREA')
  })

  it('renders comments_html when not editing', () => {
    const {container, getByText} = render(<Comments {...{...props, editing: false}} />)

    // When not editing, it should render the Comments header
    expect(getByText('Comments')).toBeInTheDocument()

    // The HTML content should be in the document
    // Note: dangerouslySetInnerHTML content is not directly accessible via innerHTML
    // but we can check that the text is rendered
    expect(container.textContent).toContain('I award you no points')
  })

  it('renders a placeholder when no assessment provided', () => {
    const {getByText} = render(<Comments {...{...props, editing: false, assessment: null}} />)

    // Should show the placeholder text when no assessment is provided
    expect(
      getByText(
        'This area will be used by the assessor to leave comments related to this criterion.',
      ),
    ).toBeInTheDocument()
  })

  it('shows no selector when no saved comments are available', () => {
    const {queryByText} = render(<Comments {...{...props, savedComments: []}} />)

    // Should not show the saved comments selector
    expect(queryByText('Saved Comments')).not.toBeInTheDocument()
  })

  it('can use saved comments from before', () => {
    const setComments = jest.fn()
    const {getByLabelText, getByText} = render(<Comments {...{...props, setComments}} />)

    // Open the dropdown
    const select = getByLabelText('Saved Comments')
    fireEvent.click(select)

    // Select the last option
    const option = getByText('May god have mercy on your soul')
    fireEvent.click(option)

    // Should call setComments with the selected comment
    expect(setComments).toHaveBeenCalledWith('May god have mercy on your soul')
  })

  it('truncates long saved comments', () => {
    const long = 'this is the song that never ends, yes it goes on and on my friends-'.repeat(50)
    const {getByLabelText, getByText} = render(<Comments {...{...props, savedComments: [long]}} />)

    // Open the dropdown
    const select = getByLabelText('Saved Comments')
    fireEvent.click(select)

    // The comment should be truncated
    const truncatedText = getByText(/^this is the song.+…$/)
    expect(truncatedText).toBeInTheDocument()
    // The text should be truncated to 100 characters (99 + ellipsis)
    expect(truncatedText.textContent.length).toBeLessThanOrEqual(100)
  })

  it('allows entering comments in the textarea', () => {
    const setComments = jest.fn()
    const {getByLabelText} = render(<Comments {...{...props, setComments}} />)

    // Get the textarea and trigger a change event
    const textarea = getByLabelText('Comments')
    fireEvent.change(textarea, {target: {value: 'New comment text'}})

    // Should call setComments with the new text
    expect(setComments).toHaveBeenCalledWith('New comment text')
  })

  it('can check / uncheck save for later', () => {
    const setSaveLater = jest.fn()
    const {getByLabelText} = render(<Comments {...{...props, setSaveLater}} />)

    // Click the checkbox
    const checkbox = getByLabelText('Save this comment for reuse')
    fireEvent.click(checkbox)

    // Should call setSaveLater with true
    expect(setSaveLater).toHaveBeenCalledWith(true)
  })

  it('does not show save later checkbox when allowSaving is false', () => {
    const {queryByLabelText} = render(<Comments {...{...props, allowSaving: false}} />)

    // The checkbox should not be present
    expect(queryByLabelText('Save this comment for reuse')).not.toBeInTheDocument()
  })

  it('renders a footer after the comment when provided', () => {
    const footerText = 'this is a footer'
    const {getByText} = render(
      <Comments {...{...props, editing: false, footer: <div>{footerText}</div>}} />,
    )

    // The footer should be rendered
    expect(getByText(footerText)).toBeInTheDocument()
  })
})
