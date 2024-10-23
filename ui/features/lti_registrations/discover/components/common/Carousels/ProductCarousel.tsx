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
import React, {useState} from 'react'

import useBreakpoints from '@canvas/lti-apps/hooks/useBreakpoints'
import {PreviousArrow, NextArrow} from './Arrows'
import {settings, calculateArrowDisableIndex} from './utils'
import Slider from 'react-slick'
import 'slick-carousel/slick/slick.css'

import ProductCard from '../../../../../../shared/lti-apps/components/apps/ProductCard'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'

import type {Product} from '../../../../../../shared/lti-apps/models/Product'
import type {Settings} from 'react-slick'

const I18n = useI18nScope('lti_registrations')

type ProductCarouselProps = {
  products: Product[]
  companyName: string
  customSettings?: Partial<Settings>
}

function ProductCarousel(props: ProductCarouselProps) {
  const {products, companyName} = props
  const slider = React.useRef<Slider>(null)
  const updatedSettings = settings(products)
  const {isDesktop, isTablet, isMobile} = useBreakpoints()
  const updatedArrowDisableIndex = calculateArrowDisableIndex(
    products,
    isDesktop,
    isTablet,
    isMobile
  )

  const [currentSlideNumber, setCurrentSlideNumber] = useState(0)

  const renderProducts = () => {
    return products?.map((associatedProducts, i) => (
      <Flex key={`${i + 1}`} margin="0 small 0 0">
        <ProductCard key={`${i + 1}`} product={associatedProducts} />
      </Flex>
    ))
  }

  return (
    <div>
      <Flex margin="0 0 medium 0">
        <Flex.Item shouldGrow={true} shouldShrink={true}>
          <Text weight="bold" size="large">
            {I18n.t('More Products by')} {companyName}
          </Text>
        </Flex.Item>
        {(products?.length ?? 0) > 1 && (
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
            {renderProducts()}
          </Slider>
        </Flex.Item>
      </Flex>
    </div>
  )
}

export default ProductCarousel
