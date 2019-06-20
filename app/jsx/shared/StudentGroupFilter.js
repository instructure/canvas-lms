/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {arrayOf, func, shape, string} from 'prop-types'
import Select from '@instructure/ui-core/lib/components/Select'
import I18n from 'i18n!assignment'

// When Canvas updates Instructure-UI to version 6, change <option /> to
// <Select.Option /> and <optgroup /> to <Select.Group />

function renderGroup(group) {
  return (
    <option key={group.id} value={group.id}>
      {group.name}
    </option>
  )
}

function renderCategoryAndChildren(category) {
  return (
    <optgroup label={category.name} key={`group_category_${category.id}`}>
      {category.groups.map(group => renderGroup(group))}
    </optgroup>
  )
}

function StudentGroupFilter(props) {
  return (
    <Select
      label={props.label}
      onChange={(event) => {props.onChange(event.target.value)}}
      value={props.value || "0"}
    >
      <option aria-disabled="true" disabled="disabled" key="0" value="0">
        {I18n.t('Select One')}
      </option>
      {
        props.categories.map(category => (
          renderCategoryAndChildren(category)
        ))
      }
    </Select>
  )
}

StudentGroupFilter.propTypes = {
  categories: arrayOf(shape({
    id: string.isRequired,
    groups: arrayOf(shape({
      id: string.isRequired,
      name: string.isRequired
    })),
    name: string.isRequired
  })),
  label: string.isRequired,
  onChange: func.isRequired,
  value: string
}

export default StudentGroupFilter
