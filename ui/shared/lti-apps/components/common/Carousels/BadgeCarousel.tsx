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
import useBreakpoints from '@canvas/lti-apps/hooks/useBreakpoints'
import {PreviousArrow, NextArrow} from './Arrows'
import {settings, calculateArrowDisableIndex} from './utils'
import Slider from 'react-slick'
import 'slick-carousel/slick/slick.css'

import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Img} from '@instructure/ui-img'
import {Link} from '@instructure/ui-link'

import type {Badges} from '../../../models/Product'
import type {Settings} from 'react-slick'

const I18n = useI18nScope('lti_registrations')

type BadgeCarouselProps = {
  badges: Badges[]
  isMaxMobile: boolean
  isMaxTablet: boolean
  customSettings?: Partial<Settings>
}

function BadgeCarousel(props: BadgeCarouselProps) {
  const {badges, isMaxMobile, isMaxTablet} = props
  const updatedSettings = settings(badges)
  const slider = React.useRef<Slider>(null)
  const {isDesktop, isTablet, isMobile} = useBreakpoints()
  const updatedArrowDisableIndex = calculateArrowDisableIndex(badges, isDesktop, isTablet, isMobile)

  const [currentSlideNumber, setCurrentSlideNumber] = useState(0)

  const sliderOffset = useMemo(() => {
    if (isMaxMobile) {
      return 1
    } else if (isMaxTablet) {
      return 2
    }
    return 3
  }, [isMaxMobile, isMaxTablet])

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
              <div style={{display: currentSlideNumber + sliderOffset > i ? 'block' : 'none'}}>
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

  return (
    <div>
      <Flex margin="medium 0 small 0">
        <Flex.Item shouldGrow={true} shouldShrink={true}>
          <Text weight="bold" size="large">
            {I18n.t('Badges')}
          </Text>
        </Flex.Item>
        {badges.length > 1 && (
          <Flex direction="row">
            <PreviousArrow currentSlideNumber={currentSlideNumber} slider={slider} />
            <NextArrow
              currentSlideNumber={currentSlideNumber}
              slider={slider}
              updatedArrowDisableIndex={updatedArrowDisableIndex.type}
            />
          </Flex>
        )}
      </Flex>
      <Flex>
        <Flex.Item shouldGrow={true}>
          <Slider
            ref={slider}
            {...updatedSettings}
            {...props.customSettings}
            beforeChange={(_currentSlide: number, nextSlide: number) =>
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
