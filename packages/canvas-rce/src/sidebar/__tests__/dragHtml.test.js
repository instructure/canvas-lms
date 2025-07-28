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

import dragHtml from '../dragHtml'
import * as browser from '../../common/browser'

jest.mock('../../common/browser')

describe('dragHtml', () => {
  let ev
  const html = '<div>test content</div>'

  beforeEach(() => {
    browser.edge.mockReturnValue(false)
    browser.ie.mockReturnValue(false)

    ev = {
      dataTransfer: {
        setData: jest.fn(),
        items: {
          clear: jest.fn(),
        },
      },
    }
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('in standard browsers', () => {
    it('sets text/html data with raw html', () => {
      dragHtml(ev, html)
      expect(ev.dataTransfer.setData).toHaveBeenCalledWith('text/html', html)
    })

    it('does not clear dataTransfer items', () => {
      dragHtml(ev, html)
      expect(ev.dataTransfer.items.clear).not.toHaveBeenCalled()
    })
  })

  describe('in MS Edge', () => {
    beforeEach(() => {
      browser.edge.mockReturnValue(true)
    })

    it('sets text/html data with raw html', () => {
      dragHtml(ev, html)
      expect(ev.dataTransfer.setData).toHaveBeenCalledWith('text/html', html)
    })

    it('clears dataTransfer items', () => {
      dragHtml(ev, html)
      expect(ev.dataTransfer.items.clear).toHaveBeenCalled()
    })
  })

  describe('in Internet Explorer', () => {
    beforeEach(() => {
      browser.ie.mockReturnValue(true)
    })

    it('sets Text data with encoded html', () => {
      dragHtml(ev, html)
      expect(ev.dataTransfer.setData).toHaveBeenCalledWith(
        'Text',
        `data:text/mce-internal,rcs-sidebar,${escape(html)}`,
      )
    })

    it('does not clear dataTransfer items', () => {
      dragHtml(ev, html)
      expect(ev.dataTransfer.items.clear).not.toHaveBeenCalled()
    })
  })
})
