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
import I18n from 'i18n!FindOutcomesModal'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Billboard} from '@instructure/ui-billboard'
import {PresentationContent} from '@instructure/ui-a11y'
import SVGWrapper from '../shared/SVGWrapper'

const FindOutcomesBillboard = () => (
  <Flex as="div" height="100%">
    <Flex.Item margin="auto">
      <Billboard
        size="small"
        heading={I18n.t('PRO TIP!')}
        headingLevel="h3"
        headingAs="h3"
        hero={
          <PresentationContent>
            <SVGWrapper url="/images/outcomes/clipboard_checklist.svg" />
          </PresentationContent>
        }
        message={
          <View as="div" padding="small 0 xx-large" margin="0 auto" width="60%">
            <Text size="large" color="primary">
              {I18n.t(
                'Save yourself a lot of time by only adding the outcomes that are specific to your course content.'
              )}
            </Text>
          </View>
        }
      />
    </Flex.Item>
  </Flex>
)

export default FindOutcomesBillboard
