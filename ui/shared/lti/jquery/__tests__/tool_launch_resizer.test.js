/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import ToolLaunchResizer from '../tool_launch_resizer'

describe('ToolLaunchResizer', () => {
  describe('#sanitizedWrapperId', () => {
    let wrapperId

    const subject = () => {
      const resizer = new ToolLaunchResizer()
      return resizer.sanitizedWrapperId(wrapperId)
    }

    describe('when the wrapperID is a UUID', () => {
      beforeEach(() => {
        wrapperId = 'b7dbe1ae-9a01-4acc-92c9-d4e226603de1'
      })

      it('allows all UUID characters', () => {
        expect(subject()).toEqual(wrapperId)
      })
    })

    describe('when the wrapperId contains non-UUID chars', () => {
      beforeEach(() => {
        /* eslint-disable-next-line no-template-curly-in-string */
        wrapperId = '<img src="x" onerror="alert(`${document.domain}_-`);" />'
      })

      it('removes the non-UUID chars', () => {
        expect(subject()).toEqual('imgsrcxonerroralertdocumentdomain_-')
      })
    })
  })

  describe('#tool_content_wrapper', () => {
    const sanitizeSpy = jest.fn()
    const wrapperId = 'foo'

    beforeEach(() => {
      sanitizeSpy.mockClear()
    })

    const subject = () => {
      const resizer = new ToolLaunchResizer()
      resizer.sanitizedWrapperId = sanitizeSpy
      return resizer
    }

    it('santizes the wrapperId', () => {
      subject().tool_content_wrapper(wrapperId)
      expect(sanitizeSpy).toHaveBeenCalledWith(wrapperId)
    })
  })
})
