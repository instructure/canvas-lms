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
import {render, fireEvent} from '@testing-library/react'

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
      content: '<p>Some fake content yay</p>'
    }
    describe('onClick', () => {
      it('calls to launch the Immersive Reader with the proper content', async () => {
        expect.assertions(1)
        fetch.mockResponseOnce(JSON.stringify({token: 'fakeToken', subdomain: 'fakeSubdomain'}))
        const fakeLaunchAsync = (...args) =>
          expect(args).toEqual([
            'fakeToken',
            'fakeSubdomain',
            {
              title: 'fake title',
              chunks: [
                {
                  content: fakeContent.content,
                  mimeType: 'text/html'
                }
              ]
            },
            {
              cookiePolicy: 1
            }
          ])
        const fakeReaderLib = Promise.resolve({
          launchAsync: fakeLaunchAsync
        })
        const {findByText} = render(
          <ImmersiveReaderButton content={fakeContent} readerSDK={fakeReaderLib} />
        )
        const button = await findByText(/Immersive Reader/)
        fireEvent.click(button)
      })
    })
  })
})
