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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ConfigurationFormLti13 from '../configuration_forms/ConfigurationFormLti13'

describe('ConfigurationFormLti13', () => {
  beforeEach(() => {
    userEvent.setup()
  })

  describe('isValid', () => {
    it('returns false when the client id input is empty', () => {
      const ref = React.createRef<ConfigurationFormLti13>()
      render(<ConfigurationFormLti13 ref={ref} />)
      expect(ref.current!.isValid()).toEqual(false)
    })

    it("returns true when the client id input isn't empty", async () => {
      const ref = React.createRef<ConfigurationFormLti13>()
      render(<ConfigurationFormLti13 ref={ref} />)
      await userEvent.type(screen.getByRole('textbox'), '100000005')
      expect(ref.current!.isValid()).toEqual(true)
    })
  })

  describe('getFormData', () => {
    it('returns an object with empty client_id when the client id input is empty', () => {
      const ref = React.createRef<ConfigurationFormLti13>()
      render(<ConfigurationFormLti13 ref={ref} />)
      expect(ref.current!.getFormData()).toEqual({client_id: ''})
    })

    it("returns an object with the client_id when the client id input isn't empty", async () => {
      const ref = React.createRef<ConfigurationFormLti13>()
      render(<ConfigurationFormLti13 ref={ref} />)
      await userEvent.type(screen.getByRole('textbox', {name: /Client ID/i}), '100000005')
      expect(ref.current!.getFormData()).toEqual({client_id: '100000005'})
    })
  })
})
