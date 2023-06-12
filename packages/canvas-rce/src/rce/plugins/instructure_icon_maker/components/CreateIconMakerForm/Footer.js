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

import {Button} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'

import formatMessage from '../../../../../format-message'
import {ConditionalTooltip} from '../../../shared/ConditionalTooltip'

export const Footer = ({
  disabled,
  onCancel,
  onSubmit,
  replaceAll,
  onReplaceAllChanged,
  editing,
  isModified,
  applyRef,
}) => {
  return (
    <>
      {editing && (
        <View as="div" padding="medium">
          <Checkbox
            label={formatMessage(
              'Apply changes to all instances of this Icon Maker Icon in the Course'
            )}
            data-testid="cb-replace-all"
            checked={replaceAll}
            onChange={e => {
              onReplaceAllChanged && onReplaceAllChanged(e.target.checked)
            }}
          />
        </View>
      )}
      <View
        as="div"
        background="secondary"
        borderWidth={editing ? 'small none none none' : 'none'}
        padding="small small x-small none"
      >
        <Flex>
          <Flex.Item shouldGrow={true} shouldShrink={true} />
          <Flex.Item>
            <Button disabled={disabled} onClick={onCancel} data-testid="icon-maker-cancel">
              {formatMessage('Cancel')}
            </Button>
            {editing ? (
              <ConditionalTooltip
                condition={!isModified && !disabled}
                renderTip={formatMessage('No changes to save.')}
                on={['hover', 'focus']}
              >
                <Button
                  disabled={!isModified || disabled}
                  color="primary"
                  onClick={onSubmit}
                  margin="0 0 0 x-small"
                  data-testid="icon-maker-save"
                >
                  {replaceAll ? formatMessage('Save') : formatMessage('Save Copy')}
                </Button>
              </ConditionalTooltip>
            ) : (
              <Button
                disabled={disabled}
                margin="0 0 0 x-small"
                color="primary"
                onClick={onSubmit}
                data-testid="create-icon-button"
                elementRef={ref => {
                  if (applyRef) applyRef.current = ref
                }}
              >
                {formatMessage('Apply')}
              </Button>
            )}
          </Flex.Item>
        </Flex>
      </View>
    </>
  )
}
