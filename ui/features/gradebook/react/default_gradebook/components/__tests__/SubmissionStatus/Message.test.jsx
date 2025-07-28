/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {Text} from '@instructure/ui-text'
import {IconWarningLine, IconInfoLine} from '@instructure/ui-icons'
import Message from '../../SubmissionStatus/Message'

describe('Message', () => {
  describe('variant warning', () => {
    test('includes IconWarningLine with message', () => {
      const message = 'Some Message'
      const {container, getByText} = render(<Message variant="warning" message={message} />)
      // Check for warning icon - it should be present in the DOM
      const warningIcon =
        container.querySelector('svg[name*="Warning"]') ||
        container.querySelector('[data-testid="warning-icon"]')
      expect(warningIcon).toBeInTheDocument()
      expect(getByText(message)).toBeInTheDocument()
    })

    test('includes a text message', () => {
      const message = 'Some Message'
      const {getByText} = render(<Message variant="warning" message={message} />)
      const textElement = getByText(message)
      expect(textElement).toBeInTheDocument()
    })
  })

  describe('variant info', () => {
    test('includes IconInfoLine with message', () => {
      const message = 'Some Message'
      const {container, getByText} = render(<Message variant="info" message={message} />)
      // Check for info icon - it should be present in the DOM
      const infoIcon =
        container.querySelector('svg[name*="Info"]') ||
        container.querySelector('[data-testid="info-icon"]')
      expect(infoIcon).toBeInTheDocument()
      expect(getByText(message)).toBeInTheDocument()
    })

    test('includes a text message', () => {
      const message = 'Some Message'
      const {getByText} = render(<Message variant="info" message={message} />)
      const textElement = getByText(message)
      expect(textElement).toBeInTheDocument()
    })
  })
})
