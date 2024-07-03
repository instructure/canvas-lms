/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useState} from 'react'
import type {FilterItem} from '../model/Filter'
import {Checkbox} from '@instructure/ui-checkbox'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Link} from '@instructure/ui-link'

const I18n = useI18nScope('lti_registrations')

export default function FilterOptions(props: {
  categoryName: string
  options: FilterItem[]
  filterIds: string[]
  setFilterValue: (filterItem: FilterItem, value: boolean) => void
  limit?: number
}) {
  const [showMore, setShowMore] = useState(false)
  const capitalizedName = props.categoryName.charAt(0).toUpperCase() + props.categoryName.slice(1)

  return (
    <View as="div" padding="0 0 medium 0">
      <View as="div" padding="0 0 small 0">
        <Heading level="h4" as="h2">
          {capitalizedName}
        </Heading>
      </View>
      {props.options
        .slice(
          0,
          props.limit ? (showMore ? props.options.length : props.limit) : props.options.length
        )
        .map(option => {
          return (
            <View as="div" padding="0 0 x-small 0" key={option.id}>
              <Checkbox
                label={option.name}
                checked={!!props.filterIds && props.filterIds.includes(option.id)}
                onChange={event => {
                  props.setFilterValue(option, event.target.checked)
                }}
                ref={
                  showMore && option.id === props.options[0].id
                    ? checkbox => checkbox && checkbox.focus()
                    : null
                }
              />
            </View>
          )
        })}
      {props.limit && props.options.length > props.limit ? (
        <Link onClick={() => setShowMore(!showMore)}>
          {showMore ? I18n.t('Show less') : I18n.t('Show more')}
        </Link>
      ) : null}
    </View>
  )
}
