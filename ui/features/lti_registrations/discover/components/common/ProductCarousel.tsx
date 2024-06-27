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

import ProductCard from '../ProductCard/ProductCard'
import {IconButton} from '@instructure/ui-buttons'
import {IconArrowOpenStartLine, IconArrowOpenEndLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'

import type {Product} from '../../model/Product'

const I18n = useI18nScope('lti_registrations')

type ProductCarouselProps = {
  products: Product[] | undefined
  companyName: string
}

function ProductCarousel(props: ProductCarouselProps) {
  const {products, companyName} = props
  const windowSize = GetWindowSize()
  const slider = React.useRef<Slider>(null)

  const [currentSlideNumber, setCurrentSlideNumber] = useState(0)

  const settings = useMemo(() => {
    return {
      dots: false,
      infinite: false,
      slidesToShow: (products || []).length > 3 ? 3 : (products || []).length,
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
  }, [products])

  const renderProducts = () => {
    return products?.map((associatedProducts, i) => (
      <ProductCard key={`${i + 1}`} product={associatedProducts} />
    ))
  }

  const arrowDisablePerBreakpoint = useMemo(() => {
    const l = products?.length ?? 0
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
  }, [products, windowSize])

  return (
    <div>
      <Flex margin="0 0 medium 0">
        <Flex.Item shouldGrow={true} shouldShrink={true}>
          <Text weight="bold" size="large">
            {I18n.t('More Products by')} {companyName}
          </Text>
        </Flex.Item>
        {(products?.length ?? 0) > 1 && (
          <Flex.Item align="start">
            <IconButton
              screenReaderLabel={I18n.t('Carousel Previous Product Button')}
              withBackground={false}
              withBorder={false}
              color="secondary"
              onClick={() => slider?.current?.slickPrev()}
              interaction={currentSlideNumber === 0 ? 'disabled' : 'enabled'}
            >
              <IconArrowOpenStartLine />
            </IconButton>
            <IconButton
              screenReaderLabel={I18n.t('Carousel Next Product Button')}
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
            {renderProducts()}
          </Slider>
        </Flex.Item>
      </Flex>
    </div>
  )
}

export default ProductCarousel
