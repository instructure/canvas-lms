/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import TextEntry from '../TextEntry'

describe('TextEntry', () => {
  describe('when the value prop is null', () => {
    it('renders a Start Entry item', () => {
      const {getByText} = render(<TextEntry value={null} />)

      expect(getByText('Start Entry')).toBeInTheDocument()
    })
  })

  describe('when the value prop is not null', () => {
    it('renders the RCE when the initial value is not null', () => {
      const {getByTestId} = render(<TextEntry value="something" />)

      expect(getByTestId('text-editor')).toBeInTheDocument()
    })

    it('renders the Cancel button when the RCE is loaded', () => {
      const {getByTestId, getByText} = render(<TextEntry value="sometext" />)
      const cancelButton = getByTestId('cancel-text-entry')

      expect(cancelButton).toContainElement(getByText('Cancel'))
    })

    it('renders the Save button when the RCE is loaded', () => {
      const {getByTestId, getByText} = render(<TextEntry value="sometext" />)
      const saveButton = getByTestId('save-text-entry')

      expect(saveButton).toContainElement(getByText('Save'))
    })
  })
})
