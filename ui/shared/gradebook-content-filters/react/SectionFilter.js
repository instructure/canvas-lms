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

import {useScope as useI18nScope} from '@canvas/i18n'
import ContentFilter from './ContentFilter'

const I18n = useI18nScope('gradebook_default_gradebook_components_content_filters_section_filter')

export default function SectionFilter(props) {
  const {sections, selectedSectionId, ...filterProps} = props

  return (
    <ContentFilter
      {...filterProps}
      allItemsId="0"
      allItemsLabel={I18n.t('All Sections')}
      items={sections}
      label={I18n.t('Section Filter')}
      selectedItemId={selectedSectionId}
      sortAlphabetically={true}
    />
  )
}

SectionFilter.propTypes = {
  sections: arrayOf(
    shape({
      id: string.isRequired,
      name: string.isRequired,
    })
  ).isRequired,

  selectedSectionId: string,
}

SectionFilter.defaultProps = {
  selectedSectionId: null,
}
