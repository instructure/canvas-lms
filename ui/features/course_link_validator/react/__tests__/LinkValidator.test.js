/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {act} from 'react-dom/test-utils'
import {mount,render} from 'enzyme'
import LinkValidator from '../LinkValidator'
import sinon from 'sinon'
import $ from 'jquery'

jest.useFakeTimers()
// TODO: perhaps hoist mocks to ui/shared/jest-mocks ?
jest.genMockFromModule('@canvas/confetti/react/__mocks__/confetti-js')

describe('LinkValidator', () => {
  describe('confetti', () => {
    describe('with no invalid links', () => {
      let env, sandbox
      beforeEach(() => {
        env = window.ENV
        sandbox = sinon.createSandbox()
        window.ENV = {
          validation_api_url: '/foo/bar',
          VALIDATION_CONFETTI_ENABLED: true
        }
        sandbox.stub($, 'ajax').callsFake(params =>
          params.success({
            workflow_state: 'completed',
            results: {
              version: 2,
              issues: []
            }
          })
        )
      })

      afterEach(() => {
        window.ENV = env
        sandbox.restore()
      })

      it('renders confetti', () => {
        const wrapper = mount(<LinkValidator />)
        const promise = new Promise(resolve => {
          setTimeout(resolve, 1)
        })
        act(() => {
          wrapper.find('button').simulate('click')
          jest.advanceTimersByTime(2000)
        })
        return promise.then(() => {
          wrapper.update()
          expect(wrapper.exists('canvas')).toEqual(true)
        })
      })

      describe('with the VALIDATION_CONFETTI_ENABLED flag set to false', () => {
        beforeEach(() => {
          window.ENV = {
            validation_api_url: '/foo/bar',
            VALIDATION_CONFETTI_ENABLED: false
          }
        })

        it('does not render confetti', () => {
          const wrapper = mount(<LinkValidator />)
          const promise = new Promise(resolve => {
            setTimeout(resolve, 1)
          })
          act(() => {
            wrapper.find('button').simulate('click')
            jest.advanceTimersByTime(2000)
          })
          return promise.then(() => {
            wrapper.update()
            expect(wrapper.exists('canvas')).toEqual(false)
          })
        })
      })
    })

    describe('with invalid links', () => {
      let env, sandbox
      beforeEach(() => {
        env = window.ENV
        sandbox = sinon.createSandbox()
        window.ENV = {
          validation_api_url: '/foo/bar',
          VALIDATION_CONFETTI_ENABLED: true
        }
        sandbox.stub($, 'ajax').callsFake(params =>
          params.success({
            workflow_state: 'completed',
            results: {
              version: 2,
              issues: [
                {
                  name: 'Foo',
                  type: 'wiki_page',
                  content_url: '/foo/bar',
                  invalid_links: [
                    {
                      url: 'http://example.foo',
                      reason: 'unreachable',
                      link_text: 'foo'
                    },
                    {
                      url: 'javascript:alert("lulz")',
                      reason: 'unreachable',
                      link_text: 'hehehh'
                    }
                  ]
                }
              ]
            }
          })
        )
      })

      afterEach(() => {
        window.ENV = env
        sandbox.restore()
      })

      it('does not render confetti', () => {
        const wrapper = mount(<LinkValidator />)
        const promise = new Promise(resolve => {
          setTimeout(resolve, 1)
        })
        act(() => {
          wrapper.find('button').simulate('click')
          jest.advanceTimersByTime(2000)
        })
        return promise.then(() => {
          wrapper.update()
          expect(wrapper.exists('canvas')).toEqual(false)
        })
      })

      it('sanitizes URLs', () => {
        const wrapper = mount(<LinkValidator />)
        const promise = new Promise(resolve => {
          setTimeout(resolve, 1)
        })
        act(() => {
          wrapper.find('button').simulate('click')
          jest.advanceTimersByTime(2000)
        })
        return promise.then(() => {
          wrapper.update()

          expect(
            wrapper.findWhere(x => x.text() === 'hehehh')
              .hostNodes()
              .first()
              .getDOMNode()
              .href
          ).toEqual("about:blank")
        })
      })
    })
  })
})
