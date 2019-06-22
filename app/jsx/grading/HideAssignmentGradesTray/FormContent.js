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

import Button from '@instructure/ui-buttons/lib/components/Button'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import View from '@instructure/ui-layout/lib/components/View'

import I18n from 'i18n!hide_assignment_grades_tray'

import Description from './Description'
import SpecificSections from '../SpecificSections'

export default function FormContent({
  assignment: {anonymousGrading, gradesPublished},
  dismiss,
  onHideClick,
  hideBySections,
  hideBySectionsChanged,
  hidingGrades,
  sectionSelectionChanged,
  sections,
  selectedSectionIds
}) {
  if (hidingGrades) {
    return (
      <View as="div" textAlign="center" padding="large">
        <Spinner title={I18n.t('Hiding grades')} size="large" />
      </View>
    )
  }

  const hasSections = sections.length > 0

  return (
    <Fragment>
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
          <FlexItem margin="0 small 0 0">
            <Button onClick={dismiss} disabled={!gradesPublished}>
              {I18n.t('Close')}
            </Button>
          </FlexItem>

          <FlexItem>
            <Button onClick={onHideClick} disabled={!gradesPublished} variant="primary">
              {I18n.t('Hide')}
            </Button>
          </FlexItem>
        </Flex>
      </View>
    </Fragment>
  )
}

FormContent.propTypes = {
  assignment: shape({
    anonymousGrading: bool.isRequired,
    gradesPublished: bool.isRequired
  }).isRequired,
  dismiss: func.isRequired,
  hideBySections: bool.isRequired,
  hideBySectionsChanged: func.isRequired,
  hidingGrades: bool.isRequired,
  onHideClick: func.isRequired,
  sections: arrayOf(
    shape({
      id: string.isRequired,
      name: string.isRequired
    })
  ).isRequired,
  sectionSelectionChanged: func.isRequired,
  selectedSectionIds: arrayOf(string).isRequired
}
