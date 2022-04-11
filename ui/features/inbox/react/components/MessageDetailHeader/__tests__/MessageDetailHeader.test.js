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
import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import {MessageDetailHeader} from '../MessageDetailHeader'
import {responsiveQuerySizes} from '../../../../util/utils'
import {ConversationContext} from '../../../../util/constants'

jest.mock('../../../../util/utils', () => ({
  ...jest.requireActual('../../../../util/utils'),
  responsiveQuerySizes: jest.fn()
}))

describe('MessageDetailHeader', () => {
  beforeAll(() => {
    // Add appropriate mocks for responsive
    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn()
      }
    })

    // Repsonsive Query Mock Default
    responsiveQuerySizes.mockImplementation(() => ({
      desktop: {minWidth: '768px'}
    }))
  })

  it('renders with provided text', () => {
    const props = {text: 'Message Header Text'}
    const {getByText} = render(<MessageDetailHeader {...props} />)
    expect(getByText('Message Header Text')).toBeInTheDocument()
  })

  it('does not render the more options menu when in submission comments scope', () => {
    const props = {text: 'Message Header Text'}
    const {getByText, queryByTestId} = render(
      <ConversationContext.Provider value={{isSubmissionCommentsType: true}}>
        <MessageDetailHeader {...props} />
      </ConversationContext.Provider>
    )
    expect(getByText('Message Header Text')).toBeInTheDocument()
    expect(queryByTestId('message-more-options')).not.toBeInTheDocument()
  })

  describe('sends the selected option to the provided callback function', () => {
    const props = {
      text: 'Button Test'
    }
    it('sends the selected option to the onReply callback function', () => {
      props.onReply = jest.fn()
      const {getByRole} = render(<MessageDetailHeader {...props} />)
      const replyButton = getByRole(
        (role, element) => role === 'button' && element.textContent === 'Reply'
      )

      fireEvent.click(replyButton)

      expect(props.onReply).toHaveBeenCalled()
    })

    it('sends the selected option to the onReplyAll callback function', () => {
      props.onReplyAll = jest.fn()
      const {getByRole, getByText} = render(<MessageDetailHeader {...props} />)
      const moreOptionsButton = getByRole(
        (role, element) => role === 'button' && element.textContent === 'More options'
      )

      fireEvent.click(moreOptionsButton)
      fireEvent.click(getByText('Reply All'))

      expect(props.onReplyAll).toHaveBeenCalled()
    })

    it('sends the selected option to the onDelete callback function', () => {
      props.onDelete = jest.fn()
      const {getByRole, getByText} = render(<MessageDetailHeader {...props} />)
      const moreOptionsButton = getByRole(
        (role, element) => role === 'button' && element.textContent === 'More options'
      )
      fireEvent.click(moreOptionsButton)
      fireEvent.click(getByText('Delete'))

      expect(props.onDelete).toHaveBeenCalled()
    })

    it('sends the selected option to the onForward callback function', () => {
      props.onForward = jest.fn()
      const {getByRole, getByText} = render(<MessageDetailHeader {...props} />)
      const moreOptionsButton = getByRole(
        (role, element) => role === 'button' && element.textContent === 'More options'
      )
      fireEvent.click(moreOptionsButton)
      fireEvent.click(getByText('Forward'))

      expect(props.onForward).toHaveBeenCalled()
    })
  })

  describe('Responsive', () => {
    describe('Mobile', () => {
      beforeEach(() => {
        responsiveQuerySizes.mockImplementation(() => ({
          mobile: {maxWidth: '67'}
        }))
      })

      it('Should render mobile test id for header', async () => {
        const props = {text: 'Message Header Text'}
        const {findByTestId} = render(<MessageDetailHeader {...props} />)
        const headingElm = await findByTestId('message-detail-header-mobile')
        expect(headingElm).toBeTruthy()
      })
    })

    describe('Desktop', () => {
      beforeEach(() => {
        responsiveQuerySizes.mockImplementation(() => ({
          desktop: {maxWidth: '67'}
        }))
      })

      it('Should render desktop test id for header', async () => {
        const props = {text: 'Message Header Text'}
        const {findByTestId} = render(<MessageDetailHeader {...props} />)
        const headingElm = await findByTestId('message-detail-header-desktop')
        expect(headingElm).toBeTruthy()
      })
    })
  })
})
