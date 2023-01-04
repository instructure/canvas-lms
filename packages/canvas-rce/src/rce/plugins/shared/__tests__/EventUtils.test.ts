/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {isMicrosoftWordContent} from '../EventUtils'

describe('instructure_paste', () => {
  describe('isMicrosoftWordContent', () => {
    it('catches the microsoft dash namespaces', () => {
      const html = `
        <html xmlns:o="urn:schemas-microsoft-com:office:office">
        <head></head>
        <body>
        <p >hello></p>
        <!--EndFragment-->
        </body></html>`
      expect(isMicrosoftWordContent(html)).toEqual(true)
    })

    it('catches the microsoft dotted namespaces', () => {
      const html = `
        <html xmlns:m="http://schemas.microsoft.com/office/2004/12/omml">
        <head></head>
        <body>
        <p >hello></p>
        <!--EndFragment-->
        </body></html>`
      expect(isMicrosoftWordContent(html)).toEqual(true)
    })

    it('catches Mso class names', () => {
      const html = `
        <body lang="EN-US" style="tab-interval:.5in;word-wrap:break-word">
        <!--StartFragment-->
        <p class="MsoNormal" style="margin-bottom:3.0pt"></p>
        <!--EndFragment-->
        </body></html>`
      expect(isMicrosoftWordContent(html)).toEqual(true)
    })

    it('catches namespaced paragraphs', () => {
      const html = `
        <body lang="EN-US" style="tab-interval:.5in;word-wrap:break-word">
        <!--StartFragment-->
        <o:p>hello</o:p>
        <!--EndFragment-->
        </body>`
      expect(isMicrosoftWordContent(html)).toEqual(true)
    })

    it('does not misidentify non-Word content', () => {
      const html = `
        <html>
        <head></head>
        <body>
        <p class="pretty">hello></p>
        <!--EndFragment-->
        </body></html>`
      expect(isMicrosoftWordContent(html)).toEqual(false)
    })
  })
})
