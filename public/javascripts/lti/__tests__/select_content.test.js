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

import SelectContent from '../select_content'

describe('isContentMessage', () => {
  it('returns true if placements includes "resource_selection"', () => {
    expect(
      SelectContent.isContentMessage({message_type: ''}, {resource_selection: {}})
    ).toBeTruthy()
  })

  it('returns true if message type includes "ContentItemSelectionRequest"', () => {
    expect(
      SelectContent.isContentMessage({message_type: 'ContentItemSelectionRequest'})
    ).toBeTruthy()
  })

  it('returns true if message type includes "LtiDeepLinkingRequest"', () => {
    expect(SelectContent.isContentMessage({message_type: 'LtiDeepLinkingRequest'})).toBeTruthy()
  })

  it('returns false if no content placements or message types are present', () => {
    expect(
      SelectContent.isContentMessage(
        {message_type: 'ResourceLinkRequest'},
        {assignment_selection: {}}
      )
    ).toBeFalsy()
  })

  it('returns false if placement is undefined', () => {
    expect(SelectContent.isContentMessage(undefined)).toBeFalsy()
  })
})

describe('errorForUrlItem', () => {
  describe('when the item does not have a url', () => {
    it('returns an error describing the absence of a URL', () => {
      expect(SelectContent.errorForUrlItem({'@type': 'LtiLinkItem'})).toEqual(
        'Error: The tool did not return a URL to Canvas'
      )
    })
  })

  describe('when the item does not have the expected type', () => {
    it('returns an error describing the invalid message type', () => {
      expect(
        SelectContent.errorForUrlItem({'@type': 'InvalidType', url: 'http://www.test.com'})
      ).toEqual('Error: The tool returned an invalid content type "InvalidType"')
    })
  })

  describe('when the item does not have a recognized error', () => {
    it('returns a generic error message', () => {
      expect(
        SelectContent.errorForUrlItem({'@type': 'LtiLinkItem', url: 'http://www.test.com'})
      ).toEqual('Error embedding content from tool')
    })
  })
})
