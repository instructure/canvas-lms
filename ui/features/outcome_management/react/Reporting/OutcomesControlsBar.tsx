/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {IconEndSolid, IconSearchLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconButton} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {MasteryFilter} from './types'

const I18n = createI18nScope('outcome_reporting')

interface OutcomesControlsBarProps {
  search: string
  onSearchChangeHandler: (event: React.ChangeEvent<HTMLInputElement>) => void
  onSearchClearHandler: () => void
  masteryFilter: MasteryFilter
  onMasteryFilterChange: (filter: MasteryFilter) => void
}

const OutcomesControlsBar = ({
  search,
  onSearchChangeHandler,
  onSearchClearHandler,
  masteryFilter,
  onMasteryFilterChange,
}: OutcomesControlsBarProps) => {
  return (
    <View as="div" padding="small 0">
      <Flex gap="small" alignItems="end">
        <Flex.Item width="16rem">
          <SimpleSelect
            data-testid="mastery-filter-select"
            renderLabel={<ScreenReaderContent>{I18n.t('Filter by mastery')}</ScreenReaderContent>}
            value={masteryFilter}
            onChange={(_e, data) => onMasteryFilterChange(data.value as MasteryFilter)}
          >
            <SimpleSelect.Option id="all" value="all">
              {I18n.t('Show All')}
            </SimpleSelect.Option>
            <SimpleSelect.Option id="mastery" value="mastery">
              {I18n.t('At or above Mastery')}
            </SimpleSelect.Option>
            <SimpleSelect.Option id="not_started" value="not_started">
              {I18n.t('Not Started')}
            </SimpleSelect.Option>
            <SimpleSelect.Option id="in_progress" value="in_progress">
              {I18n.t('In Progress')}
            </SimpleSelect.Option>
          </SimpleSelect>
        </Flex.Item>
        <Flex.Item shouldGrow={true}>
          <TextInput
            data-testid="search-input"
            renderLabel={<ScreenReaderContent>{I18n.t('Search outcomes')}</ScreenReaderContent>}
            placeholder={I18n.t('Search...')}
            type="search"
            value={search}
            onChange={onSearchChangeHandler}
            renderBeforeInput={<IconSearchLine inline={false} />}
            renderAfterInput={
              search ? (
                <IconButton
                  size="small"
                  screenReaderLabel={I18n.t('Clear search field')}
                  withBackground={false}
                  withBorder={false}
                  onClick={onSearchClearHandler}
                >
                  <IconEndSolid size="x-small" data-testid="clear-search-icon" />
                </IconButton>
              ) : null
            }
          />
        </Flex.Item>
        <Flex.Item width="8rem">
          {/* Placeholder for action buttons */}
          <View as="div" padding="x-small"></View>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default OutcomesControlsBar
