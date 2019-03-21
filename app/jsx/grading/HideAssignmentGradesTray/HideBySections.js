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
import Text from '@instructure/ui-elements/lib/components/Text'
import View from '@instructure/ui-layout/lib/components/View'
import I18n from 'i18n!hide_assignment_grades_tray'

export default function HideBySections(props) {
  const {
    assignment,
    hideBySections,
    hideBySectionsChanged,
    sections,
    sectionSelectionChanged,
    selectedSectionIds
  } = props
  const {anonymizeStudents} = assignment

  return (
    <Fragment>
      {anonymizeStudents && (
        <View as="p" margin="small 0 small" padding="0 medium">
          <Text>{I18n.t('Anonymous assignments cannot be hidden by section.')}</Text>
        </View>
      )}

      <View as="div" margin="small 0 small" padding="0 medium">
        <Checkbox
          checked={hideBySections}
          disabled={anonymizeStudents}
          label={I18n.t('Specific Sections')}
          onChange={hideBySectionsChanged}
          size="small"
          variant="toggle"
        />
      </View>

      {hideBySections && !anonymizeStudents && (
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

HideBySections.propTypes = {
  assignment: shape({
    anonymizeStudents: bool.isRequired,
    gradesPublished: bool.isRequired
  }).isRequired,
  hideBySections: bool.isRequired,
  hideBySectionsChanged: func.isRequired,
  sections: arrayOf(
    shape({
      id: string.isRequired,
      name: string.isRequired
    })
  ).isRequired,
  sectionSelectionChanged: func.isRequired,
  selectedSectionIds: arrayOf(string).isRequired
}
