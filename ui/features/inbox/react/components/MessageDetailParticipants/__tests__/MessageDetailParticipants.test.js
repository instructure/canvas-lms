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

import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import {MessageDetailParticipants} from '../MessageDetailParticipants'

import {PARTICIPANT_EXPANSION_THRESHOLD} from '../../../../util/constants'

describe('MessageDetailParticipants', () => {
  it('renders with provided data', () => {
    const props = {
      conversationMessage: {
        author: {name: 'Tom Thompson'},
        recipients: [{name: 'Tom Thompson'}, {name: 'Billy Harris'}]
      }
    }

    const {getByText} = render(<MessageDetailParticipants {...props} />)

    expect(getByText('Tom Thompson')).toBeInTheDocument()
    expect(getByText(', Billy Harris')).toBeInTheDocument()
  })
  it('renders without trailing comma if there are no participants', () => {
    const participantList = []
    const props = {
      conversationMessage: {
        author: {name: 'Tom Thompson'},
        recipients: participantList
      }
    }
    const container = render(<MessageDetailParticipants {...props} />)
    expect(container.queryByTestId('participant-list')).not.toBeInTheDocument()
  })

  it('renders with limited list until expanded', () => {
    const participantList = [
      {name: 'Bob Barker'},
      {name: 'Sally Ford'},
      {name: 'Russel Franks'},
      {name: 'Dipali Vega'},
      {name: 'Arlet Tuân'},
      {name: 'Tshepo Jehoiachin'},
      {name: 'Ráichéal Mairead'},
      {name: 'Renāte Tarik'},
      {name: "Jocelin 'Avshalom"},
      {name: 'Marisa Ninurta'},
      {name: 'Régine Teige'},
      {name: 'Norman Iustina'},
      {name: 'Ursula Siddharth'},
      {name: 'Cristoforo Gülnarə'},
      {name: 'Katka Lauge'},
      {name: 'Sofia Fernanda'},
      {name: 'Orestes Etheldreda'}
    ]
    const props = {
      conversationMessage: {
        author: {name: 'Tom Thompson'},
        recipients: participantList
      }
    }

    const container = render(<MessageDetailParticipants {...props} />)

    expect(
      container.queryByText(
        `, ${participantList
          .map(person => person.name)
          .slice(0, PARTICIPANT_EXPANSION_THRESHOLD)
          .join(', ')}`
      )
    ).toBeInTheDocument()
    expect(
      container.queryByText(`, ${participantList.map(person => person.name).join(', ')}`)
    ).toBeNull()
    const expandBtn = container.getByTestId('expand-participants-button')
    fireEvent.click(expandBtn)
    expect(
      container.getByText(`, ${participantList.map(person => person.name).join(', ')}`)
    ).toBeInTheDocument()
  })
})
