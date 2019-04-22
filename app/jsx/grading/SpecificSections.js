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

import React, {Fragment} from 'react'
import {arrayOf, bool, func, shape, string} from 'prop-types'
import Checkbox from '@instructure/ui-forms/lib/components/Checkbox'
import List, {ListItem} from '@instructure/ui-elements/lib/components/List'
import View from '@instructure/ui-layout/lib/components/View'
import I18n from 'i18n!hide_assignment_grades_tray'

export default function SpecificSections(props) {
  const {checked, disabled, onCheck, sections, sectionSelectionChanged, selectedSectionIds} = props

  return (
    <Fragment>
      <View as="div" margin="small 0 small" padding="0 medium">
        <Checkbox
          checked={checked}
          disabled={disabled}
          label={I18n.t('Specific Sections')}
          onChange={onCheck}
          size="small"
          variant="toggle"
        />
      </View>

      {checked && !disabled && (
        <View
          as="div"
          margin="0 0 small"
          maxHeight="15rem"
          overflowX="hidden"
          overflowY="auto"
          padding="0 0 0 large"
        >
          <List itemSpacing="small" variant="unstyled">
            {sections.map(section => (
              <ListItem key={section.id}>
                <Checkbox
                  checked={selectedSectionIds.includes(section.id)}
                  label={
                    <span
                      style={{
                        hyphens: 'auto',
                        msHyphens: 'auto',
                        overflowWrap: 'break-word',
                        WebkitHyphens: 'auto'
                      }}
                    >
                      {section.name}
                    </span>
                  }
                  onChange={event => {
                    sectionSelectionChanged(event.target.checked, section.id)
                  }}
                />
              </ListItem>
            ))}
          </List>
        </View>
      )}
    </Fragment>
  )
}

SpecificSections.propTypes = {
  checked: bool.isRequired,
  disabled: bool.isRequired,
  onCheck: func.isRequired,
  sections: arrayOf(
    shape({
      id: string.isRequired,
      name: string.isRequired
    })
  ).isRequired,
  sectionSelectionChanged: func.isRequired,
  selectedSectionIds: arrayOf(string).isRequired
}
