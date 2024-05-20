// @vitest-environment jsdom
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
import React from 'react'
import {initializeReaderButton, ImmersiveReaderButton} from '../ImmersiveReader'
import {render} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import {enableFetchMocks} from 'jest-fetch-mock'

enableFetchMocks()

describe('#initializeReaderButton', () => {
  it('renders the immersive reader button into the given mount point', () => {
    document.body.innerHTML = '<div id="mount_point"></div>'
    initializeReaderButton(document.getElementById('mount_point'))
    const buttonElement = document.querySelector('button')
    expect(buttonElement.textContent).toMatch(/Immersive Reader/)
    document.body.innerHTML = ''
  })

  describe('ImmersiveReaderButton', () => {
    const fakeContent = {
      title: 'fake title',
      content: () => '<p>Some fake content yay</p>',
    }

    describe('onClick', () => {
      beforeEach(() => {
        fetch.mockResponseOnce(JSON.stringify({token: 'fakeToken', subdomain: 'fakeSubdomain'}))
      })

      it('calls to launch the Immersive Reader with the proper content', async () => {
        const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
        expect.assertions(1)
        const fakeLaunchAsync = (...args) =>
          expect(args).toEqual([
            'fakeToken',
            'fakeSubdomain',
            {
              title: 'fake title',
              chunks: [
                {
                  content: fakeContent.content(),
                  mimeType: 'text/html',
                },
              ],
            },
            {
              cookiePolicy: 0,
            },
          ])
        const fakeReaderLib = Promise.resolve({
          launchAsync: fakeLaunchAsync,
        })
        const {findByText} = render(
          <ImmersiveReaderButton content={fakeContent} readerSDK={fakeReaderLib} />
        )
        const button = await findByText(/Immersive Reader/)
        await user.click(button)
      })

      describe('with MathML content', () => {
        const fakeContentWithMath = {
          title: 'fake title',
          content: () => `
            <div>
              Some simple content
              <img src="something"
                class="MathJax_SVG"
                data-mathml="<mrow><apply><minus/><ci>a</ci><ci>b</ci></apply></mrow>"
              />
              Some post math content
            </div>
          `,
        }

        it('sends the HTML and MathML as chunks', async () => {
          const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
          expect.assertions(1)

          // This whitespace is meaningful for the snapshot so please don't remove it!
          const fakeLaunchAsync = (...args) => {
            expect(args[2].chunks).toMatchInlineSnapshot(`
              [
                {
                  "content": "<div>
                            Some simple content
                            </div>",
                  "mimeType": "text/html",
                },
                {
                  "content": "<mrow><apply><minus/><ci>a</ci><ci>b</ci></apply></mrow>",
                  "mimeType": "application/mathml+xml",
                },
                {
                  "content": "Some post math content
                          
                        ",
                  "mimeType": "text/html",
                },
              ]
            `)
          }

          const fakeReaderLib = Promise.resolve({
            launchAsync: fakeLaunchAsync,
          })

          const {findByText} = render(
            <ImmersiveReaderButton content={fakeContentWithMath} readerSDK={fakeReaderLib} />
          )

          const button = await findByText(/^Immersive Reader$/)
          await user.click(button)
        })
      })
    })
  })
})
