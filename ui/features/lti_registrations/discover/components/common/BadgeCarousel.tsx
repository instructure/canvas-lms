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
import {Text} from '@instructure/ui-text'
import {Img} from '@instructure/ui-img'
import {Link} from '@instructure/ui-link'

import type {Badges} from '../../model/Product'

const I18n = useI18nScope('lti_registrations')

type BadgeCarouselProps = {
  badges: Badges[]
}

function BadgeCarousel(props: BadgeCarouselProps) {
  const {badges} = props
  const windowSize = GetWindowSize()
  const slider = React.useRef<Slider>(null)

  const [currentSlideNumber, setCurrentSlideNumber] = useState(0)

  const settings = useMemo(() => {
    return {
      dots: false,
      infinite: false,
      slidesToShow: (badges || []).length >= 3 ? 3 : (badges || []).length,
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
  }, [badges])

  const renderBadges = () => {
    return badges.map((badge, i) => (
      <Flex key={`${i + 1}`} margin="0 xx-large large 0">
        <Flex.Item>
          <div>
            <Img src={badge.image_url} width={50} height={50} />
          </div>
        </Flex.Item>
        <Flex.Item padding="0 0 0 small">
          <Text weight="bold" size="medium">
            {badge.name}
          </Text>
          <Flex.Item>
            {badge.link && (
              <div>
                <Link href={badge.link} isWithinText={false}>
                  <Text weight="bold">{I18n.t('Learn More')}</Text>
                </Link>
              </div>
            )}
          </Flex.Item>
        </Flex.Item>
      </Flex>
    ))
  }

  const arrowDisablePerBreakpoint = useMemo(() => {
    const l = badges.length
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
  }, [badges, windowSize])

  return (
    <div>
      <Flex margin="medium 0 small 0">
        <Flex.Item shouldGrow={true} shouldShrink={true}>
          <Text weight="bold" size="large">
            {I18n.t('Badges')}
          </Text>
        </Flex.Item>
        {badges.length > 1 && (
          <Flex.Item align="start">
            <IconButton
              screenReaderLabel={I18n.t('Carousel Previous Badge Button')}
              withBackground={false}
              withBorder={false}
              color="secondary"
              onClick={() => slider?.current?.slickPrev()}
              interaction={currentSlideNumber === 0 ? 'disabled' : 'enabled'}
            >
              <IconArrowOpenStartLine />
            </IconButton>
            <IconButton
              screenReaderLabel={I18n.t('Carousel Next Badge Button')}
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
          </Flex.Item>
        )}
      </Flex>
      <Flex>
        <Flex.Item>
          <Slider
            ref={slider}
            {...settings}
            beforeChange={(currentSlide: number, nextSlide: number) =>
              setCurrentSlideNumber(nextSlide)
            }
          >
            {renderBadges()}
          </Slider>
        </Flex.Item>
      </Flex>
    </div>
  )
}

export default BadgeCarousel
