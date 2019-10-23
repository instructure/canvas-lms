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

function renderSendToDialog(learningObject = {}, propsOverride = {}) {
  return render()
}

describe('DirectShareSendToDialog', () => {
  describe('dialog controls', () => {
    it('closes the dialog when X is clicked', () => {})
    it('closes the dialog when cancel button is clicked', () => {})
  })
  describe('share with', () => {
    it('populates the list of users in dropdwon', () => {})
    it('filters the users based on search input', () => {})
    it('filters the users when search returns empty', () => {})
    it('adds recipients to final list', () => {})
    it('allows removal of recipient from final list', () => {})
  })
  describe('share button', () => {
    it('is enabled when a recipient is selected', () => {})
    it('is diabled when no recipient is selected', () => {})
  })
  describe('sharing content', () => {
    it('displays loading state when message is beng sent', () => {})
    it('displays success and closes the dialog when the api call succeeds', async () => {})
    it('displays an error on the dialog', async () => {})
  })
})
