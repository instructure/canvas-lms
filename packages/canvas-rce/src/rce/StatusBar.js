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
import {StyleSheet, css} from "aphrodite";

import { Button } from '@instructure/ui-buttons'
import { Flex, View } from '@instructure/ui-layout'
import { ScreenReaderContent } from '@instructure/ui-a11y'
import { Text } from '@instructure/ui-elements'
import { Select } from '@instructure/ui-forms'

import { IconA11yLine, IconKeyboardShortcutsLine } from '@instructure/ui-icons'
import {SVGIcon} from '@instructure/ui-svg-images';

import formatMessage from '../format-message'

StatusBar.propTypes = {
  onToggleHtml: func
}

function emptyTagIcon() {
  return (
    <SVGIcon viewBox="0 0 24 24" fontSize="24px">
      <g role="presentation">
        <text textAnchor="start" x="0" y="18px" fontSize="16">&lt;/&gt;</text>
      </g>
    </SVGIcon>
  )
}
export default function StatusBar(props) {
  return (
    <div>
      <Flex margin="x-small">
        <Flex.Item grow>
          <View>
            <Text>p</Text>
          </View>
        </Flex.Item>
        <Flex.Item>
          <View display="inline-block" padding="0 x-small">
            <Button variant="link" icon={IconKeyboardShortcutsLine}>
              <ScreenReaderContent>{formatMessage('View keyboard shortcuts')}</ScreenReaderContent>
            </Button>
            <Button variant="link" icon={IconA11yLine}>
              <ScreenReaderContent>{formatMessage('Accessibility')}</ScreenReaderContent>
            </Button>
          </View>
          <div className={css(styles.separator)}/>
        </Flex.Item>
        <Flex.Item>
          <View display="inline-block" padding="0 x-small">
            <Button variant="link" icon={emptyTagIcon()} onClick={props.onToggleHtml}>
              <ScreenReaderContent>{formatMessage('Toggle raw html view')}</ScreenReaderContent>
            </Button>
          </View>
          <div className={css(styles.separator)}/>
        </Flex.Item>
        <Flex.Item>
          <View display="inline-block" padding="0 x-small xxx-small x-small">
            <Select
              inline
              width="12rem"
              size="small"
              label={<ScreenReaderContent>Select a language</ScreenReaderContent>}
            >
              <option value="en-us">English (US)</option>
              <option value="fr">French</option>
            </Select>
          </View>
          <div className={css(styles.separator)}/>
        </Flex.Item>
        <Flex.Item>
          <View display="inline-block" padding="0 0 0 small">
            <Text size="small">42 words</Text>
          </View>
        </Flex.Item>
      </Flex>
    </div>
  )
}


const styles = StyleSheet.create({
  separator: {
    display: 'inline-block',
    'box-sizing': 'border-box',
    'border-right': '1px solid #ccc',
    width: '1px',
    height: '1.5rem',
    position: 'relative',
    top: '.5rem'
  }
});
