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
import {any, arrayOf, bool, shape} from 'prop-types'

import Alert from '@instructure/ui-alerts/lib/components/Alert'
import FormFieldGroup from '@instructure/ui-form-field/lib/components/FormFieldGroup'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import View from '@instructure/ui-layout/lib/components/View'

import I18n from 'i18n!hide_assignment_grades_tray'

import FormContent from './FormContent'

export default function Layout({
  assignment: {anonymousGrading, gradesPublished},
  dismiss,
  hideBySections,
  hideBySectionsChanged,
  hidingGrades,
  onHideClick,
  sections,
  sectionSelectionChanged,
  selectedSectionIds
}) {
  const hasSections = sections.length > 0

  return (
    <Fragment>
      {!gradesPublished && (
        <Alert margin="x-small" variant="warning">
          {I18n.t(
            'Hiding grades is not allowed because grades have not been released for this assignment.'
          )}
        </Alert>
      )}

      {gradesPublished && hasSections && anonymousGrading && (
        <Alert margin="x-small" variant="info">
          {I18n.t('You can only hide grades for everyone when the assignment is anonymous.')}
        </Alert>
      )}

      <FormFieldGroup
        description={
          <View as="div" margin="0 0 small" padding="0 medium">
            <Heading as="h3" level="h4">
              {I18n.t('Hide Grades')}
            </Heading>
          </View>
        }
        label={I18n.t('Hide Grades')}
        disabled={!gradesPublished}
      >
        <FormContent
          assignment={{anonymousGrading, gradesPublished}}
          dismiss={dismiss}
          onHideClick={onHideClick}
          hideBySections={hideBySections}
          hideBySectionsChanged={hideBySectionsChanged}
          hidingGrades={hidingGrades}
          sectionSelectionChanged={sectionSelectionChanged}
          sections={sections}
          selectedSectionIds={selectedSectionIds}
        />
      </FormFieldGroup>
    </Fragment>
  )
}

Layout.propTypes = {
  assignment: shape({
    anonymousGrading: bool.isRequired,
    gradesPublished: bool.isRequired
  }).isRequired,
  sections: arrayOf(any).isRequired,
  ...FormContent.propTypes
}
