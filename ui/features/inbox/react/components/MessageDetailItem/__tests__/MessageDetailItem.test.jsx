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
import {responsiveQuerySizes} from '../../../../util/utils'
import {MessageDetailItem} from '../MessageDetailItem'
import fakeENV from '@canvas/test-utils/fakeENV'

jest.mock('../../../../util/utils', () => ({
  ...jest.requireActual('../../../../util/utils'),
  responsiveQuerySizes: jest.fn(),
}))

const defaultProps = {
  conversationMessage: {
    author: {name: 'Tom Thompson', shortName: 'Tom Thompson', pronouns: 'he/him'},
    recipients: [
      {name: 'Tom Thompson', shortName: 'Tom Thompson'},
      {name: 'Billy Harris', shortName: 'Billy Harris'},
    ],
    createdAt: 'Tue, 20 Apr 2021 14:31:25 UTC +00:00',
    body: 'This is the body text for the message.',
  },
  contextName: 'Fake Course 1',
}

const setup = props => {
  return render(<MessageDetailItem {...defaultProps} {...props} />)
}

describe('MessageDetailItem', () => {
  beforeEach(() => {
    fakeENV.setup({
      CONVERSATIONS: {
        ATTACHMENTS_FOLDER_ID: '1',
      },
      inbox_translation_enabled: true,
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  beforeAll(() => {
    // Add appropriate mocks for responsive
    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn(),
      }
    })

    // Repsonsive Query Mock Default
    responsiveQuerySizes.mockImplementation(() => ({
      desktop: {minWidth: '768px'},
    }))
  })

  it('renders with provided data', () => {
    const {getByText} = setup({body: 'a link to google.com'})

    expect(getByText('Tom Thompson')).toBeInTheDocument()
    expect(getByText(', Billy Harris')).toBeInTheDocument()
    expect(getByText('This is the body text for the message.')).toBeInTheDocument()
    expect(getByText('Fake Course 1')).toBeInTheDocument()
    expect(getByText('Apr 20, 2021 at 2:31pm')).toBeInTheDocument()
  })

  it('renders with a link when a link is present', () => {
    const props = {
      conversationMessage: {
        author: {name: 'Tom Thompson', shortName: 'Tom Thompson'},
        recipients: [
          {name: 'Tom Thompson', shortName: 'Tom Thompson'},
          {name: 'Billy Harris', shortName: 'Billy Harris'},
        ],
        createdAt: 'Tue, 20 Apr 2021 14:31:25 UTC +00:00',
        body: 'a link to google.com',
      },
      contextName: 'Fake Course 1',
    }

    const {getByText, queryByText} = render(<MessageDetailItem {...props} />)

    expect(getByText('Tom Thompson')).toBeInTheDocument()
    expect(getByText(', Billy Harris')).toBeInTheDocument()
    expect(queryByText('a link to google.com')).not.toBeInTheDocument()
    expect(getByText('google.com')).toBeInTheDocument()
    expect(getByText('a link to')).toBeInTheDocument()
    expect(getByText('Fake Course 1')).toBeInTheDocument()
    expect(getByText('Apr 20, 2021 at 2:31pm')).toBeInTheDocument()
  })

  it('renders and xss attempt gets sanitized', () => {
    const props = {
      conversationMessage: {
        author: {name: 'Tom Thompson', shortName: 'Tom Thompson'},
        recipients: [
          {name: 'Tom Thompson', shortName: 'Tom Thompson'},
          {name: 'Billy Harris', shortName: 'Billy Harris'},
        ],
        createdAt: 'Tue, 20 Apr 2021 14:31:25 UTC +00:00',
        body: "Attempting to attack!<script>alert('XSS')</script>",
        htmlBody: "<p>Attempting to attack!<script>alert('XSS')</script></p>",
      },
      contextName: 'Fake Course 1',
    }

    const {container, getByText} = render(<MessageDetailItem {...props} />)

    expect(getByText('Tom Thompson')).toBeInTheDocument()
    expect(getByText(', Billy Harris')).toBeInTheDocument()
    expect(container.querySelector('script')).not.toBeInTheDocument()
    expect(getByText('Attempting to attack!')).toBeInTheDocument()
    expect(getByText('Fake Course 1')).toBeInTheDocument()
    expect(getByText('Apr 20, 2021 at 2:31pm')).toBeInTheDocument()
  })

  it('renders and does not display html tags', () => {
    const props = {
      conversationMessage: {
        author: {name: 'Tom Thompson', shortName: 'Tom Thompson'},
        recipients: [
          {name: 'Tom Thompson', shortName: 'Tom Thompson'},
          {name: 'Billy Harris', shortName: 'Billy Harris'},
        ],
        createdAt: 'Tue, 20 Apr 2021 14:31:25 UTC +00:00',
        body: 'Formatted text',
        htmlBody: '<p>Formatted text</p>',
      },
      contextName: 'Fake Course 1',
    }

    const {queryByText, getByText} = render(<MessageDetailItem {...props} />)

    expect(getByText('Tom Thompson')).toBeInTheDocument()
    expect(getByText(', Billy Harris')).toBeInTheDocument()
    expect(queryByText('<p>Formatted text</p>')).not.toBeInTheDocument()
    expect(getByText('Formatted text')).toBeInTheDocument()
    expect(getByText('Fake Course 1')).toBeInTheDocument()
    expect(getByText('Apr 20, 2021 at 2:31pm')).toBeInTheDocument()
  })

  it('renders and preserves new lines', () => {
    const props = {
      conversationMessage: {
        author: {name: 'Tom Thompson', shortName: 'Tom Thompson'},
        recipients: [
          {name: 'Tom Thompson', shortName: 'Tom Thompson'},
          {name: 'Billy Harris', shortName: 'Billy Harris'},
        ],
        createdAt: 'Tue, 20 Apr 2021 14:31:25 UTC +00:00',
        body: 'Text\nOn a new line',
        htmlBody: 'Text\nOn a new line',
      },
      contextName: 'Fake Course 1',
    }

    const {container, getByText} = render(<MessageDetailItem {...props} />)

    expect(getByText('Tom Thompson')).toBeInTheDocument()
    expect(getByText(', Billy Harris')).toBeInTheDocument()
    // replaces \n with <br>
    expect(container.querySelector('br')).toBeInTheDocument()
    expect(getByText(/Text\s*On a new line/)).toBeInTheDocument()
    expect(getByText('Fake Course 1')).toBeInTheDocument()
    expect(getByText('Apr 20, 2021 at 2:31pm')).toBeInTheDocument()
  })

  it('shows attachment links if they exist', () => {
    const props = {
      conversationMessage: {
        author: {name: 'Tom Thompson', shortName: 'Tom Thompson'},
        recipients: [
          {name: 'Tom Thompson', shortName: 'Tom Thompson'},
          {name: 'Billy Harris', shortName: 'Billy Harris'},
        ],
        createdAt: 'Tue, 20 Apr 2021 14:31:25 UTC +00:00',
        body: 'This is the body text for the message.',
        htmlBody: 'This is the body text for the message.',
        attachments: [{id: '1', displayName: 'attachment1.jpeg', url: 'testingurl'}],
        // attachmentsConnection: {
        //   nodes: [{id: '1', displayName: 'attachment1.jpeg', url: 'testingurl'}],
        // },
      },
      contextName: 'Fake Course 1',
    }

    const {getByText} = render(<MessageDetailItem {...props} />)
    expect(getByText('attachment1.jpeg')).toBeInTheDocument()
  })

  it('shows media attachment link if it exists', () => {
    const props = {
      conversationMessage: {
        author: {name: 'Tom Thompson', shortName: 'Tom Thompson'},
        recipients: [
          {name: 'Tom Thompson', shortName: 'Tom Thompson'},
          {name: 'Billy Harris', shortName: 'Billy Harris'},
        ],
        createdAt: 'Tue, 20 Apr 2021 14:31:25 UTC +00:00',
        body: 'This is the body text for the message.',
        htmlBody: 'This is the body text for the message.',
        mediaComment: {
          _id: '123',
          title: 'Course Video',
          mediaSources: [
            {
              type: 'video',
              src: 'course-video-test',
              height: '800',
              width: '300',
            },
          ],
        },
      },
      contextName: 'Fake Course 1',
    }

    const {getByText} = render(<MessageDetailItem {...props} />)
    expect(getByText('Course Video')).toBeInTheDocument()
  })

  it('does not render the reply or reply all options when function is not provided', () => {
    const props = {
      conversationMessage: {
        author: {name: 'Tom Thompson', shortName: 'Tom Thompson'},
        recipients: [
          {name: 'Tom Thompson', shortName: 'Tom Thompson'},
          {name: 'Billy Harris', shortName: 'Billy Harris'},
        ],
        createdAt: 'Tue, 20 Apr 2021 14:31:25 UTC +00:00',
        body: 'This is the body text for the message.',
        htmlBody: 'This is the body text for the message.',
      },
      contextName: 'Fake Course 1',
      onReply: null,
      onReplyAll: null,
    }

    const {getByRole, queryByText, queryByTestId} = render(<MessageDetailItem {...props} />)

    const moreOptionsButton = getByRole(
      (role, element) =>
        role === 'button' && element.textContent === 'More options for message from Tom Thompson',
    )

    fireEvent.click(moreOptionsButton)
    expect(queryByText('Reply All')).not.toBeInTheDocument()
    expect(queryByTestId('message-reply')).not.toBeInTheDocument()
  })

  it('sends the selected option to the provided callback function', () => {
    const props = {
      conversationMessage: {
        author: {name: 'Tom Thompson', shortName: 'Tom Thompson'},
        recipients: [
          {name: 'Tom Thompson', shortName: 'Tom Thompson'},
          {name: 'Billy Harris', shortName: 'Billy Harris'},
        ],
        createdAt: 'Tue, 20 Apr 2021 14:31:25 UTC +00:00',
        body: 'This is the body text for the message.',
        htmlBody: 'This is the body text for the message.',
      },
      contextName: 'Fake Course 1',
      onReply: jest.fn(),
      onReplyAll: jest.fn(),
      onDelete: jest.fn(),
      onForward: jest.fn(),
    }

    const {getByTestId, getByText} = render(<MessageDetailItem {...props} />)

    const replyButton = getByTestId('message-reply')
    fireEvent.click(replyButton)
    expect(props.onReply).toHaveBeenCalled()

    const moreOptionsButton = getByTestId('message-more-options')
    fireEvent.click(moreOptionsButton)
    fireEvent.click(getByText('Reply All'))
    expect(props.onReplyAll).toHaveBeenCalled()

    fireEvent.click(moreOptionsButton)
    fireEvent.click(getByText('Delete'))
    expect(props.onDelete).toHaveBeenCalled()

    fireEvent.click(moreOptionsButton)
    fireEvent.click(getByText('Forward'))
    expect(props.onForward).toHaveBeenCalled()
  })

  describe('Pronouns', () => {
    describe('can_add_pronouns disabled', () => {
      it('do not show up pronouns', () => {
        const {queryByText} = setup()
        expect(queryByText('he/him')).not.toBeInTheDocument()
      })
    })
    describe('can_add_pronouns enabled', () => {
      beforeEach(() => {
        ENV = {
          SETTINGS: {
            can_add_pronouns: true,
          },
        }
      })

      it('Show up pronouns if pronouns is not null', () => {
        const {getByText} = setup()
        expect(getByText('he/him')).toBeInTheDocument()
      })

      it('Do not show up pronouns if pronouns is null', () => {
        const props = {
          conversationMessage: {
            author: {name: 'Tom Thompson', shortName: 'Tom Thompson', pronouns: null},
            recipients: [
              {name: 'Tom Thompson', shortName: 'Tom Thompson'},
              {name: 'Billy Harris', shortName: 'Billy Harris'},
            ],
            createdAt: 'Tue, 20 Apr 2021 14:31:25 UTC +00:00',
            body: 'This is the body text for the message.',
            htmlBody: 'This is the body text for the message.',
          },
          contextName: 'Fake Course 1',
        }
        const {queryByText} = setup(props)
        expect(queryByText('he/him')).not.toBeInTheDocument()
      })
    })
  })

  describe('Responsive', () => {
    describe('Mobile', () => {
      beforeEach(() => {
        responsiveQuerySizes.mockImplementation(() => ({
          mobile: {maxWidth: '67'},
        }))
      })

      it('Should emit correct Mobile Test Id', async () => {
        const {findByTestId} = setup()
        const item = await findByTestId('message-detail-item-mobile')
        expect(item).toBeTruthy()
      })
    })

    describe('Tablet', () => {
      beforeEach(() => {
        responsiveQuerySizes.mockImplementation(() => ({
          tablet: {maxWidth: '67'},
        }))
      })

      it('Should emit correct Tablet Test Id', async () => {
        const {findByTestId} = setup()
        const item = await findByTestId('message-detail-item-tablet')
        expect(item).toBeTruthy()
      })
    })

    describe('Desktop', () => {
      beforeEach(() => {
        responsiveQuerySizes.mockImplementation(() => ({
          desktop: {maxWidth: '67'},
        }))
      })

      it('Should emit correct Desktop Test Id', async () => {
        const {findByTestId} = setup()
        const item = await findByTestId('message-detail-item-desktop')
        expect(item).toBeTruthy()
      })
    })
  })
})
