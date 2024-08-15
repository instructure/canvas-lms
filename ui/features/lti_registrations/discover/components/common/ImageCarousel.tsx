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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState, useMemo} from 'react'
import GetWindowSize from './GetWindowSize'
import Slider from 'react-slick'
import 'slick-carousel/slick/slick.css'

import {IconButton} from '@instructure/ui-buttons'
import {IconArrowOpenStartLine, IconArrowOpenEndLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'

const I18n = useI18nScope('lti_registrations')

type ImageCarouselProps = {
  screenshots: string[]
}

function ImageCarousel(props: ImageCarouselProps) {
  const {screenshots} = props
  const windowSize = GetWindowSize()
  const slider = React.useRef<Slider>(null)

  const [currentSlideNumber, setCurrentSlideNumber] = useState(0)

  const settings = useMemo(() => {
    return {
      dots: false,
      infinite: false,
      slidesToShow: screenshots.length > 3 ? 3 : screenshots?.length,
      slidesToScroll: 1,
      arrows: false,
      responsive: [
        {
          breakpoint: 760,
          settings: {
            slidesToShow: 2,
            slidesToScroll: 1,
            initialSlide: 1,
          },
        },
        {
          breakpoint: 360,
          settings: {
            slidesToShow: 1,
            slidesToScroll: 1,
          },
        },
      ],
    }
  }, [screenshots])

  const renderScreenshots = () => {
    return screenshots?.map((screenshot, i) => (
      <div key={`${i + 1}`}>
        <div style={{marginRight: '1rem'}}>
          <img src={screenshot} alt="" style={{borderRadius: 5, height: 265, width: 340}} />
        </div>
      </div>
    ))
  }

  const arrowDisablePerBreakpoint = useMemo(() => {
    const l = screenshots.length
    if (windowSize <= 360 && l === 2) {
      return l - 1
    } else if (windowSize <= 360) {
      return l - 1
    } else if (windowSize <= 760 && windowSize > 360) {
      return l - 2
    } else if (windowSize >= 760 && l === 2) {
      return l - 2
    } else {
      return l - 3
    }
  }, [screenshots, windowSize])

  return (
    <Flex width="93%" justifyItems="space-between">
      {screenshots.length > 1 && (
        <Flex.Item>
          <div style={{marginRight: '0.8rem'}}>
            <IconButton
              screenReaderLabel={I18n.t('Carousel Previous Screenshot Button')}
              withBackground={false}
              withBorder={false}
              color="secondary"
              onClick={() => slider?.current?.slickPrev()}
              interaction={currentSlideNumber === 0 ? 'disabled' : 'enabled'}
            >
              <IconArrowOpenStartLine />
            </IconButton>
          </div>
        </Flex.Item>
      )}
      <Flex.Item>
        <Slider
          ref={slider}
          {...settings}
          beforeChange={(currentSlide: number, nextSlide: number) =>
            setCurrentSlideNumber(nextSlide)
          }
        >
          {renderScreenshots()}
        </Slider>
      </Flex.Item>
      {screenshots.length > 1 && (
        <Flex.Item>
          <div>
            <IconButton
              screenReaderLabel={I18n.t('Carousel Next Screenshot Button')}
              withBackground={false}
              withBorder={false}
              color="secondary"
              onClick={() => slider?.current?.slickNext()}
              interaction={
                currentSlideNumber === arrowDisablePerBreakpoint ? 'disabled' : 'enabled'
              }
            >
              <IconArrowOpenEndLine />
            </IconButton>
          </div>
        </Flex.Item>
      )}
    </Flex>
  )
}

export default ImageCarousel
