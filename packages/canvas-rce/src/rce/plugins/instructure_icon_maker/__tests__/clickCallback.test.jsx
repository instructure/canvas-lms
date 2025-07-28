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

import clickCallback, {ICONS_TRAY_CONTAINER_ID} from '../clickCallback'
import FakeEditor from '../../../__tests__/FakeEditor'
import {waitFor} from '@testing-library/dom'
import {act} from '@testing-library/react'

describe('clickCallback()', () => {
  const subject = type => clickCallback(new FakeEditor(), document, type)

  describe('when the container does not exist', () => {
    beforeEach(() => (document.body.innerHTML = ''))

    it('creates the container', async () => {
      await act(async () => {
        subject('create_icon_maker_icon')
      })

      await waitFor(() => {
        expect(document.getElementById(ICONS_TRAY_CONTAINER_ID)).toBeTruthy()
      })
    })

    it('mounts the component', async () => {
      await act(async () => {
        subject('create_icon_maker_icon')
      })

      await waitFor(() => {
        expect(document.querySelector('[data-testid="icon-name"]')).toBeTruthy()
      })
    })
  })

  describe('when the container exists', () => {
    beforeEach(async () => {
      await act(async () => {
        subject('edit_icon_maker_icon')
      })

      await waitFor(() => {
        expect(document.querySelector('[data-testid="icon-name"]')).toBeTruthy()
      })
    })

    it('re-mounts the component', async () => {
      await act(async () => {
        subject('create_icon_maker_icon')
      })

      await waitFor(() => {
        expect(document.querySelector('[data-testid="icon-name"]')).toBeTruthy()
      })
    })
  })
})
