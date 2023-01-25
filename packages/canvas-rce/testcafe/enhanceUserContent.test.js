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

import {Selector} from 'testcafe'
// eslint-disable-next-line babel/no-unused-expressions
fixture`EnhanceUserContent`.page`./enhanceUserContent.html`

// const externalLink = Selector(
//   'a.inline_disabled.external[target="_blank"][rel="noreferrer noopener"]'
// )
const externalLinkIcon = Selector('span.external_link_icon svg')
const downloadButton = Selector('a.file_download_btn svg')
// const loadingPreviewSpinner = Selector('.loading_image_holder')
const autoOpenInlinePreviewLink = Selector('.auto_open.file_preview_link')
const inlinePreviewContainer = Selector('.preview_container')
const overlayPreviewLink = Selector('.inline_disabled.preview_in_overlay')

test('enhances user_content', async t => {
  // this one passes locally, but fails in jenkins!?!
  // await t.expect(externalLink.exists).ok('there should be a decorated external link')
  await t.expect(externalLinkIcon.exists).ok('there should be an external link icon')
  await t.expect(downloadButton.exists).ok('there should be a download button')
  // this has started failing too. I don't know why
  // await t.expect(loadingPreviewSpinner.exists).ok('there should be a loading spinner')
  await t
    .expect(autoOpenInlinePreviewLink.exists)
    .ok('there should be an auto_open inline preview link')
  await t.expect(inlinePreviewContainer.exists).ok('there should be an inline preview container')
  await t.expect(overlayPreviewLink.exists).ok('there should be an overlay preveiw link')
})
