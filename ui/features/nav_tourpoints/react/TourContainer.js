/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {CloseButton, Button} from '@instructure/ui-buttons'
import I18n from 'i18n!TourPoints'

const TourContainer = ({
  current,
  totalSteps,
  gotoStep,
  close,
  firstLabel,
  softClose = close,
  content
}) => {
  const closeButtonRef = React.useRef()
  const focusRef = React.useRef()
  React.useEffect(() => {
    // Make sure this is visible to screen readers
    const tourElement = document.getElementById('___reactour')
    if (tourElement) {
      tourElement.setAttribute('aria-hidden', false)
    }
    // Focus the close button by default
    if (closeButtonRef.current) {
      closeButtonRef.current.focus()
    }
  })

  return (
    <div
      role="none"
      onClick={e => {
        // Stop the event from bubbling up.
        // This keeps trays from closing too soon.
        e.stopPropagation()
      }}
    >
      <View
        as="div"
        padding="medium"
        elementRef={el => (focusRef.current = el)}
        position="relative"
        borderRadius="small"
        shadow="topmost"
      >
        <View className="tour-close-button">
          <CloseButton
            elementRef={el => (closeButtonRef.current = el)}
            placement="end"
            offset="small"
            screenReaderLabel={I18n.t('Close')}
            onClick={close}
          />
        </View>
        {content}
        <Flex margin="medium 0 0 0">
          <Flex.Item shouldGrow>
            {current === 0 ? (
              firstLabel
            ) : (
              <p>{I18n.t('%{current} of %{totalSteps}', {current, totalSteps: totalSteps - 1})}</p>
            )}
          </Flex.Item>
          <Flex.Item>
            {current > 0 && (
              <Button margin="0 small 0 0" onClick={() => gotoStep(current - 1)}>
                {I18n.t('Previous')}
              </Button>
            )}
            {current > 0 && current < totalSteps - 1 ? (
              <Button variant="primary" onClick={() => gotoStep(current + 1)}>
                {I18n.t('Next')}
              </Button>
            ) : null}
            {current === totalSteps - 1 && (
              <Button variant="primary" onClick={() => close({forceClose: true})}>
                {I18n.t('Done')}
              </Button>
            )}
            {current === 0 && totalSteps > 1 && (
              <Button margin="0 small 0 0" onClick={softClose}>
                {I18n.t('Not Now')}
              </Button>
            )}
            {current === 0 && totalSteps > 1 && (
              <Button variant="primary" onClick={() => gotoStep(1)}>
                {I18n.t('Start Tour')}
              </Button>
            )}
          </Flex.Item>
        </Flex>
      </View>
    </div>
  )
}

export default TourContainer
