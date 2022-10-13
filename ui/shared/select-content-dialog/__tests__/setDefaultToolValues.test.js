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

import setDefaultToolValues from '../setDefaultToolValues'

describe('setDefaultToolValues', () => {
  const definition_type = 'ContextExternalTool'
  const definition_id = '22'
  const tool = {
    definition_type,
    definition_id,
  }

  const url = 'https://www.test-tool.com/lti_launch'
  const result = {
    url,
  }

  const postMessageOrigin = window.ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN

  beforeAll(() => {
    window.ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = 'canvas.instructure.com'
  })

  beforeEach(() => {
    document.body.innerHTML =
      '<input id="assignment_external_tool_tag_attributes_content_type" type="hidden"/>' +
      '<input id="assignment_external_tool_tag_attributes_content_id" type="hidden"/>' +
      '<input id="assignment_external_tool_tag_attributes_url" type="hidden"/>' +
      '<input id="assignment_external_tool_tag_attributes_iframe_height" type="hidden" value="888"/>' +
      '<input id="assignment_external_tool_tag_attributes_iframe_width" type="hidden" value="999"/>'

    window.postMessage = jest.fn()

    setDefaultToolValues(result, tool)
  })

  afterEach(() => {
    window.postMessage.mockReset()
  })

  afterAll(() => {
    window.ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = postMessageOrigin
    window.postMessage.mockRestore()
  })

  it('sends a postMessage to the window with results', () => {
    expect(window.postMessage).toHaveBeenCalledWith(
      {
        subject: 'defaultToolContentReady',
        content: result,
      },
      'canvas.instructure.com'
    )
  })

  it('sets the definition type', () => {
    expect(
      document.querySelector('#assignment_external_tool_tag_attributes_content_type').value
    ).toEqual(definition_type)
  })

  it('sets the definition id', () => {
    expect(
      document.querySelector('#assignment_external_tool_tag_attributes_content_id').value
    ).toEqual(definition_id)
  })

  it('sets the tool URL', () => {
    expect(document.querySelector('#assignment_external_tool_tag_attributes_url').value).toEqual(
      url
    )
  })

  it('sets the iframe width', () => {
    expect(
      document.querySelector('#assignment_external_tool_tag_attributes_iframe_width').value
    ).toEqual('')
  })

  it('sets the iframe height', () => {
    expect(
      document.querySelector('#assignment_external_tool_tag_attributes_iframe_height').value
    ).toEqual('')
  })
})
