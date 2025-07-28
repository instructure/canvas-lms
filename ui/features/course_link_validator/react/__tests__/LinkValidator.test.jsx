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
import {render, fireEvent, waitFor, act} from '@testing-library/react'
import LinkValidator from '../LinkValidator'
import $ from 'jquery'
import fakeENV from '@canvas/test-utils/fakeENV'

jest.useFakeTimers()
jest.mock('jquery')

describe('LinkValidator', () => {
  beforeEach(() => {
    // Mock jQuery selector and show/hide methods
    const mockShow = jest.fn()
    const mockHide = jest.fn()
    const mockJQuery = jest.fn(() => ({
      show: mockShow,
      hide: mockHide,
    }))
    $.mockImplementation(selector => mockJQuery(selector))
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('confetti', () => {
    describe('with no invalid links', () => {
      beforeEach(() => {
        fakeENV.setup({
          validation_api_url: '/foo/bar',
          VALIDATION_CONFETTI_ENABLED: true,
        })

        $.ajax.mockImplementation(params =>
          params.success({
            workflow_state: 'completed',
            results: {
              version: 2,
              issues: [],
            },
          }),
        )
      })

      afterEach(() => {
        fakeENV.teardown()
        jest.clearAllMocks()
      })

      it('renders confetti', async () => {
        const {getByTestId} = render(<LinkValidator pollTimeout={0} pollTimeoutInitial={0} />)

        act(() => {
          fireEvent.click(getByTestId('validate-button'))
          jest.advanceTimersByTime(2000)
        })

        await waitFor(() => {
          expect(getByTestId('confetti-canvas')).toBeInTheDocument()
        })
      })

      describe('with the VALIDATION_CONFETTI_ENABLED flag set to false', () => {
        beforeEach(() => {
          fakeENV.setup({
            validation_api_url: '/foo/bar',
            VALIDATION_CONFETTI_ENABLED: false,
          })
        })

        it('does not render confetti', async () => {
          const {getByTestId, queryByTestId} = render(
            <LinkValidator pollTimeout={0} pollTimeoutInitial={0} />,
          )

          act(() => {
            fireEvent.click(getByTestId('validate-button'))
            jest.advanceTimersByTime(2000)
          })

          await waitFor(() => {
            expect(queryByTestId('confetti-canvas')).not.toBeInTheDocument()
          })
        })
      })
    })

    describe('with invalid links', () => {
      beforeEach(() => {
        fakeENV.setup({
          validation_api_url: '/foo/bar',
          VALIDATION_CONFETTI_ENABLED: true,
        })

        $.ajax.mockImplementation(params =>
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
                      url: 'javascript:alert("lulz")',
                      reason: 'unreachable',
                      link_text: 'hehehh',
                    },
                  ],
                },
              ],
            },
          }),
        )
      })

      afterEach(() => {
        fakeENV.teardown()
        jest.clearAllMocks()
      })

      it('does not render confetti', async () => {
        const {getByTestId, queryByTestId} = render(
          <LinkValidator pollTimeout={0} pollTimeoutInitial={0} />,
        )

        act(() => {
          fireEvent.click(getByTestId('validate-button'))
          jest.advanceTimersByTime(2000)
        })

        await waitFor(() => {
          expect(queryByTestId('confetti-canvas')).not.toBeInTheDocument()
        })
      })

      it('sanitizes URLs', async () => {
        const {getByText, getByTestId} = render(
          <LinkValidator pollTimeout={0} pollTimeoutInitial={0} />,
        )

        act(() => {
          fireEvent.click(getByTestId('validate-button'))
          jest.advanceTimersByTime(2000)
        })

        await waitFor(() => {
          expect(getByText('hehehh').href).toEqual('about:blank')
        })
      })
    })
  })
})
