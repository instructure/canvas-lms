/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {BRAND_GRADIENT, RADIUS_MD} from '../brand'

const outerStyle: React.CSSProperties = {
  borderRadius: RADIUS_MD,
  padding: '1px',
  background: BRAND_GRADIENT,
}

const innerStyle: React.CSSProperties = {
  borderRadius: `calc(${RADIUS_MD} - 1px)`,
  overflow: 'hidden',
  background: 'white',
}

interface GradientBorderProps {
  children: React.ReactNode
  style?: React.CSSProperties
  fillHeight?: boolean
}

const GradientBorder: React.FC<GradientBorderProps> = ({children, style, fillHeight}) => (
  <div style={{...outerStyle, ...style}}>
    <div style={{...innerStyle, ...(fillHeight ? {height: '100%'} : {})}}>{children}</div>
  </div>
)

export default GradientBorder
