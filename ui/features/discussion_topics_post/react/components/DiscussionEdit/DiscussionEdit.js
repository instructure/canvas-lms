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

import I18n from 'i18n!discussion_posts'
import React, {useRef, useState, useEffect} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {Responsive} from '@instructure/ui-responsive'
import {Text} from '@instructure/ui-text'
import {responsiveQuerySizes} from '../../utils'
import {View} from '@instructure/ui-view'
import {nanoid} from 'nanoid'
import PropTypes from 'prop-types'
import CanvasRce from '@canvas/rce/react/CanvasRce'
import {name as mentionsPluginName} from '@canvas/rce/plugins/canvas_mentions/plugin'

export const DiscussionEdit = props => {
  const rceRef = useRef()
  const [rceContent, setRceContent] = useState(false)
  const textAreaId = useRef(`message-body-${nanoid()}`)

  const rceMentionsIsEnabled = () => {
    return !!ENV.rce_mentions_in_discussions
  }

  const getPlugins = () => {
    const plugins = []

    // Non-Editable
    plugins.push('noneditable')

    // Mentions
    if (rceMentionsIsEnabled()) {
      plugins.push(mentionsPluginName)
    }

    return plugins
  }

  useEffect(() => {
    setRceContent(props.value)
  }, [props.value, setRceContent])

  return (
    <div
      style={{
        width: '100%',
        // props.show allows you to load an RCE without displaying it which can aleviate load times
        display: props.show ? '' : 'none'
      }}
      data-testid="DiscussionEdit-container"
    >
      <View display="block">
        <span>
          <CanvasRce
            textareaId={textAreaId.current}
            onFocus={() => {}}
            onBlur={() => {}}
            onInit={() => {
              setTimeout(() => {
                rceRef?.current?.focus()
              }, 1500)
            }}
            ref={rceRef}
            onContentChange={content => {
              setRceContent(content)
            }}
            editorOptions={{
              focus: true,
              plugins: getPlugins()
            }}
            height={300}
            defaultContent={props.replyPreview + props.value}
            mirroredAttrs={{'data-testid': 'message-body'}}
          />
        </span>
      </View>
      <Responsive
        match="media"
        query={responsiveQuerySizes({mobile: true, desktop: true})}
        props={{
          mobile: {
            direction: 'column',
            display: 'block',
            margin: 'small 0 0 0'
          },
          desktop: {
            direction: 'row',
            display: 'inline-block',
            margin: '0 0 0 small'
          }
        }}
        render={responsiveProps => (
          <Flex margin="small none none none" direction={responsiveProps.direction}>
            <Flex.Item
              shouldGrow
              shouldShrink
              textAlign="end"
              overflowY="hidden"
              overflowX="hidden"
            >
              <Button
                onClick={() => {
                  if (props.onCancel) {
                    props.onCancel()
                  }
                }}
                display={responsiveProps.display}
                color="secondary"
                data-testid="DiscussionEdit-cancel"
              >
                <Text size="medium">{I18n.t('Cancel')}</Text>
              </Button>
              <Button
                onClick={() => {
                  if (props.onSubmit) {
                    props.onSubmit(rceContent)
                  }
                }}
                display={responsiveProps.display}
                color="primary"
                margin={responsiveProps.margin}
                data-testid="DiscussionEdit-submit"
              >
                <Text size="medium">{props.isEdit ? I18n.t('Save') : I18n.t('Reply')} </Text>
              </Button>
            </Flex.Item>
          </Flex>
        )}
      />
    </div>
  )
}

DiscussionEdit.propTypes = {
  show: PropTypes.bool,
  value: PropTypes.string,
  onCancel: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  isEdit: PropTypes.bool,
  replyPreview: PropTypes.string
}

DiscussionEdit.defaultProps = {
  show: true,
  isEdit: false,
  replyPreview: '',
  value: ''
}

export default DiscussionEdit
