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
import {arrayOf, bool, func, number, shape, string} from 'prop-types'

import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Badge} from '@instructure/ui-badge'
import {Spinner} from '@instructure/ui-spinner'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'

import {useScope as useI18nScope} from '@canvas/i18n'

import PostTypes from './PostTypes'
import SpecificSections from '@canvas/grading/react/SpecificSections'

const I18n = useI18nScope('post_assignment_grades_tray')

export default function FormContent({
  assignment: {anonymousGrading, gradesPublished},
  dismiss,
  onPostClick,
  postBySections,
  postBySectionsChanged,
  postType,
  postTypeChanged,
  postingGrades,
  sectionSelectionChanged,
  sections,
  selectedSectionIds,
  unpostedCount,
}) {
  if (postingGrades) {
    return (
      <View as="div" textAlign="center" padding="large">
        <Spinner renderTitle={I18n.t('Posting grades')} size="large" />
      </View>
    )
  }

  const hasSections = sections.length > 0

  return (
    <>
      {unpostedCount > 0 && (
        <div id="PostAssignmentGradesTray__Layout__UnpostedSummary">
          <AccessibleContent alt={I18n.t('%{count} hidden', {count: unpostedCount})}>
            <Badge
              count={unpostedCount}
              countUntil={99}
              margin="0 0 small large"
              placement="start center"
              type="count"
              variant="danger"
            >
              <View as="div" margin="0 0 0 small">
                <Text size="small">{I18n.t('Hidden')}</Text>
              </View>
            </Badge>
          </AccessibleContent>
        </div>
      )}

      <View as="div" margin="small 0" padding="0 medium">
        <PostTypes
          anonymousGrading={anonymousGrading}
          defaultValue={postType}
          disabled={!gradesPublished}
          postTypeChanged={postTypeChanged}
        />
      </View>

      <View as="div" margin="0 medium" className="hr" />

      {hasSections && (
        <SpecificSections
          checked={postBySections}
          disabled={!gradesPublished || anonymousGrading}
          onCheck={event => {
            postBySectionsChanged(event.target.checked)
          }}
          sections={sections}
          sectionSelectionChanged={sectionSelectionChanged}
          selectedSectionIds={selectedSectionIds}
        />
      )}

      <View as="div" margin="0 medium" className="hr" />

      <View as="div" margin="medium 0 0" padding="0 medium">
        <Flex justifyItems="end">
          <Flex.Item margin="0 small 0 0">
            <Button disabled={!gradesPublished} onClick={dismiss}>
              {I18n.t('Close')}
            </Button>
          </Flex.Item>

          <Flex.Item>
            <Button disabled={!gradesPublished} onClick={onPostClick} color="primary">
              {I18n.t('Post')}
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
  postBySections: bool.isRequired,
  postBySectionsChanged: func.isRequired,
  postingGrades: bool.isRequired,
  postType: string.isRequired,
  postTypeChanged: func.isRequired,
  onPostClick: func.isRequired,
  sections: arrayOf(
    shape({
      id: string.isRequired,
      name: string.isRequired,
    })
  ).isRequired,
  sectionSelectionChanged: func.isRequired,
  selectedSectionIds: arrayOf(string).isRequired,
  unpostedCount: number.isRequired,
}
