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
import AnonymousSpeedGraderAlert from '../AnonymousSpeedGraderAlert'
import {createGradebook} from '../../__tests__/GradebookSpecHelper'

jest.mock('../AnonymousSpeedGraderAlert', () => {
  const mockComponent = jest.fn(props => {
    return {
      render: () => (
        <div role="dialog" data-testid="anonymous-speed-grader-alert">
          <span>SpeedGrader URL: {props.speedGraderUrl}</span>
          <button onClick={props.onClose}>Close</button>
        </div>
      ),
      open: jest.fn(),
    }
  })
  return {
    __esModule: true,
    default: mockComponent,
  }
})

jest.mock('react-dom', () => ({
  ...jest.requireActual('react-dom'),
  render: jest.fn(element => element.type(element.props)),
}))

describe('Gradebook > renderAnonymousSpeedGraderAlert', () => {
  let gradebook
  const onClose = jest.fn()
  const alertProps = {
    speedGraderUrl: 'http://test.url:3000',
    onClose,
  }

  beforeEach(() => {
    gradebook = createGradebook()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the AnonymousSpeedGraderAlert component', () => {
    gradebook.renderAnonymousSpeedGraderAlert(alertProps)
    expect(AnonymousSpeedGraderAlert).toHaveBeenCalled()
  })

  it('passes speedGraderUrl to the modal as a prop', () => {
    gradebook.renderAnonymousSpeedGraderAlert(alertProps)
    expect(AnonymousSpeedGraderAlert).toHaveBeenCalledWith({
      speedGraderUrl: 'http://test.url:3000',
      onClose,
    })
  })

  it('passes onClose to the modal as a prop', () => {
    gradebook.renderAnonymousSpeedGraderAlert(alertProps)
    expect(AnonymousSpeedGraderAlert).toHaveBeenCalledWith({
      speedGraderUrl: 'http://test.url:3000',
      onClose,
    })
  })
})

describe('Gradebook > showAnonymousSpeedGraderAlertForURL', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
    jest.spyOn(gradebook, 'renderAnonymousSpeedGraderAlert')
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the alert with the supplied speedGraderURL', () => {
    gradebook.showAnonymousSpeedGraderAlertForURL('http://test.url:3000')
    expect(gradebook.renderAnonymousSpeedGraderAlert).toHaveBeenCalledWith(
      expect.objectContaining({
        speedGraderUrl: 'http://test.url:3000',
      }),
    )
  })
})
