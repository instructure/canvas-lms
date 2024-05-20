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
import Slider from 'react-slick'
import 'slick-carousel/slick/slick.css'

import {IconButton} from '@instructure/ui-buttons'
import {IconArrowOpenStartLine, IconArrowOpenEndLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'

type ImageCarouselProps = {
  screenshots: string[]
}

function ImageCarousel(props: ImageCarouselProps) {
  const {screenshots} = props
  const slider = React.useRef<null | any>()

  const settings = {
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
      <Flex.Item>
        <div style={{opacity: 0.3, marginRight: '0.8rem'}}>
          <IconButton
            screenReaderLabel="Carousel Previous Screenshot Button"
            withBackground={false}
            withBorder={false}
            onClick={() => slider?.current?.slickPrev()}
          >
            <IconArrowOpenStartLine />
          </IconButton>
        </div>
      </Flex.Item>
      <Flex.Item>
        <Slider ref={slider} {...settings}>
          {renderScreenshots()}
        </Slider>
      </Flex.Item>
      <Flex.Item>
        <div style={{opacity: 0.3}}>
          <IconButton
            screenReaderLabel="Carousel Next Screenshot Button"
            withBackground={false}
            withBorder={false}
            onClick={() => slider?.current?.slickNext()}
          >
            <IconArrowOpenEndLine />
          </IconButton>
        </div>
      </Flex.Item>
    </Flex>
  )
}

export default ImageCarousel
