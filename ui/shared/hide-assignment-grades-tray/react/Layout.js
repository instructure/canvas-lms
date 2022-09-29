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
import {any, arrayOf, bool, shape, string} from 'prop-types'

import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Badge} from '@instructure/ui-badge'
import {Alert} from '@instructure/ui-alerts'
import {FormFieldGroup} from '@instructure/ui-form-field'

import {View} from '@instructure/ui-view'

import {useScope as useI18nScope} from '@canvas/i18n'

import FormContent from './FormContent'

const I18n = useI18nScope('hide_assignment_grades_tray')

export default function Layout({
  assignment: {anonymousGrading, gradesPublished},
  containerName,
  dismiss,
  hideBySections,
  hideBySectionsChanged,
  hidingGrades,
  onHideClick,
  sections,
  sectionSelectionChanged,
  selectedSectionIds,
  unhiddenCount,
}) {
  const hasSections = sections.length > 0

  return (
    <>
      {!gradesPublished && (
        <Alert margin="x-small" variant="warning">
          {I18n.t(
            'Hiding grades is not allowed because grades have not been released for this assignment.'
          )}
        </Alert>
      )}

      {gradesPublished && anonymousGrading && containerName === 'SPEED_GRADER' && (
        <Alert margin="x-small" variant="warning">
          {I18n.t('Hiding grades will refresh your browser. This may take a moment.')}
        </Alert>
      )}

      {gradesPublished && hasSections && anonymousGrading && (
        <Alert margin="x-small" variant="info">
          {I18n.t(
            'When hiding grades for anonymous assignments, grades will be hidden for everyone in the course. Anonymity will be re-applied.'
          )}
        </Alert>
      )}

      <FormFieldGroup
        description={
          <View as="div" margin="0 0 small" padding="0 medium">
            <Heading as="h3" level="h4">
              {I18n.t('Hide Grades')}
            </Heading>
            <div id="PostAssignmentGradesTray__Layout__UnpostedSummary">
              <AccessibleContent alt={I18n.t('%{count} posted', {count: unhiddenCount})}>
                <Badge
                  count={unhiddenCount}
                  countUntil={99}
                  margin="small"
                  placement="start center"
                  type="count"
                  variant="danger"
                >
                  <View as="div" margin="0 0 0 small">
                    <Text size="small">{I18n.t('Posted')}</Text>
                  </View>
                </Badge>
              </AccessibleContent>
            </div>
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
    </>
  )
}

Layout.propTypes = {
  assignment: shape({
    anonymousGrading: bool.isRequired,
    gradesPublished: bool.isRequired,
  }).isRequired,
  containerName: string,
  sections: arrayOf(any).isRequired,
  ...FormContent.propTypes,
}
