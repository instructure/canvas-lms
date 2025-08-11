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

import {useState} from 'react'
import {Flex} from '@instructure/ui-flex'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Alert} from '@instructure/ui-alerts'
import {Checkbox, CheckboxGroup} from '@instructure/ui-checkbox'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'

const I18n = createI18nScope('SmartSearch')

interface Props {
  handleCloseTray: () => void
  updateFilters: (sources: (string | number)[]) => void
  filters: (string | number)[]
}

export const ALL_SOURCES = ['all', 'assignments', 'announcements', 'discussion_topics', 'pages']

export default function SmartSearchFilters(props: Props) {
  const [checkedSources, setCheckedSources] = useState<(string | number)[]>(props.filters)
  const [reset, setReset] = useState(false)

  const handleCheckboxChange = (values: (string | number)[]) => {
    const allSelected = values.includes('all') && !checkedSources.includes('all')
    const allDeselected = !values.includes('all') && checkedSources.includes('all')
    if (allSelected) {
      // 'all' was selected => select all sources
      setCheckedSources(ALL_SOURCES)
    } else if (allDeselected) {
      // 'all' was deselected => deselect all sources
      setCheckedSources([])
    } else if (values.length === ALL_SOURCES.length - 1 && !values.includes('all')) {
      // if all sources except 'all' are selected, we can consider it as 'all'
      setCheckedSources(ALL_SOURCES)
    } else if (values.length === 1 && values.includes('all')) {
      // if 'all' is the only source selected, none are checked
      setCheckedSources([])
    } else {
      setCheckedSources(values)
    }
    setReset(false)
  }

  const handleResetFilters = () => {
    setCheckedSources(ALL_SOURCES)
    setReset(true)
  }

  return (
    <Flex
      as="form"
      onSubmit={e => {
        e.preventDefault()
        if (checkedSources.length === ALL_SOURCES.length) {
          // if all sources are selected, we can include 'all'
          props.updateFilters(checkedSources)
        } else {
          // don't include 'all' if we are mixed
          props.updateFilters(checkedSources.filter(source => source !== 'all'))
        }
      }}
      direction="column"
      padding="modalElements modalElements 0"
      height="100vh"
    >
      <Flex justifyItems="space-between">
        <Heading variant="titleSection" level="h2">
          {I18n.t('Filters')}
        </Heading>
        <CloseButton
          onClick={props.handleCloseTray}
          screenReaderLabel={I18n.t('Close filters tray')}
        />
      </Flex>
      <Flex.Item shouldGrow shouldShrink>
        {reset && (
          <Alert screenReaderOnly isLiveRegionAtomic liveRegion={getLiveRegion}>
            {I18n.t('Filters have been reset to defaults')}
          </Alert>
        )}
        <Flex direction="column" gap="inputFields" padding="sectionElements space8">
          <Heading variant="titleCardRegular" level="h3">
            {I18n.t('Sources')}
          </Heading>
          <CheckboxGroup
            name="sources"
            onChange={handleCheckboxChange}
            value={checkedSources}
            description={
              <ScreenReaderContent>
                {I18n.t('Select sources to include in the search')}
              </ScreenReaderContent>
            }
          >
            <Checkbox
              data-testid="all-sources-checkbox"
              key="all"
              label={I18n.t('All sources')}
              value="all"
              indeterminate={
                checkedSources.length < ALL_SOURCES.length && checkedSources.length > 0
              }
            />
            <Checkbox
              key="assignments"
              label={I18n.t('Assignments')}
              value="assignments"
              data-testid="assignments-checkbox"
            />
            <Checkbox
              key="announcements"
              label={I18n.t('Announcements')}
              value="announcements"
              data-testid="announcements-checkbox"
            />
            <Checkbox
              key="discussion_topics"
              label={I18n.t('Discussions')}
              value="discussion_topics"
              data-testid="discussion-topics-checkbox"
            />
            <Checkbox
              key="pages"
              label={I18n.t('Pages')}
              value="pages"
              data-testid="pages-checkbox"
            />
          </CheckboxGroup>
        </Flex>
      </Flex.Item>
      <Flex.Item align="end">
        <Flex gap="buttons" margin="buttons">
          <Button color="secondary" onClick={handleResetFilters} data-testid="reset-filters-button">
            {I18n.t('Reset to defaults')}
          </Button>
          <Button type="submit" data-testid="apply-filters-button" color="primary">
            {I18n.t('Apply')}
          </Button>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}
