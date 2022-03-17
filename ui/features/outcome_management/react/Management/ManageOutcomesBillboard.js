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
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Billboard} from '@instructure/ui-billboard'
import {PresentationContent} from '@instructure/ui-a11y-content'
import SVGWrapper from '@canvas/svg-wrapper'

const I18n = useI18nScope('FindOutcomesModal')

const ManageOutcomesBillboard = () => (
  <Flex as="div" height="50vh">
    <Flex.Item margin="auto">
      <Billboard
        size="small"
        hero={
          <PresentationContent>
            <div style={{display: 'inline-block', transform: 'scale(1.5)'}}>
              <SVGWrapper url="/images/outcomes/outcomes.svg" />
            </div>
          </PresentationContent>
        }
        message={
          <View as="div" padding="small 0 x-large" width="100%">
            <Text size="large" color="primary">
              {I18n.t('Select a group to reveal outcomes here.')}
            </Text>
          </View>
        }
      />
    </Flex.Item>
  </Flex>
)

export default ManageOutcomesBillboard
