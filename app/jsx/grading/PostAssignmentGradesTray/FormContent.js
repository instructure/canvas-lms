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
import {arrayOf, bool, func, number, shape, string} from 'prop-types'

import Badge from '@instructure/ui-elements/lib/components/Badge'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import Text from '@instructure/ui-elements/lib/components/Text'
import View from '@instructure/ui-layout/lib/components/View'

import I18n from 'i18n!post_assignment_grades_tray'

import PostTypes from './PostTypes'
import SpecificSections from '../SpecificSections'

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
  unpostedCount
}) {
  if (postingGrades) {
    return (
      <View as="div" textAlign="center" padding="large">
        <Spinner title={I18n.t('Posting grades')} size="large" />
      </View>
    )
  }

  const hasSections = sections.length > 0

  return (
    <Fragment>
      {unpostedCount > 0 && (
        <div id="PostAssignmentGradesTray__Layout__UnpostedSummary">
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
          <FlexItem margin="0 small 0 0">
            <Button disabled={!gradesPublished} onClick={dismiss}>
              {I18n.t('Close')}
            </Button>
          </FlexItem>

          <FlexItem>
            <Button disabled={!gradesPublished} onClick={onPostClick} variant="primary">
              {I18n.t('Post')}
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
  postBySections: bool.isRequired,
  postBySectionsChanged: func.isRequired,
  postingGrades: bool.isRequired,
  postType: string.isRequired,
  postTypeChanged: func.isRequired,
  onPostClick: func.isRequired,
  sections: arrayOf(
    shape({
      id: string.isRequired,
      name: string.isRequired
    })
  ).isRequired,
  sectionSelectionChanged: func.isRequired,
  selectedSectionIds: arrayOf(string).isRequired,
  unpostedCount: number.isRequired
}
