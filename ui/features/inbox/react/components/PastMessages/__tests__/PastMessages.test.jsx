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

import DateHelper from '@canvas/datetime/dateHelper'
import React from 'react'
import {render} from '@testing-library/react'
import {PastMessages} from '../PastMessages'

describe('PastMessages', () => {
  it('renders past messages', () => {
    const props = {
      messages: [
        {
          author: {
            name: 'Gandalf',
          },
          body: "No. No, it isn't",
          createdAt: 'TA 3019',
        },
        {
          author: {
            name: 'Pippin',
          },
          body: "Well, that isn't so bad.",
          createdAt: 'TA 3019',
        },
        {
          author: {
            name: 'Gandalf',
          },
          body: 'White shores, and beyond, a far green country under a swift sunrise.',
          createdAt: 'TA 3019',
        },
        {
          author: {
            name: 'Pippin',
          },
          body: 'What? Gandalf? See what?',
          createdAt: 'TA 3019',
        },
        {
          author: {
            name: 'Gandalf',
          },
          body: "End? No, the journey doesn't end here. Death is just another path, one that we all must take. The grey rain-curtain of this world rolls back, and all turns to silver glass, and then you see it.",
          createdAt: 'TA 3019',
        },
        {
          author: {
            name: 'Pippin',
          },
          body: "I didn't think it would end this way.",
          createdAt: 'TA 3019',
        },
      ],
    }

    const {getAllByText, getByText} = render(<PastMessages {...props} />)

    props.messages.forEach(message => {
      const expectedDate = DateHelper.formatDatetimeForDiscussions(message.createdAt)

      expect(getAllByText(message.author.name).length > 0).toBe(true)
      expect(getByText(message.body)).toBeInTheDocument()
      expect(getAllByText(expectedDate).length > 0).toBe(true)
    })
  })
})
