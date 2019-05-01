/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {func} from 'prop-types'

import Button from '@instructure/ui-buttons/lib/components/Button'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import PresentationContent from '@instructure/ui-a11y/lib/components/PresentationContent'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Text from '@instructure/ui-elements/lib/components/Text'
import Select from '@instructure/ui-forms/lib/components/Select'
import View from '@instructure/ui-layout/lib/components/View'

import IconA11y from '@instructure/ui-icons/lib/Line/IconA11y'
import IconKeyboardShortcuts from '@instructure/ui-icons/lib/Line/IconKeyboardShortcuts'

import formatMessage from '../format-message'

StatusBar.propTypes = {
  onToggleHtml: func
}

export default function StatusBar(props) {
  return (
    <div>
      <Flex margin="small 0 0 0">
        <FlexItem grow>
          <View>
            <Text>p</Text>
          </View>
        </FlexItem>
        <FlexItem>
          <View padding="small" borderWidth="0 small 0 0">
            <Button variant="link" icon={IconKeyboardShortcuts}>
              <ScreenReaderContent>{formatMessage('View keyboard shortcuts')}</ScreenReaderContent>
            </Button>
            <Button variant="link" icon={IconA11y}>
              <ScreenReaderContent>{formatMessage('Accessibility')}</ScreenReaderContent>
            </Button>
          </View>
        </FlexItem>
        <FlexItem>
          <View padding="small" borderWidth="0 small 0 0">
            <Button variant="link" onClick={props.onToggleHtml}>
              <PresentationContent>{'</>'}</PresentationContent>
              <ScreenReaderContent>{formatMessage('Toggle raw html view')}</ScreenReaderContent>
            </Button>
          </View>
        </FlexItem>
        <FlexItem>
          <View padding="small" borderWidth="0 small 0 0">
            <Select
              inline
              width="12rem"
              label={<ScreenReaderContent>Select a language</ScreenReaderContent>}
            >
              <option value="en-us">English (US)</option>
              <option value="fr">French</option>
            </Select>
          </View>
        </FlexItem>
        <FlexItem>
          <View padding="small 0 small small">
            <Text>42 words</Text>
          </View>
        </FlexItem>
      </Flex>
    </div>
  )
}
