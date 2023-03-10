//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('mimeClass')

// this module works together with app/stylesheets/components/_MimeClassIcons.scss
// so, given the mime-type of a file you can give it a css class name that corresponds to it.
// eg: somefile.pdf would get the css class .mimeClass-pdf and a little icon with the acrobat logo in it.

// if there is a file format that is common enough, go ahead and add an entry to one of these:
// If you need to make a new class, make sure to also make an svg for it in public/images/mimeClassIcons/
// and a class name in app/stylesheets/components/_MimeClassIcons.scss
// (and app/stylesheets/components/deprecated/_fancy_links.scss if it is still being used)
const mimeClasses = {
  audio: {
    get displayName() {
      return I18n.t('Audio')
    },
    mimeTypes: [
      'audio/x-mpegurl',
      'audio/x-pn-realaudio',
      'audio/x-aiff',
      'audio/3gpp',
      'audio/mid',
      'audio/x-wav',
      'audio/basic',
      'audio/mpeg',
    ],
  },
  code: {
    get displayName() {
      return I18n.t('Source code')
    },
    mimeTypes: [
      'text/xml',
      'text/css',
      'text/x-yaml',
      'application/xml',
      'application/javascript',
      'text/x-csharp',
    ],
  },
  doc: {
    get displayName() {
      return I18n.t('Text document')
    },
    mimeTypes: [
      'application/x-docx',
      'text/rtf',
      'application/msword',
      'application/rtf',
      'application/vnd.oasis.opendocument.text',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.apple.pages',
    ],
  },
  flash: {
    get displayName() {
      return I18n.t('Flash')
    },
    mimeTypes: ['application/x-shockwave-flash'],
  },
  html: {
    get displayName() {
      return I18n.t('Web page')
    },
    mimeTypes: ['text/html', 'application/xhtml+xml'],
  },
  image: {
    get displayName() {
      return I18n.t('Image')
    },
    mimeTypes: ['image/png', 'image/x-psd', 'image/gif', 'image/pjpeg', 'image/jpeg', 'image/webp'],
  },
  ppt: {
    get displayName() {
      return I18n.t('Presentation')
    },
    mimeTypes: [
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'application/vnd.ms-powerpoint',
      'application/vnd.apple.keynote',
    ],
  },
  pdf: {
    get displayName() {
      return I18n.t('PDF')
    },
    mimeTypes: ['application/pdf'],
  },
  text: {
    get displayName() {
      return I18n.t('Plain text')
    },
    mimeTypes: ['text', 'text/plain'],
  },
  video: {
    get displayName() {
      return I18n.t('Video')
    },
    mimeTypes: [
      'video/mp4',
      'video/x-ms-asf',
      'video/x-msvideo',
      'video/x-sgi-movie',
      'video/mpeg',
      'video/quicktime',
      'video/x-la-asf',
      'video/3gpp',
      'video/webm',
      'video/avi',
    ],
  },
  xls: {
    get displayName() {
      return I18n.t('Spreadsheet')
    },
    mimeTypes: [
      'application/vnd.oasis.opendocument.spreadsheet',
      'text/csv',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-excel',
      'application/vnd.apple.numbers',
    ],
  },
  zip: {
    get displayName() {
      return I18n.t('Archive')
    },
    mimeTypes: [
      'application/x-rar-compressed',
      'application/x-zip-compressed',
      'application/zip',
      'application/x-zip',
      'application/x-rar',
    ],
  },
}

export default function mimeClass(contentType) {
  return mimeClass.mimeClasses[contentType] || 'file'
}

mimeClass.displayName = function (contentType) {
  const found = mimeClasses[mimeClass(contentType)]
  return (found && found.displayName) || I18n.t('Unknown')
}

mimeClass.mimeClasses = {}
for (const cls in mimeClasses) {
  const value = mimeClasses[cls]
  value.mimeTypes.forEach(mimeType => (mimeClass.mimeClasses[mimeType] = cls))
}
