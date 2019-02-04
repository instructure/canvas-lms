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
import {fireEvent} from 'react-testing-library'
import {ConnectedSecurityPanel} from '../SecurityPanel'
import {renderWithRedux} from './utils'

describe('ConnectedSecurityPanel', () => {
  it('updates CSP enabled status when the checkbox is clicked', () => {
    const {getByLabelText} = renderWithRedux(
      <ConnectedSecurityPanel context="account" contextId="1" />
    )

    const checkbox = getByLabelText('Enable Content Security Policy')
    fireEvent.click(checkbox)
    expect(checkbox.checked).toBeTruthy()
  })

  describe('isSubAccount prop', () => {
    it('updates CSP inherited status when the inherit checkbox is clicked', () => {
      const {getByLabelText} = renderWithRedux(
        <ConnectedSecurityPanel context="account" contextId="1" isSubAccount />
      )

      const checkbox = getByLabelText('Inherit Content Security Policy')
      fireEvent.click(checkbox)
      expect(checkbox.checked).toBeTruthy()
    })

    it('disables the enable checkbox when the inherit option is set to true', () => {
      const {getByLabelText} = renderWithRedux(
        <ConnectedSecurityPanel context="account" contextId="1" isSubAccount />
      )

      const checkbox = getByLabelText('Inherit Content Security Policy')
      fireEvent.click(checkbox)
      expect(checkbox.checked).toBeTruthy()

      const enableCheckbox = getByLabelText('Enable Content Security Policy')
      expect(enableCheckbox).toBeDisabled()
    })
  })
})
