/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import Helper from '../context_modules_helper'

describe('ContextModulesHelper', () => {
  beforeEach(() => {
    jest.spyOn(Helper, 'setWindowLocation').mockImplementation(() => {})
  })

  afterEach(() => {
    Helper.setWindowLocation.mockRestore()
  })

  test('externalUrlLinkClick', () => {
    const event = {
      preventDefault: jest.fn(),
    }
    const elt = {
      attr: jest.fn().mockReturnValue('http://example.com'),
    }
    Helper.externalUrlLinkClick(event, elt)
    expect(event.preventDefault).toHaveBeenCalledTimes(1)
    expect(elt.attr).toHaveBeenCalledWith('data-item-href')
    expect(Helper.setWindowLocation).toHaveBeenCalledWith('http://example.com')
  })

  test('externalUrlLinkClick sanitizeUrl', () => {
    const event = {
      preventDefault: jest.fn(),
    }
    const elt = {
      // eslint-disable-next-line no-script-url
      attr: jest.fn().mockReturnValue('javascript:alert("hi")'),
    }
    Helper.externalUrlLinkClick(event, elt)
    expect(event.preventDefault).toHaveBeenCalledTimes(1)
    expect(Helper.setWindowLocation).toHaveBeenCalledWith('about:blank')
  })
})
