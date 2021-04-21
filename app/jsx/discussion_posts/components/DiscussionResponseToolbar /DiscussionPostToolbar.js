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
import {Button} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {TextInput} from '@instructure/ui-text-input'
import {
  IconArrowDownLine,
  IconArrowUpLine,
  IconCircleArrowUpLine,
  IconSearchLine
} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import I18n from 'i18n!discussions_posts'

export const ViewOptions = {
  all: () => I18n.t('All'),
  read: () => I18n.t('Read'),
  unread: () => I18n.t('Unread'),
  graded: () => I18n.t('Graded'),
  ungraded: () => I18n.t('Ungraded'),
  deleted: () => I18n.t('Deleted')
}

const DiscussionPostToolbar = props => {
  return (
    <View maxWidth="56.875em">
      <Flex width="100%">
        <Flex.Item align="start" shouldGrow>
          <FormFieldGroup
            description={<ScreenReaderContent>{I18n.t('Checkbox examples')}</ScreenReaderContent>}
            vAlign="middle"
            layout="columns"
          >
            <TextInput
              onChange={props.onSearchChange}
              renderLabel={
                <ScreenReaderContent>{I18n.t('Search entries or author')}</ScreenReaderContent>
              }
              renderBeforeInput={<IconSearchLine inline={false} />}
              placeholder={I18n.t('Search entries or author...')}
              shouldNotWrap
              width="308px"
            />

            <SimpleSelect
              renderLabel={<ScreenReaderContent>{I18n.t('Filter by')}</ScreenReaderContent>}
              defaultValue={props.selectedView}
              onChange={props.onViewFilter}
              width="120px"
            >
              <SimpleSelect.Group renderLabel={I18n.t('View')}>
                {Object.entries(ViewOptions).map(([viewOption, viewOptionLabel]) => (
                  <SimpleSelect.Option id={viewOption} key={viewOption} value={viewOption}>
                    {viewOptionLabel.call()}
                  </SimpleSelect.Option>
                ))}
              </SimpleSelect.Group>
            </SimpleSelect>

            <Tooltip
              renderTip={
                props.sortDirection === 'asc' ? I18n.t('Newest First') : I18n.t('Oldest First')
              }
              width="78px"
              data-testid="sortButtonTooltip"
            >
              <Button
                onClick={props.onSortClick}
                renderIcon={
                  props.sortDirection === 'asc' ? (
                    <IconArrowDownLine data-testid="DownArrow" />
                  ) : (
                    <IconArrowUpLine data-testid="UpArrow" />
                  )
                }
                data-testid="sortButton"
              >
                {I18n.t('Sort')}
                <ScreenReaderContent>
                  {props.sortDirection === 'asc'
                    ? I18n.t('Sorted by Ascending')
                    : I18n.t('Sorted by Descending')}
                </ScreenReaderContent>
              </Button>
            </Tooltip>

            <Checkbox
              label={I18n.t('Collapse Replies')}
              variant="toggle"
              size="small"
              defaultChecked={props.isCollapsedReplies}
              onChange={props.onCollapseRepliesToggle}
              data-testid="collapseToggle"
            />
          </FormFieldGroup>
        </Flex.Item>
        <Flex.Item align="end">
          <FormFieldGroup
            description={<ScreenReaderContent>{I18n.t('Checkbox examples')}</ScreenReaderContent>}
            vAlign="middle"
            layout="columns"
          >
            <Button
              onClick={props.onTopClick}
              renderIcon={<IconCircleArrowUpLine />}
              data-testid="topButton"
            >
              {I18n.t('Top')}
            </Button>
          </FormFieldGroup>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default DiscussionPostToolbar

DiscussionPostToolbar.propTypes = {
  selectedView: PropTypes.string,
  sortDirection: PropTypes.string,
  isCollapsedReplies: PropTypes.bool,
  onSearchChange: PropTypes.func,
  onViewFilter: PropTypes.func,
  onSortClick: PropTypes.func,
  onCollapseRepliesToggle: PropTypes.func,
  onTopClick: PropTypes.func
}

DiscussionPostToolbar.defaultProps = {
  sortDirection: 'asc'
}
