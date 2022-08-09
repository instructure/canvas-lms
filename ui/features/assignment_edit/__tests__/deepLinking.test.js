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

import handleResponse from '../deepLinking'

describe('handles DeepLinking responses', () => {
  const oldEnv = window.ENV
  let html_elements

  beforeAll(() => {
    window.ENV = {
      DEEP_LINKING_POST_MESSAGE_ORIGIN: 'https://www.test.com'
    }
    mockEditViewElements()
    loadSelectors()
  })

  afterAll(() => {
    window.ENV = oldEnv
  })

  beforeEach(() => {
    clearSelectorValues()
  })

  function mockEditViewElements() {
    const content_tag_attributes = {
      '[content_id]': 'assignment_external_tool_tag_attributes_content_id',
      '[content_type]': 'assignment_external_tool_tag_attributes_content_type',
      '[url]': 'assignment_external_tool_tag_attributes_url',
      '[new_tab]': 'assignment_external_tool_tag_attributes_new_tab',
      '[custom_params]': 'assignment_external_tool_tag_attributes_custom_params',
      '[link_settings][selection_width]': 'assignment_external_tool_tag_attributes_iframe_width',
      '[link_settings][selection_height]': 'assignment_external_tool_tag_attributes_iframe_height'
    }

    for (const [attribute, html_id] of Object.entries(content_tag_attributes)) {
      const element = document.createElement('input')
      element.setAttribute('id', html_id)
      element.setAttribute('name', 'external_tool_tag_attributes' + attribute)
      document.body.append(element)
    }

    const span = document.createElement('span')
    span.setAttribute('data-cid', 'CloseButton')
    span.appendChild(document.createElement('button'))

    const modal_header = document.createElement('div')
    modal_header.setAttribute('data-cid', 'ModalHeader')
    modal_header.appendChild(span)

    const modal = document.createElement('span')
    modal.setAttribute('data-cid', 'Modal')
    modal.appendChild(modal_header)

    document.body.append(modal)
  }

  function loadSelectors() {
    html_elements = {
      id: document.querySelector("input[name='external_tool_tag_attributes[content_id]']"),
      type: document.querySelector("input[name='external_tool_tag_attributes[content_type]']"),
      url: document.querySelector("input[name='external_tool_tag_attributes[url]']"),
      new_tab: document.querySelector("input[name='external_tool_tag_attributes[new_tab]']"),
      custom_params: document.querySelector(
        "input[name='external_tool_tag_attributes[custom_params]']"
      ),
      width: document.querySelector(
        "input[name='external_tool_tag_attributes[link_settings][selection_width]']"
      ),
      height: document.querySelector(
        "input[name='external_tool_tag_attributes[link_settings][selection_height]']"
      )
    }
  }

  function clearSelectorValues() {
    Object.values(html_elements).forEach(element => {
      element?.removeAttribute('value')
    })
  }

  function event(overrides) {
    return {
      origin: 'https://www.test.com',
      data: {
        subject: 'LtiDeepLinkingResponse',
        reloadpage: false,
        content_items: [
          {
            id: '123',
            type: 'ltiResourceLink',
            url: 'http://lti13testtool.docker/launch?deep_link_location=xyz',
            title: 'Lti 1.3 Tool Title',
            text: 'Lti 1.3 Tool Text',
            new_tab: '0',
            custom: {
              RootAccountId: '$Canvas.rootAccount.id',
              ExternalToolGlobalId: '$Canvas.externalTool.global_id',
              ShardId: '$Canvas.shard.id'
            }
          }
        ],
        ltiEndpoint: 'http://canvas.docker/courses/1/external_tools/retrieve'
      },
      ...overrides
    }
  }

  describe('when receiving LtiResourceLink attributes', () => {
    it('set the content_id attribute', () => {
      handleResponse(event())
      expect(html_elements.id.value).toBe('123')
    })

    it('set the content_type attribute', () => {
      handleResponse(event())
      expect(html_elements.type.value).toBe('ltiResourceLink')
    })

    it('set the url attribute', () => {
      handleResponse(event())
      expect(html_elements.url.value).toBe(
        'http://lti13testtool.docker/launch?deep_link_location=xyz'
      )
    })

    describe('set the new_tab attribute', () => {
      it('when the received new_tab value is not "1" do not check the checkbox', () => {
        handleResponse(event())
        expect(html_elements.new_tab.checked).toBe(false)
        expect(html_elements.new_tab.getAttribute('checked')).toBe(null)
      })

      it('when the received new_tab value is "1" check the checkbox', () => {
        const opt = {
          data: {
            content_items: [
              {
                id: '123',
                type: 'ltiResourceLink',
                url: 'http://lti13testtool.docker/launch?deep_link_location=xyz',
                title: 'Lti 1.3 Tool Title',
                text: 'Lti 1.3 Tool Text',
                new_tab: '1',
                custom: ''
              }
            ],
            ltiEndpoint: 'http://canvas.docker/courses/1/external_tools/retrieve'
          }
        }
        handleResponse(event(opt))
        expect(html_elements.new_tab.checked).toBe(true)
        expect(html_elements.new_tab.getAttribute('checked')).toBe('checked')
      })
    })

    it('set the custom_params attribute', () => {
      handleResponse(event())
      expect(html_elements.custom_params.value).toBe(
        '{"RootAccountId":"$Canvas.rootAccount.id","ExternalToolGlobalId":"$Canvas.externalTool.global_id","ShardId":"$Canvas.shard.id"}'
      )
    })

    it('do not set default values for width and height', () => {
      handleResponse(event())

      expect(html_elements.width.value).toBe('')
      expect(html_elements.height.value).toBe('')
    })

    describe('when receiving iframe dimensions', () => {
      it('sets iframe width and height', () => {
        const opts = {
          data: {
            content_items: [
              {
                type: 'ltiResourceLink',
                url: 'http://lti13testtool.docker/launch?deep_link_location=xyz',
                title: 'Lti 1.3 Tool Title',
                text: 'Lti 1.3 Tool Text',
                iframe: {
                  width: 345,
                  height: 678
                }
              }
            ]
          }
        }
        handleResponse(event(opts))

        expect(html_elements.width.value).toBe('345')
        expect(html_elements.height.value).toBe('678')
      })

      it('sets iframe width', () => {
        const opts = {
          data: {
            content_items: [
              {
                type: 'ltiResourceLink',
                url: 'http://lti13testtool.docker/launch?deep_link_location=xyz',
                title: 'Lti 1.3 Tool Title',
                text: 'Lti 1.3 Tool Text',
                iframe: {
                  width: 345
                }
              }
            ]
          }
        }
        handleResponse(event(opts))

        expect(html_elements.width.value).toBe('345')
        expect(html_elements.height.value).toBe('')
      })

      it('sets iframe height', () => {
        const opts = {
          data: {
            content_items: [
              {
                type: 'ltiResourceLink',
                url: 'http://lti13testtool.docker/launch?deep_link_location=xyz',
                title: 'Lti 1.3 Tool Title',
                text: 'Lti 1.3 Tool Text',
                iframe: {
                  height: 678
                }
              }
            ]
          }
        }
        handleResponse(event(opts))

        expect(html_elements.width.value).toBe('')
        expect(html_elements.height.value).toBe('678')
      })
    })
  })
})
