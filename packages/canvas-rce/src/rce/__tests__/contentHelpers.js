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

export function videoFromTray() {
  return {
    class: 'instructure_file_link', // if from tray
    content_type: 'video/quicktime',
    embedded_iframe_url: 'https://mycanvas.com:3000/media_objects_iframe/17',
    href: '/media_objects_iframe/17',
    id: 17,
    target: '_blank',
    title: 'filename.mov',
  }
}
export function videoFromUpload() {
  return {
    id: 'maybe',
    embedded_iframe_url: 'https://mycanvas.com:3000/url/to/m-media-id',
    media_id: 'm-media-id',
    title: 'filename.mov',
    type: 'video',
  }
}

export function audioFromTray() {
  return {
    class: 'instructure_file_link',
    content_type: 'audio/mp3',
    href: '/url/to/course/file',
    id: 29,
    target: '_blank',
    text: 'filename.mp3',
  }
}
export function audioFromUpload() {
  return {
    id: 'maybe',
    embedded_iframe_url: 'https://mycanvas.com:3000/url/to/m-media-id',
    media_id: 'm-media-id',
    title: 'filename.mp3',
    type: 'audio',
  }
}
