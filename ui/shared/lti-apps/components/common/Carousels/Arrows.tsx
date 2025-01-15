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

import {useScope as createI18nScope} from '@canvas/i18n'
import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {IconArrowOpenStartLine, IconArrowOpenEndLine} from '@instructure/ui-icons'

import Slider from 'react-slick'

const I18n = createI18nScope('lti_registrations')
const disabled = I18n.t('disabled')
const enabled = I18n.t('enabled')

type NextArrowProps = {
  currentSlideNumber: number
  slider: React.RefObject<Slider>
  updatedArrowDisableIndex: number
  screenReaderLabel?: string
}

type PreviousArrowProps = {
  currentSlideNumber: number
  slider: React.RefObject<Slider>
  screenReaderLabel?: string
}

export const NextArrow = (props: NextArrowProps) => {
  const {currentSlideNumber, slider, updatedArrowDisableIndex, screenReaderLabel} = props

  return (
    <Flex.Item>
      <div>
        <IconButton
          screenReaderLabel={screenReaderLabel || I18n.t('Carousel Next Item Button')}
          withBackground={false}
          withBorder={false}
          color="secondary"
          onClick={() => slider?.current?.slickNext()}
          interaction={currentSlideNumber === updatedArrowDisableIndex ? disabled : enabled}
        >
          <IconArrowOpenEndLine />
        </IconButton>
      </div>
    </Flex.Item>
  )
}

export const PreviousArrow = (props: PreviousArrowProps) => {
  const {currentSlideNumber, slider, screenReaderLabel} = props

  return (
    <Flex.Item>
      <div style={{marginRight: '0.8rem'}}>
        <IconButton
          screenReaderLabel={screenReaderLabel || I18n.t('Carousel Previous Item Button')}
          withBackground={false}
          withBorder={false}
          color="secondary"
          onClick={() => slider?.current?.slickPrev()}
          interaction={currentSlideNumber === 0 ? disabled : enabled}
        >
          <IconArrowOpenStartLine />
        </IconButton>
      </div>
    </Flex.Item>
  )
}
