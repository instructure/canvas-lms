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
import {View} from '@instructure/ui-view'
import {nanoid} from 'nanoid'
import PropTypes from 'prop-types'
import CanvasRce from '@canvas/rce/react/CanvasRce'
import {name} from '@canvas/rce/plugins/canvas_mentions/plugin'

export const DiscussionEdit = props => {
  const rceRef = useRef()
  const [rceContent, setRceContent] = useState(false)
  const textAreaId = useRef(`message-body-${nanoid()}`)

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
              plugins: [name] // Needed for when RCE uses editorOptions for Plugin loading
            }}
            plugins={[name]} // Short term fix to get plugin from ReactRCE to CqnvasRCE
            height={300}
            defaultContent={props.value}
            mirroredAttrs={{'data-testid': 'message-body'}}
          />
        </span>
      </View>
      <Flex margin="small none none none">
        <Flex.Item shouldGrow shouldShrink textAlign="end">
          <Button
            onClick={() => {
              if (props.onCancel) {
                props.onCancel()
              }
            }}
            display="inline-block"
            color="secondary"
            data-testid="DiscussionEdit-cancel"
          >
            {I18n.t('Cancel')}
          </Button>
          <Button
            onClick={() => {
              if (props.onSubmit) {
                props.onSubmit(rceContent)
              }
            }}
            display="inline-block"
            color="primary"
            margin="none none none small"
            data-testid="DiscussionEdit-submit"
          >
            {props.isEdit ? I18n.t('Save') : I18n.t('Reply')}
          </Button>
        </Flex.Item>
      </Flex>
    </div>
  )
}

DiscussionEdit.propTypes = {
  show: PropTypes.bool,
  value: PropTypes.string,
  onCancel: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  isEdit: PropTypes.bool
}

DiscussionEdit.defaultProps = {
  show: true,
  isEdit: false
}

export default DiscussionEdit
