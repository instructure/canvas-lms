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
import React, {useState, useRef} from 'react'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {ContextView} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import useBreakpoints from '@canvas/lti-apps/hooks/useBreakpoints'
import Slider from 'react-slick'
import type {Settings} from 'react-slick'
import 'slick-carousel/slick/slick.css'

import {PreviousArrow, NextArrow} from './Arrows'
import {genericCarouselSettings} from './utils'

const I18n = createI18nScope('lti_registrations')

type ImageCarouselModalProps = {
  isModalOpen: boolean
  setModalOpen: (open: boolean) => void
  screenshots: string[]
  productName: string
  customSettings?: Partial<Settings>
}

function ImageCarouselModal(props: ImageCarouselModalProps) {
  const {isModalOpen, setModalOpen, screenshots, productName, customSettings} = props
  const {isDesktop, isMobile} = useBreakpoints()
  const slider = useRef<Slider>(null)
  const defaultFocusElement = useRef<Element | null>(null)
  const updatedSettings = genericCarouselSettings()
  const [currentSlideNumber, setCurrentSlideNumber] = useState(0)

  const previousScreenshot = I18n.t('Previous Screenshot')
  const nextScreenshot = I18n.t('Next Screenshot')

  const renderScreenshots = () => {
    return screenshots?.map(screenshot => (
      <div key={screenshot} aria-label="Carousel of decorative images">
        <img
          src={screenshot}
          style={{display: 'block', marginLeft: 'auto', marginRight: 'auto'}}
          alt=""
        />
      </div>
    ))
  }
  // If Modal variant="inverse", the "out of the box" CloseButton
  // is not visible as of 02/2025. This is a workaround to ensure
  // button text visibility.
  const renderCloseButton = (variant: string) => {
    return (
      <CloseButton
        placement="end"
        offset="small"
        onClick={() => setModalOpen(false)}
        screenReaderLabel={I18n.t('Close')}
        color={variant === 'inverse' ? 'primary-inverse' : 'primary'}
        elementRef={element => (defaultFocusElement.current = element)}
      />
    )
  }

  return (
    <div>
      <Modal
        label={`${productName} Images`}
        open={isModalOpen}
        size={!isDesktop ? 'fullscreen' : 'large'}
        variant="inverse"
        defaultFocusElement={() => defaultFocusElement.current}
        onDismiss={() => {
          setModalOpen(false)
        }}
      >
        {renderCloseButton('inverse')}

        <Modal.Body>
          <Flex width="90%">
            {!isMobile && (
              <PreviousArrow
                currentSlideNumber={currentSlideNumber}
                slider={slider}
                screenReaderLabel={previousScreenshot}
                isImageCarousel={true}
                itemCount={screenshots.length}
              />
            )}
            <Flex.Item>
              <div style={{position: 'absolute', top: 100, right: 100, zIndex: 10}}>
                <ContextView
                  background="inverse"
                  padding="xxx-small"
                  placement="bottom"
                  themeOverride={{arrowSize: '0'}}
                >
                  <Heading level="h3">
                    {currentSlideNumber + 1} of {screenshots.length}
                  </Heading>
                </ContextView>
              </div>
              <Slider
                ref={slider}
                {...updatedSettings}
                {...customSettings}
                beforeChange={(_currentSlide: number, nextSlide: number) =>
                  setCurrentSlideNumber(nextSlide)
                }
              >
                {renderScreenshots()}
              </Slider>
            </Flex.Item>
            {!isMobile && (
              <NextArrow
                currentSlideNumber={currentSlideNumber}
                slider={slider}
                screenReaderLabel={nextScreenshot}
                isImageCarousel={true}
                itemCount={screenshots.length}
              />
            )}
          </Flex>
          {isMobile && (
            <Flex justifyItems="space-between">
              <Flex.Item>
                <PreviousArrow
                  currentSlideNumber={currentSlideNumber}
                  slider={slider}
                  screenReaderLabel={previousScreenshot}
                  isImageCarousel={true}
                />
              </Flex.Item>
              <Flex.Item margin="0 large 0 0">
                <NextArrow
                  currentSlideNumber={currentSlideNumber}
                  slider={slider}
                  screenReaderLabel={nextScreenshot}
                  isImageCarousel={true}
                />
              </Flex.Item>
            </Flex>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button
            color="primary-inverse"
            withBackground={false}
            onClick={() => setModalOpen(false)}
          >
            {I18n.t('Close')}
          </Button>
        </Modal.Footer>
      </Modal>
    </div>
  )
}

export default ImageCarouselModal
