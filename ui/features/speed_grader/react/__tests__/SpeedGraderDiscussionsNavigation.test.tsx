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
import {SpeedGraderDiscussionsNavigation} from '../SpeedGraderDiscussionsNavigation'

const setup = () => {
  return render(<SpeedGraderDiscussionsNavigation />)
}

const setupMockIframes = () => {
  const mockContentWindow = {
    postMessage: vi.fn(),
  }

  const mockDiscussionIframe = {
    contentWindow: mockContentWindow,
  }

  const mockSpeedgraderIframe = {
    contentDocument: {
      getElementById: vi.fn().mockReturnValue(mockDiscussionIframe),
    },
  }

  vi.spyOn(document, 'getElementById').mockReturnValue(mockSpeedgraderIframe as any)

  return mockContentWindow
}

describe('SpeedGraderDiscussionsNavigation', () => {
  beforeEach(() => {
    // Mock the DOM structure that the component expects
    document.body.innerHTML = `
      <iframe id="speedgrader_iframe">
        <iframe id="discussion_preview_iframe"></iframe>
      </iframe>
    `
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('renders', () => {
    const {getByText} = setup()

    expect(getByText('Previous Reply')).toBeInTheDocument()
    expect(getByText('Next Reply')).toBeInTheDocument()
  })

  it('calls nextStudentReply when Next Reply button is clicked', () => {
    const {getByTestId} = setup()
    const mockContentWindow = setupMockIframes()
    const nextButton = getByTestId('discussions-next-reply-button')

    fireEvent.click(nextButton)

    expect(mockContentWindow.postMessage).toHaveBeenCalledWith(
      {subject: 'DT.nextStudentReply'},
      '*',
    )
  })

  it('calls previousStudentReply when Previous Reply button is clicked', () => {
    const {getByTestId} = setup()
    const mockContentWindow = setupMockIframes()
    const previousButton = getByTestId('discussions-previous-reply-button')

    fireEvent.click(previousButton)

    expect(mockContentWindow.postMessage).toHaveBeenCalledWith(
      {subject: 'DT.previousStudentReply'},
      '*',
    )
  })
})
