/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Billboard} from '@instructure/ui-billboard'
import {PresentationContent} from '@instructure/ui-a11y-content'
import SVGWrapper from '@canvas/svg-wrapper'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'

const I18n = useI18nScope('FindOutcomesModal')

const FindOutcomesBillboard = () => {
  const {isCourse, isMobileView} = useCanvasContext()

  return (
    <Flex as="div" height={isMobileView ? '' : '100%'} direction="row" justifyItems="center">
      <Flex.Item margin="auto">
        <Billboard
          size="small"
          heading={isCourse ? I18n.t('PRO TIP!') : ''}
          headingLevel="h3"
          headingAs="h3"
          hero={
            <PresentationContent>
              {isCourse ? (
                <div data-testid="clipboard-checklist-icon">
                  <SVGWrapper
                    url={
                      isMobileView
                        ? '/images/outcomes/find_outcomes_mobile.svg'
                        : '/images/outcomes/clipboard_checklist.svg'
                    }
                  />
                </div>
              ) : (
                <div
                  style={{transform: isMobileView ? '' : 'scale(1.7)'}}
                  data-testid="outcomes-icon"
                >
                  <SVGWrapper url="/images/outcomes/outcomes.svg" />
                </div>
              )}
            </PresentationContent>
          }
          message={
            <View
              as="div"
              padding="small 0 xx-large"
              margin="0 auto"
              width={isCourse ? '60%' : '100%'}
            >
              <Text size="large" color="primary">
                {isCourse
                  ? I18n.t(
                      'Save yourself a lot of time by only adding the outcomes that are specific to your course content.'
                    )
                  : I18n.t('Select a group to reveal outcomes here.')}
              </Text>
            </View>
          }
        />
      </Flex.Item>
    </Flex>
  )
}

export default FindOutcomesBillboard
