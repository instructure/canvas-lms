/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {useState, useEffect, useCallback} from 'react'
import {Menu} from '@instructure/ui-menu'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {IconArrowOpenDownLine, IconArrowOpenUpLine} from '@instructure/ui-icons'
import {debounce} from 'lodash'
import {DEFAULT_SEARCH_DELAY} from '../utils/constants'

const I18n = useI18nScope('discussion_topics_post')

interface SelectedObject {
  value: string
  id: string
}

type Props = {
  name: string
  filters: Record<string, string>
  defaultSelectedFilter: string
  onSelectFilter: (data: SelectedObject) => void
  filterDelay?: number
}

export const HeadingMenu: React.FC<Props> = ({
  name,
  filters,
  defaultSelectedFilter,
  onSelectFilter,
  filterDelay = DEFAULT_SEARCH_DELAY,
}) => {
  const [filter_opened, setFilterOpened] = useState<boolean>(false)
  const [selected_filter, setSelectedFilter] = useState<string>(defaultSelectedFilter)

  const debouncedFilter = useCallback(
    debounce(
      (filter: string) => {
        onSelectFilter({value: filter, id: filter})
      },
      filterDelay,
      {
        leading: false,
        trailing: true,
      }
    ),
    [onSelectFilter]
  )

  const handleFilterSelect = (filter: string) => {
    setSelectedFilter(filter)
    onSelectFilter({value: filter, id: filter})
  }

  useEffect(() => {
    return () => {
      debouncedFilter.cancel()
    }
  }, [debouncedFilter])

  return (
    <Flex
      as="div"
      direction="row"
      justifyItems="start"
      alignItems="center"
      width="98%"
      data-testid="heading-menu"
    >
      <Flex.Item margin="0 x-small 0 0">
        <Heading level="h1">{filters[selected_filter]}</Heading>
      </Flex.Item>
      <Flex.Item>
        <Menu
          trigger={
            <IconButton
              size="small"
              withBackground={false}
              withBorder={false}
              renderIcon={filter_opened ? <IconArrowOpenUpLine /> : <IconArrowOpenDownLine />}
              screenReaderLabel={name}
              data-testid="toggle-filter-menu"
            />
          }
          onToggle={() => setFilterOpened(!filter_opened)}
        >
          <Menu.Group
            selected={[selected_filter]}
            onSelect={(_, selected) => {
              handleFilterSelect(selected[0] as string)
            }}
            label={I18n.t('View')}
            data-testid="filter-menu"
          >
            {Object.keys(filters).map(filter => (
              <Menu.Item key={filter} value={filter} data-testid={`menu-filter-${filter}`}>
                {filters[filter]}
              </Menu.Item>
            ))}
          </Menu.Group>
        </Menu>
      </Flex.Item>
    </Flex>
  )
}
