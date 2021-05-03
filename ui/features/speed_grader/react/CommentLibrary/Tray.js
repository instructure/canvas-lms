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
import PropTypes from 'prop-types'
import {IconButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-elements'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Tray as InstuiTray} from '@instructure/ui-tray'
import {IconArrowOpenStartLine} from '@instructure/ui-icons'
import {ScreenReaderContent, AccessibleContent} from '@instructure/ui-a11y-content'
import I18n from 'i18n!CommentLibrary'
import Comment from './Comment'
import TrayTextArea from './TrayTextArea'

const Tray = ({isOpen, setIsOpen, onItemClick, comments}) => {
  return (
    <InstuiTray
      size="regular"
      label={I18n.t('Comment Library')}
      placement="end"
      open={isOpen}
      onDismiss={() => setIsOpen(false)}
    >
      <View as="div" padding="small">
        <Flex direction="column" as="div">
          <Flex.Item textAlign="center" as="header">
            <View as="div" padding="small 0 medium xx-small">
              <div style={{float: 'left'}}>
                <IconButton
                  size="small"
                  screenReaderLabel={I18n.t('Close comment library')}
                  renderIcon={IconArrowOpenStartLine}
                  withBorder={false}
                  withBackground={false}
                  onClick={() => setIsOpen(false)}
                />
              </div>
              <View display="inline-block" margin="0 auto">
                <Text weight="bold" size="medium">
                  {I18n.t('Manage Comment Library')}
                </Text>
              </View>
            </View>
            <View
              textAlign="start"
              as="div"
              padding="0 0 medium small"
              borderWidth="none none medium none"
            >
              <AccessibleContent>
                <View as="div" display="inline-block">
                  <Text size="small" weight="bold">
                    {I18n.t('Show suggestions when typing')}
                  </Text>
                </View>
              </AccessibleContent>
              <div style={{display: 'inline-block', float: 'right'}}>
                <Checkbox
                  label={
                    <ScreenReaderContent>
                      {I18n.t('Show suggestions when typing')}
                    </ScreenReaderContent>
                  }
                  value="small"
                  variant="toggle"
                  size="small"
                  inline
                  defaultChecked
                />
              </div>
            </View>
          </Flex.Item>
          <Flex.Item size="65vh" shouldGrow>
            {comments.map(commentItem => (
              <Comment
                key={commentItem._id}
                onClick={onItemClick}
                id={commentItem._id}
                comment={commentItem.comment}
              />
            ))}
          </Flex.Item>
          <Flex.Item padding="medium small small small">
            <TrayTextArea />
          </Flex.Item>
        </Flex>
      </View>
    </InstuiTray>
  )
}

Tray.propTypes = {
  comments: PropTypes.arrayOf(
    PropTypes.shape({
      comment: PropTypes.string.isRequired,
      _id: PropTypes.string.isRequired
    })
  ).isRequired,
  isOpen: PropTypes.bool.isRequired,
  onItemClick: PropTypes.func.isRequired,
  setIsOpen: PropTypes.func.isRequired
}

export default Tray
