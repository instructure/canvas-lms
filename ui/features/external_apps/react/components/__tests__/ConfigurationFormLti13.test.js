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

/**
 * @todo Convert this to react-testing-library and Typescript. See ConfigurationForm.test.tsx
 * for prior art.
 */
import React from 'react'
import {mount} from 'enzyme'
import ConfigurationFormLti13 from '../configuration_forms/ConfigurationFormLti13'

let wrapper

beforeEach(() => {
  wrapper = mount(<ConfigurationFormLti13 />)
})

afterEach(() => {
  wrapper.unmount()
})

describe('isValid', () => {
  describe('when the client id input is empty', () => {
    it('returns false', () => {
      expect(wrapper.instance().isValid()).toEqual(false)
    })
  })

  describe('when the client id input is not empty', () => {
    beforeEach(() => {
      wrapper.instance().setState({
        clientId: '100000005',
      })
    })

    it('returns true', () => {
      expect(wrapper.instance().isValid()).toEqual(true)
    })
  })
})

describe('getFormData', () => {
  describe('when the client id input is empty', () => {
    it('returns an object with empty client_id', () => {
      expect(wrapper.instance().getFormData()).toEqual({client_id: ''})
    })
  })

  describe('when the client id input is not empty', () => {
    const clientId = '100000000005'

    beforeEach(() => {
      wrapper.instance().setState({
        clientId,
      })
    })

    it('returns an object with the client_id', () => {
      expect(wrapper.instance().getFormData()).toEqual({client_id: clientId})
    })
  })
})
