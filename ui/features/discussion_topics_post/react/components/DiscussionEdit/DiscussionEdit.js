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
import React, {useEffect} from 'react'
import {useDiscussionRCE} from './useDiscussionRCE'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import PropTypes from 'prop-types'

export const DiscussionEdit = props => {
  const [setRCERef, getRCEText, setRCEText] = useDiscussionRCE()

  // Load text into RCE when Value updates
  useEffect(() => {
    setRCEText(props.value)
  }, [props.value, setRCEText])

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
        <textarea ref={setRCERef} />
      </View>
      <Flex margin="small none none none">
        <Flex.Item shouldGrow shouldShrink textAlign="end">
          <Button
            onClick={props.onCancel}
            display="inline-block"
            color="secondary"
            data-testid="DiscussionEdit-cancel"
          >
            {I18n.t('Cancel')}
          </Button>
          <Button
            onClick={() => {
              props.onSubmit(getRCEText())
            }}
            display="inline-block"
            color="primary"
            margin="none none none small"
            data-testid="DiscussionEdit-submit"
          >
            {I18n.t('Reply')}
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
  onSubmit: PropTypes.func.isRequired
}

DiscussionEdit.defaultProps = {
  show: true
}

export default DiscussionEdit
