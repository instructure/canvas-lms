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
import {arrayOf, bool, func, shape, string} from 'prop-types'

import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'

import {useScope as useI18nScope} from '@canvas/i18n'

import Description from './Description'
import SpecificSections from '@canvas/grading/react/SpecificSections'

const I18n = useI18nScope('hide_assignment_grades_tray')

export default function FormContent({
  assignment: {anonymousGrading, gradesPublished},
  dismiss,
  onHideClick,
  hideBySections,
  hideBySectionsChanged,
  hidingGrades,
  sectionSelectionChanged,
  sections,
  selectedSectionIds,
}) {
  if (hidingGrades) {
    return (
      <View as="div" textAlign="center" padding="large">
        <Spinner renderTitle={I18n.t('Hiding grades')} size="large" />
      </View>
    )
  }

  const hasSections = sections.length > 0

  return (
    <>
      {hasSections && (
        <SpecificSections
          checked={hideBySections}
          disabled={!gradesPublished || anonymousGrading}
          onCheck={event => {
            hideBySectionsChanged(event.target.checked)
          }}
          sections={sections}
          sectionSelectionChanged={sectionSelectionChanged}
          selectedSectionIds={selectedSectionIds}
        />
      )}

      <View as="div" margin="0 medium" className="hr" />

      <View as="div" margin="medium 0" padding="0 medium">
        <Description />
      </View>

      <View as="div" margin="0 medium" className="hr" />

      <View as="div" margin="medium 0 0" padding="0 medium">
        <Flex justifyItems="end">
          <Flex.Item margin="0 small 0 0">
            <Button onClick={dismiss} disabled={!gradesPublished}>
              {I18n.t('Close')}
            </Button>
          </Flex.Item>

          <Flex.Item>
            <Button onClick={onHideClick} disabled={!gradesPublished} color="primary">
              {I18n.t('Hide')}
            </Button>
          </Flex.Item>
        </Flex>
      </View>
    </>
  )
}

FormContent.propTypes = {
  assignment: shape({
    anonymousGrading: bool.isRequired,
    gradesPublished: bool.isRequired,
  }).isRequired,
  dismiss: func.isRequired,
  hideBySections: bool.isRequired,
  hideBySectionsChanged: func.isRequired,
  hidingGrades: bool.isRequired,
  onHideClick: func.isRequired,
  sections: arrayOf(
    shape({
      id: string.isRequired,
      name: string.isRequired,
    })
  ).isRequired,
  sectionSelectionChanged: func.isRequired,
  selectedSectionIds: arrayOf(string).isRequired,
}
