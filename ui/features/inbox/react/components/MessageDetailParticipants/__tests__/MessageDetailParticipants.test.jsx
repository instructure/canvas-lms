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
        author: {name: 'Tom Thompson', shortName: 'Tom Thompson'},
        recipients: [
          {name: 'Tom Thompson', shortName: 'Tom Thompson'},
          {name: 'Billy Harris', shortName: 'Billy Harris'},
        ],
      },
    }

    const {getByText} = render(<MessageDetailParticipants {...props} />)

    expect(getByText('Tom Thompson')).toBeInTheDocument()
    expect(getByText(', Billy Harris')).toBeInTheDocument()
  })
  it('renders without trailing comma if there are no participants', () => {
    const participantList = []
    const props = {
      conversationMessage: {
        author: {name: 'Tom Thompson', shortName: 'Tom Thompson'},
        recipients: participantList,
      },
    }
    const container = render(<MessageDetailParticipants {...props} />)
    expect(container.queryByTestId('participant-list')).not.toBeInTheDocument()
  })

  it('renders with limited list until expanded', () => {
    const participantList = [
      {name: 'Bob Barker', shortName: 'Bob Barker'},
      {name: 'Sally Ford', shortName: 'Sally Ford'},
      {name: 'Russel Franks', shortName: 'Russel Franks'},
      {name: 'Dipali Vega', shortName: 'Dipali Vega'},
      {name: 'Arlet Tuân', shortName: 'Arlet Tuân'},
      {name: 'Tshepo Jehoiachin', shortName: 'Tshepo Jehoiachin'},
      {name: 'Ráichéal Mairead', shortName: 'Ráichéal Mairead'},
      {name: 'Renāte Tarik', shortName: 'Renāte Tarik'},
      {name: "Jocelin 'Avshalom", shortName: "Jocelin 'Avshalom"},
      {name: 'Marisa Ninurta', shortName: 'Marisa Ninurta'},
      {name: 'Régine Teige', shortName: 'Régine Teige'},
      {name: 'Norman Iustina', shortName: 'Norman Iustina'},
      {name: 'Ursula Siddharth', shortName: 'Ursula Siddharth'},
      {name: 'Cristoforo Gülnarə', shortName: 'Cristoforo Gülnarə'},
      {name: 'Katka Lauge', shortName: 'Katka Lauge'},
      {name: 'Sofia Fernanda', shortName: 'Sofia Fernanda'},
      {name: 'Orestes Etheldreda', shortName: 'Orestes Etheldreda'},
    ]
    const props = {
      conversationMessage: {
        author: {name: 'Tom Thompson', shortName: 'Tom Thompson'},
        recipients: participantList,
      },
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
