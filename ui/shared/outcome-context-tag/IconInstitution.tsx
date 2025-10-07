/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {InlineSVG} from '@instructure/ui-svg-images'

type IconSize = 'xx-small' | 'x-small' | 'small' | 'medium' | 'large' | 'x-large'

interface IconInstitutionProps {
  size?: IconSize
  color?: string
  style?: React.CSSProperties
}

const IconInstitution = ({size = 'x-small', color = 'white', style}: IconInstitutionProps) => {
  const dimensions: Record<IconSize, string> = {
    'xx-small': '0.75rem',
    'x-small': '1rem',
    small: '1.5rem',
    medium: '2rem',
    large: '2.5rem',
    'x-large': '3rem',
  }

  const iconSize = dimensions[size] || '1rem'

  return (
    <InlineSVG
      viewBox="0 0 1920 1920"
      width={iconSize}
      height={iconSize}
      style={{
        fill: color,
        ...style,
      }}
    >
      <path d="M656 1216V1344H944V1216H656Z" />
      <path d="M656 1456H944V1584H656V1456Z" />
      <path d="M656 976V1104H944V976H656Z" />
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M976 74L1904 352V1904H16V976H336V656H1264V1776H1776V448L1104 246V544H976V74ZM1136 1776H464V784H1136V1776ZM144 1104H336V1776H144V1104Z"
      />
      <path d="M1584 656H1456V1584H1584V656Z" />
    </InlineSVG>
  )
}

export default IconInstitution
