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

import HtmlFragmentContentItem from '../HtmlFragmentContentItem'
import {HtmlFragmentContentItemJson} from '../../Lti13ContentItemJson'

const json: HtmlFragmentContentItemJson & {invalidProp: string} = {
  type: 'html',
  title: 'Title',
  text: 'some text',
  invalidProp: 'banana',
  html: '<a href="test.com">link</a><p><strong>bold</strong></p>',
}

function htmlContentItem(overrides: Partial<HtmlFragmentContentItemJson> = {}) {
  const mergedJson = {...json, ...overrides}
  return new HtmlFragmentContentItem(mergedJson, {
    containingCanvasLtiToolId: null,
    ltiEndpoint: null,
    selection: null,
    ltiIframeAllowPolicy: null,
  })
}

describe('constructor', () => {
  it('sets the "type"', () => {
    expect(htmlContentItem().type).toEqual('html')
  })
})

describe('toHtmlString', () => {
  it('returns the "html"', () => {
    expect(htmlContentItem().toHtmlString()).toEqual(
      '<a href="test.com">link</a><p><strong>bold</strong></p>'
    )
  })
})
