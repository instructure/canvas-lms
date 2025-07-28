/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {SVGIcon} from '@instructure/ui-svg-images'
import {type IconProps} from './iconTypes'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

export default ({elementRef, size = 'small'}: IconProps) => {
  return (
    <SVGIcon
      elementRef={elementRef}
      title={I18n.t('notes')}
      src={`<svg width="27" height="27" viewBox="0 0 27 27" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M18.9707 3.11612H14.2015V2.51003C14.2015 2.06394 13.8454 1.7019 13.4066 1.7019C12.9678 1.7019 12.6117 2.06394 12.6117 2.51003V3.11612H7.84246V2.51003C7.84246 2.06394 7.48636 1.7019 7.04758 1.7019C6.60881 1.7019 6.25271 2.06394 6.25271 2.51003V3.11612H3.0732C2.63443 3.11612 2.27832 3.47816 2.27832 3.92425V24.9355C2.27832 25.3816 2.63443 25.7436 3.0732 25.7436H23.74C24.1788 25.7436 24.5349 25.3816 24.5349 24.9355V3.92425C24.5349 3.47816 24.1788 3.11612 23.74 3.11612H20.5605V2.51003C20.5605 2.06394 20.2044 1.7019 19.7656 1.7019C19.3268 1.7019 18.9707 2.06394 18.9707 2.51003V3.11612ZM20.5605 4.73237V5.33847C20.5605 5.78455 20.2044 6.14659 19.7656 6.14659C19.3268 6.14659 18.9707 5.78455 18.9707 5.33847V4.73237H14.2015V5.33847C14.2015 5.78455 13.8454 6.14659 13.4066 6.14659C12.9678 6.14659 12.6117 5.78455 12.6117 5.33847V4.73237H7.84246V5.33847C7.84246 5.78455 7.48636 6.14659 7.04758 6.14659C6.60881 6.14659 6.25271 5.78455 6.25271 5.33847V4.73237H3.86807V24.1274H22.9451V4.73237H20.5605ZM5.45783 20.8949H21.3554C21.7941 20.8949 22.1502 20.5328 22.1502 20.0867C22.1502 19.6407 21.7941 19.2786 21.3554 19.2786H5.45783C5.01906 19.2786 4.66295 19.6407 4.66295 20.0867C4.66295 20.5328 5.01906 20.8949 5.45783 20.8949ZM5.45783 16.0461H21.3554C21.7941 16.0461 22.1502 15.6841 22.1502 15.238C22.1502 14.7919 21.7941 14.4299 21.3554 14.4299H5.45783C5.01906 14.4299 4.66295 14.7919 4.66295 15.238C4.66295 15.6841 5.01906 16.0461 5.45783 16.0461ZM5.45783 11.1974H21.3554C21.7941 11.1974 22.1502 10.8353 22.1502 10.3892C22.1502 9.94316 21.7941 9.58112 21.3554 9.58112H5.45783C5.01906 9.58112 4.66295 9.94316 4.66295 10.3892C4.66295 10.8353 5.01906 11.1974 5.45783 11.1974Z" fill="currentColor"/>
</svg>
`}
      size={size}
    />
  )
}
