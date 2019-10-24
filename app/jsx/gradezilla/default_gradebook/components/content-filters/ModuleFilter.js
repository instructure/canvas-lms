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
import {arrayOf, shape, string} from 'prop-types'

import I18n from 'i18n!gradezilla_default_gradebook_components_content_filters_module_filter'
import ContentFilter from './ContentFilter'

export default function ModuleFilter(props) {
  const {modules, selectedModuleId, ...filterProps} = props

  return (
    <ContentFilter
      {...filterProps}
      allItemsId="0"
      allItemsLabel={I18n.t('All Modules')}
      items={modules}
      label={I18n.t('Module Filter')}
      selectedItemId={selectedModuleId}
      sortAlphabetically
    />
  )
}

ModuleFilter.propTypes = {
  modules: arrayOf(
    shape({
      id: string.isRequired,
      name: string.isRequired
    })
  ).isRequired,

  selectedModuleId: string
}

ModuleFilter.defaultProps = {
  selectedModuleId: null
}
