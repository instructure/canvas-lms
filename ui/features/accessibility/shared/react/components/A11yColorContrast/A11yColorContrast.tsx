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

import React, {useRef, useEffect} from 'react'
import {ColorContrast, ColorContrastProps} from '@instructure/ui-color-picker'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('accessibility_checker')

export interface A11yColorContrastProps
  extends Omit<
    ColorContrastProps,
    | 'successLabel'
    | 'failureLabel'
    | 'normalTextLabel'
    | 'largeTextLabel'
    | 'graphicsTextLabel'
    | 'firstColorLabel'
    | 'secondColorLabel'
    | 'elementRef'
  > {
  options?: string[]
}

export const A11yColorContrast: React.FC<A11yColorContrastProps> = ({
  firstColor,
  secondColor,
  label,
  onContrastChange,
  validationLevel = 'AA',
  options = [],
}) => {
  const contrastForm = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    const wrapper = contrastForm.current as HTMLDivElement | null
    if (!wrapper) return

    const topLevelDivs = Array.from(wrapper.children).filter(
      el => el.tagName.toUpperCase() === 'DIV',
    )
    const statusWrappers = topLevelDivs.filter(div => div.textContent?.match(/(pass|fail|AAA|AA)/i))
    if (statusWrappers.length === 0) return
    const optionIndexMap: Record<string, number> = {
      normal: 0,
      large: 1,
      graphics: 2,
    }
    Object.entries(optionIndexMap).forEach(([key, index]) => {
      const el = statusWrappers[index] as HTMLElement
      if (!el) return

      if (options.includes(key)) {
        el.style.fontWeight = '700'
        const pillWrapper = el.children[1]
        const pill = pillWrapper.querySelector('span div > div') as HTMLElement // fallback if pill is inside a span
        if (pill) {
          pill.style.fontWeight = '700'
        }
      } else {
        el.style.display = 'none'
      }
    })
  }, [options])

  return (
    <ColorContrast
      firstColor={firstColor}
      secondColor={secondColor}
      label={label}
      successLabel={I18n.t('PASS')}
      failureLabel={I18n.t('FAIL')}
      normalTextLabel={I18n.t('NORMAL TEXT')}
      largeTextLabel={I18n.t('LARGE TEXT')}
      graphicsTextLabel={I18n.t('GRAPHICS TEXT')}
      firstColorLabel={I18n.t('Background')}
      secondColorLabel={I18n.t('Foreground')}
      onContrastChange={onContrastChange}
      validationLevel={validationLevel}
      elementRef={r => {
        if (r instanceof HTMLDivElement || r === null) {
          contrastForm.current = r
        }
      }}
    />
  )
}
