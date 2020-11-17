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

import React from 'react'
import {render} from '@testing-library/react'
import {PastMessages} from '../PastMessages'

describe('PastMessages', () => {
  it('renders past messages', () => {
    const props = {
      messages: [
        {
          name: 'Gandalf',
          messageBody: "No. No, it isn't",
          date: 'TA 3019'
        },
        {
          name: 'Pippin',
          messageBody: "Well, that isn't so bad.",
          date: 'TA 3019'
        },
        {
          name: 'Gandalf',
          messageBody: 'White shores, and beyond, a far green country under a swift sunrise.',
          date: 'TA 3019'
        },
        {
          name: 'Pippin',
          messageBody: 'What? Gandalf? See what?',
          date: 'TA 3019'
        },
        {
          name: 'Gandalf',
          messageBody:
            "End? No, the journey doesn't end here. Death is just another path, one that we all must take. The grey rain-curtain of this world rolls back, and all turns to silver glass, and then you see it.",
          date: 'TA 3019'
        },
        {
          name: 'Pippin',
          messageBody: "I didn't think it would end this way.",
          date: 'TA 3019'
        }
      ]
    }

    const {getAllByText, getByText} = render(<PastMessages {...props} />)

    props.messages.forEach(message => {
      expect(getAllByText(message.name).length > 0).toBe(true)
      expect(getByText(message.messageBody)).toBeInTheDocument()
      expect(getAllByText(message.date).length > 0).toBe(true)
    })
  })
})
