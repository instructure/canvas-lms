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

import React, {useState} from 'react'
import Slider from 'react-slick'
import type {Settings} from 'react-slick'
import 'slick-carousel/slick/slick.css'

import {Flex} from '@instructure/ui-flex'

import {PreviousArrow, NextArrow} from './Arrows'
import useWindowWidth from '../useWindowWidth'
import {settings, calculateArrowDisableIndex} from './utils'

type ImageCarouselProps = {
  screenshots: string[]
  customSettings?: Partial<Settings>
}

function ImageCarousel(props: ImageCarouselProps) {
  const {screenshots} = props
  const slider = React.useRef<Slider>(null)
  const windowSize = useWindowWidth()
  const updatedSettings = settings(screenshots)
  const updatedArrowDisableIndex = calculateArrowDisableIndex(screenshots, windowSize)

  const [currentSlideNumber, setCurrentSlideNumber] = useState(0)

  const renderScreenshots = () => {
    return screenshots?.map((screenshot, i) => (
      <div key={`${i + 1}`}>
        <div style={{marginRight: '1rem'}}>
          <img src={screenshot} alt="" style={{borderRadius: 5, height: 265, width: 340}} />
        </div>
      </div>
    ))
  }

  return (
    <Flex width="93%" justifyItems="space-between">
      {screenshots.length > 1 && (
        <PreviousArrow currentSlideNumber={currentSlideNumber} slider={slider} />
      )}
      <Flex.Item>
        <Slider
          ref={slider}
          {...updatedSettings}
          {...props.customSettings}
          beforeChange={(_currentSlide: number, nextSlide: number) =>
            setCurrentSlideNumber(nextSlide)
          }
        >
          {renderScreenshots()}
        </Slider>
      </Flex.Item>
      {screenshots.length > 1 && (
        <NextArrow
          currentSlideNumber={currentSlideNumber}
          slider={slider}
          updatedArrowDisableIndex={updatedArrowDisableIndex.type}
        />
      )}
    </Flex>
  )
}

export default ImageCarousel
