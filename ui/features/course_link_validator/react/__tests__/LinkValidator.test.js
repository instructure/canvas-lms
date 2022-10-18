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
import {render, fireEvent} from '@testing-library/react'
import LinkValidator from '../LinkValidator'
import sinon from 'sinon'
import $ from 'jquery'

jest.useFakeTimers()

describe('LinkValidator', () => {
  describe('confetti', () => {
    describe('with no invalid links', () => {
      let env, sandbox
      beforeEach(() => {
        env = window.ENV
        sandbox = sinon.createSandbox()
        window.ENV = {
          validation_api_url: '/foo/bar',
          VALIDATION_CONFETTI_ENABLED: true,
        }
        sandbox.stub($, 'ajax').callsFake(params =>
          params.success({
            workflow_state: 'completed',
            results: {
              version: 2,
              issues: [],
            },
          })
        )
      })

      afterEach(() => {
        window.ENV = env
        sandbox.restore()
      })

      it('renders confetti', () => {
        const {getByTestId} = render(<LinkValidator pollTimeout={0} pollTimeoutInitial={0} />)
        const promise = new Promise(resolve => {
          setTimeout(resolve, 1)
        })
        act(() => {
          fireEvent.click(getByTestId('validate-button'))
          jest.advanceTimersByTime(2000)
        })
        return promise.then(() => {
          expect(getByTestId('confetti-canvas')).toBeTruthy()
        })
      })

      describe('with the VALIDATION_CONFETTI_ENABLED flag set to false', () => {
        beforeEach(() => {
          window.ENV = {
            validation_api_url: '/foo/bar',
            VALIDATION_CONFETTI_ENABLED: false,
          }
        })

        it('does not render confetti', () => {
          const {getByTestId, queryByTestId} = render(
            <LinkValidator pollTimeout={0} pollTimeoutInitial={0} />
          )
          const promise = new Promise(resolve => {
            setTimeout(resolve, 1)
          })
          act(() => {
            fireEvent.click(getByTestId('validate-button'))
            jest.advanceTimersByTime(2000)
          })
          return promise.then(() => {
            expect(queryByTestId('confetti-canvas')).toBeNull()
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
          VALIDATION_CONFETTI_ENABLED: true,
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
                      link_text: 'foo',
                    },
                    {
                      // eslint-disable-next-line no-script-url
                      url: 'javascript:alert("lulz")',
                      reason: 'unreachable',
                      link_text: 'hehehh',
                    },
                  ],
                },
              ],
            },
          })
        )
      })

      afterEach(() => {
        window.ENV = env
        sandbox.restore()
      })

      it('does not render confetti', () => {
        const {getByTestId, queryByTestId} = render(
          <LinkValidator pollTimeout={0} pollTimeoutInitial={0} />
        )
        const promise = new Promise(resolve => {
          setTimeout(resolve, 1)
        })
        act(() => {
          fireEvent.click(getByTestId('validate-button'))
          jest.advanceTimersByTime(2000)
        })
        return promise.then(() => {
          expect(queryByTestId('confetti-canvas')).toBeNull()
        })
      })

      it('sanitizes URLs', () => {
        const {getByText, getByTestId} = render(
          <LinkValidator pollTimeout={0} pollTimeoutInitial={0} />
        )
        const promise = new Promise(resolve => {
          setTimeout(resolve, 1)
        })
        act(() => {
          fireEvent.click(getByTestId('validate-button'))
          jest.advanceTimersByTime(2000)
        })
        return promise.then(() => {
          expect(getByText('hehehh').href).toEqual('about:blank')
        })
      })
    })
  })
})
