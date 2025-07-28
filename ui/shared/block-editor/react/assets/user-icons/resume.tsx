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
      title={I18n.t('resume')}
      src={`<svg width="27" height="27" viewBox="0 0 27 27" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M22.5082 2.30324C22.5082 1.85716 22.1462 1.49512 21.7001 1.49512H5.53762C5.09153 1.49512 4.72949 1.85716 4.72949 2.30324V24.9307C4.72949 25.3768 5.09153 25.7389 5.53762 25.7389H21.7001C22.1462 25.7389 22.5082 25.3768 22.5082 24.9307V2.30324ZM20.892 3.11137V24.1226H6.34574V3.11137H20.892ZM8.77012 22.5064H18.4676C18.9137 22.5064 19.2757 22.1443 19.2757 21.6982C19.2757 21.2522 18.9137 20.8901 18.4676 20.8901H8.77012C8.32403 20.8901 7.96199 21.2522 7.96199 21.6982C7.96199 22.1443 8.32403 22.5064 8.77012 22.5064ZM8.77012 18.4657H18.4676C18.9137 18.4657 19.2757 18.1037 19.2757 17.6576C19.2757 17.2115 18.9137 16.8495 18.4676 16.8495H8.77012C8.32403 16.8495 7.96199 17.2115 7.96199 17.6576C7.96199 18.1037 8.32403 18.4657 8.77012 18.4657ZM8.77012 14.4251H18.4676C18.9137 14.4251 19.2757 14.0631 19.2757 13.617C19.2757 13.1709 18.9137 12.8089 18.4676 12.8089H8.77012C8.32403 12.8089 7.96199 13.1709 7.96199 13.617C7.96199 14.0631 8.32403 14.4251 8.77012 14.4251ZM12.8107 5.53574C12.8107 5.08966 12.4487 4.72762 12.0026 4.72762H8.77012C8.32403 4.72762 7.96199 5.08966 7.96199 5.53574V9.57637C7.96199 10.0225 8.32403 10.3845 8.77012 10.3845H12.0026C12.4487 10.3845 12.8107 10.0225 12.8107 9.57637V5.53574ZM15.2351 9.98043H18.4676C18.9137 9.98043 19.2757 9.61839 19.2757 9.17231C19.2757 8.72622 18.9137 8.36418 18.4676 8.36418H15.2351C14.789 8.36418 14.427 8.72622 14.427 9.17231C14.427 9.61839 14.789 9.98043 15.2351 9.98043ZM11.1945 6.34387V8.76824H9.57824V6.34387H11.1945ZM15.2351 6.74793H18.4676C18.9137 6.74793 19.2757 6.38589 19.2757 5.93981C19.2757 5.49372 18.9137 5.13168 18.4676 5.13168H15.2351C14.789 5.13168 14.427 5.49372 14.427 5.93981C14.427 6.38589 14.789 6.74793 15.2351 6.74793Z" fill="currentColor"/>
</svg>`}
      size={size}
    />
  )
}
