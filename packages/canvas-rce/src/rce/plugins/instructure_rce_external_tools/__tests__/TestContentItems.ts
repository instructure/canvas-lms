/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import {RceLti11ContentItemJson} from '../lti11-content-items/RceLti11ContentItem'

export default {
  lti_thumb_window: {
    text: 'Arch Linux thumbnail window',
    title: 'Its like sexy for your computer',
    url: 'http://lti-tool-provider-example.dev/messages/blti',
    thumbnail: {
      height: 128,
      width: 128,
      '@id': 'http://www.runeaudio.com/assets/img/banner-archlinux.png',
    },
    placementAdvice: {
      displayHeight: 600,
      displayWidth: 800,
      presentationDocumentTarget: 'window',
    },
    mediaType: 'application/vnd.ims.lti.v1.ltilink',
    '@type': 'LtiLink',
    '@id': 'http://lti-tool-provider-example.dev/messages/blti',
    canvasURL:
      '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti',
  } as RceLti11ContentItemJson,
  lti_thumb_frame: {
    text: 'Arch Linux thumbnail frame',
    title: 'Its like sexy for your computer',
    url: 'http://lti-tool-provider-example.dev/messages/blti',
    thumbnail: {
      height: 128,
      width: 128,
      '@id': 'http://www.runeaudio.com/assets/img/banner-archlinux.png',
    },
    placementAdvice: {
      displayHeight: 600,
      displayWidth: 800,
      presentationDocumentTarget: 'frame',
    },
    mediaType: 'application/vnd.ims.lti.v1.ltilink',
    '@type': 'LtiLink',
    '@id': 'http://lti-tool-provider-example.dev/messages/blti',
    canvasURL:
      '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti',
  } as RceLti11ContentItemJson,
  lti_thumb_iframe: {
    text: 'Arch Linux thumbnail iframe',
    title: 'Its like sexy for your computer',
    url: 'http://lti-tool-provider-example.dev/messages/blti',
    thumbnail: {
      height: 128,
      width: 128,
      '@id': 'http://www.runeaudio.com/assets/img/banner-archlinux.png',
    },
    placementAdvice: {
      displayHeight: 600,
      displayWidth: 800,
      presentationDocumentTarget: 'iframe',
    },
    mediaType: 'application/vnd.ims.lti.v1.ltilink',
    '@type': 'LtiLink',
    '@id': 'http://lti-tool-provider-example.dev/messages/blti',
    canvasURL:
      '/courses/1/external_tools/retrieve?display=borderless&url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti',
  } as RceLti11ContentItemJson,
  lti_thumb_embed: {
    text: 'Arch Linux thumbnail embed',
    title: 'Its like sexy for your computer',
    url: 'http://lti-tool-provider-example.dev/messages/blti',
    thumbnail: {
      height: 128,
      width: 128,
      '@id': 'http://www.runeaudio.com/assets/img/banner-archlinux.png',
    },
    placementAdvice: {
      displayHeight: 600,
      displayWidth: 800,
      presentationDocumentTarget: 'embed',
    },
    mediaType: 'application/vnd.ims.lti.v1.ltilink',
    '@type': 'LtiLink',
    '@id': 'http://lti-tool-provider-example.dev/messages/blti',
    canvasURL:
      '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti',
  } as RceLti11ContentItemJson,
  lti_embed: {
    text: 'Arch Linux plain embed',
    title: 'Its like sexy for your computer',
    url: 'http://lti-tool-provider-example.dev/messages/blti',
    placementAdvice: {
      displayHeight: 600,
      displayWidth: 800,
      presentationDocumentTarget: 'embed',
    },
    mediaType: 'application/vnd.ims.lti.v1.ltilink',
    '@type': 'LtiLink',
    '@id': 'http://lti-tool-provider-example.dev/messages/blti',
    canvasURL:
      '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti',
  } as RceLti11ContentItemJson,
  lti_frame: {
    text: 'Arch Linux plain frame',
    title: 'Its like sexy for your computer',
    url: 'http://lti-tool-provider-example.dev/messages/blti',
    placementAdvice: {
      displayHeight: 600,
      displayWidth: 800,
      presentationDocumentTarget: 'frame',
    },
    mediaType: 'application/vnd.ims.lti.v1.ltilink',
    '@type': 'LtiLink',
    '@id': 'http://lti-tool-provider-example.dev/messages/blti',
    canvasURL:
      '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti',
  } as RceLti11ContentItemJson,
  lti_iframe: {
    text: 'Arch Linux plain iframe',
    title: 'Its like sexy for your computer',
    url: 'http://lti-tool-provider-example.dev/messages/blti',
    placementAdvice: {
      displayHeight: 600,
      displayWidth: 800,
      presentationDocumentTarget: 'iframe',
    },
    mediaType: 'application/vnd.ims.lti.v1.ltilink',
    '@type': 'LtiLink',
    '@id': 'http://lti-tool-provider-example.dev/messages/blti',
    canvasURL:
      '/courses/1/external_tools/retrieve?display=borderless&url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti',
  } as RceLti11ContentItemJson,
  lti_window: {
    text: 'Arch Linux plain window',
    title: 'Its like sexy for your computer',
    url: 'http://lti-tool-provider-example.dev/messages/blti',
    placementAdvice: {
      displayHeight: 600,
      displayWidth: 800,
      presentationDocumentTarget: 'window',
    },
    mediaType: 'application/vnd.ims.lti.v1.ltilink',
    '@type': 'LtiLink',
    '@id': 'http://lti-tool-provider-example.dev/messages/blti',
    canvasURL:
      '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti',
  } as RceLti11ContentItemJson,
  text_thumb_embed: {
    text: 'Arch Linux file item thumbnail embed',
    title: 'Its like sexy for your computer',
    url: 'http://lti-tool-provider-example.dev/test_file.txt',
    thumbnail: {
      height: 128,
      width: 128,
      '@id': 'http://www.runeaudio.com/assets/img/banner-archlinux.png',
    },
    placementAdvice: {
      displayHeight: 600,
      displayWidth: 800,
      presentationDocumentTarget: 'embed',
    },
    mediaType: 'text/plain',
    '@type': 'FileItem',
    '@id': 'http://lti-tool-provider-example.dev/test_file.txt',
  } as RceLti11ContentItemJson,
  text_thumb_frame: {
    text: 'Arch Linux file item thumbnail frame',
    title: 'Its like sexy for your computer',
    url: 'http://lti-tool-provider-example.dev/test_file.txt',
    thumbnail: {
      height: 128,
      width: 128,
      '@id': 'http://www.runeaudio.com/assets/img/banner-archlinux.png',
    },
    placementAdvice: {
      displayHeight: 600,
      displayWidth: 800,
      presentationDocumentTarget: 'frame',
    },
    mediaType: 'text/plain',
    '@type': 'FileItem',
    '@id': 'http://lti-tool-provider-example.dev/test_file.txt',
  } as RceLti11ContentItemJson,
  text_thumb_iframe: {
    text: 'Arch Linux file item thumbnail iframe',
    title: 'Its like sexy for your computer',
    url: 'http://lti-tool-provider-example.dev/test_file.txt',
    thumbnail: {
      height: 128,
      width: 128,
      '@id': 'http://www.runeaudio.com/assets/img/banner-archlinux.png',
    },
    placementAdvice: {
      displayHeight: 600,
      displayWidth: 800,
      presentationDocumentTarget: 'iframe',
    },
    mediaType: 'text/plain',
    '@type': 'FileItem',
    '@id': 'http://lti-tool-provider-example.dev/test_file.txt',
  } as RceLti11ContentItemJson,
  text_thumb_window: {
    text: 'Arch Linux file item thumbnail window',
    title: 'Its like sexy for your computer',
    url: 'http://lti-tool-provider-example.dev/test_file.txt',
    thumbnail: {
      height: 128,
      width: 128,
      '@id': 'http://www.runeaudio.com/assets/img/banner-archlinux.png',
    },
    placementAdvice: {
      displayHeight: 600,
      displayWidth: 800,
      presentationDocumentTarget: 'window',
    },
    mediaType: 'text/plain',
    '@type': 'FileItem',
    '@id': 'http://lti-tool-provider-example.dev/test_file.txt',
  } as RceLti11ContentItemJson,
  text_embed: {
    text: 'Arch Linux file item embed',
    title: 'Its like sexy for your computer',
    url: 'http://lti-tool-provider-example.dev/test_file.txt',
    placementAdvice: {
      displayHeight: 600,
      displayWidth: 800,
      presentationDocumentTarget: 'embed',
    },
    mediaType: 'text/plain',
    '@type': 'FileItem',
    '@id': 'http://lti-tool-provider-example.dev/test_file.txt',
  } as RceLti11ContentItemJson,
  text_frame: {
    text: 'Arch Linux file item frame',
    title: 'Its like sexy for your computer',
    url: 'http://lti-tool-provider-example.dev/test_file.txt',
    placementAdvice: {
      displayHeight: 600,
      displayWidth: 800,
      presentationDocumentTarget: 'frame',
    },
    mediaType: 'text/plain',
    '@type': 'FileItem',
    '@id': 'http://lti-tool-provider-example.dev/test_file.txt',
  } as RceLti11ContentItemJson,
  text_iframe: {
    text: 'Arch Linux file item iframe',
    title: 'Its like sexy for your computer',
    url: 'http://lti-tool-provider-example.dev/test_file.txt',
    placementAdvice: {
      displayHeight: 600,
      displayWidth: 800,
      presentationDocumentTarget: 'iframe',
    },
    mediaType: 'text/plain',
    '@type': 'FileItem',
    '@id': 'http://lti-tool-provider-example.dev/test_file.txt',
  } as RceLti11ContentItemJson,
  text_window: {
    text: 'Arch Linux file item window',
    title: 'Its like sexy for your computer',
    url: 'http://lti-tool-provider-example.dev/test_file.txt',
    placementAdvice: {
      displayHeight: 600,
      displayWidth: 800,
      presentationDocumentTarget: 'window',
    },
    mediaType: 'text/plain',
    '@type': 'FileItem',
    '@id': 'http://lti-tool-provider-example.dev/test_file.txt',
  } as RceLti11ContentItemJson,
  text_window_no_text: {
    text: '',
    title: 'Its like sexy for your computer',
    url: 'http://lti-tool-provider-example.dev/test_file.txt',
    placementAdvice: {
      displayHeight: 600,
      displayWidth: 800,
      presentationDocumentTarget: 'window',
    },
    mediaType: 'text/plain',
    '@type': 'FileItem',
    '@id': 'http://lti-tool-provider-example.dev/test_file.txt',
  } as RceLti11ContentItemJson,
}
