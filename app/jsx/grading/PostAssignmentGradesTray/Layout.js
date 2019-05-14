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
import Heading from '@instructure/ui-elements/lib/components/Heading'
import Text from '@instructure/ui-elements/lib/components/Text'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import View from '@instructure/ui-layout/lib/components/View'

import I18n from 'i18n!post_assignment_grades_tray'

import PostTypes from './PostTypes'
import SpecificSections from '../SpecificSections'

export default function Layout({
  assignment: {anonymizeStudents, gradesPublished},
  dismiss,
  postBySections,
  postBySectionsChanged,
  postType,
  postTypeChanged,
  postingGrades,
  onPostClick,
  sections,
  sectionSelectionChanged,
  selectedSectionIds,
  unpostedCount
}) {
  const hasSections = sections.length > 0
  const heading = (
    <View as="div" margin="0 0 small" padding="0 medium">
      <Heading as="h3" level="h4">
        {I18n.t('Post Grades')}
      </Heading>
    </View>
  )

  if (postingGrades) {
    return (
      <Fragment>
        {heading}

        <View as="div" textAlign="center" padding="large">
          <Spinner title={I18n.t('Posting grades')} size="large" />
        </View>
      </Fragment>
    )
  }

  return (
    <Fragment>
      {heading}

      {unpostedCount > 0 && (
        <div id="PostAssignmentGradesTray__Layout__UnpostedSummary">
          <Badge
            count={unpostedCount}
            countUntil={99}
            margin="0 0 medium large"
            placement="start center"
            type="count"
            variant="danger"
          >
            <View as="div" margin="0 0 0 small">
              <Text margin="0 0 0 small">{I18n.t('Hidden')}</Text>
            </View>
          </Badge>
        </div>
      )}

      <View as="div" margin="small 0" padding="0 medium">
        <PostTypes
          disabled={!gradesPublished}
          defaultValue={postType}
          postTypeChanged={postTypeChanged}
        />
      </View>

      <View as="div" margin="0 medium" className="hr" />

      {hasSections && anonymizeStudents && (
        <View as="p" margin="small 0 small" padding="0 medium">
          <Text>{I18n.t('Anonymous assignments cannot be posted by section.')}</Text>
        </View>
      )}

      {hasSections && (
        <SpecificSections
          checked={postBySections}
          disabled={!gradesPublished || anonymizeStudents}
          onCheck={event => {
            postBySectionsChanged(event.target.checked)
          }}
          sections={sections}
          sectionSelectionChanged={sectionSelectionChanged}
          selectedSectionIds={selectedSectionIds}
        />
      )}

      <View as="div" margin="0 medium" className="hr" />

      {!gradesPublished && (
        <View as="p" margin="small 0 small" padding="0 medium">
          <Text>
            {I18n.t(
              'Posting grades is not allowed because grades have not been released for this assignment.'
            )}
          </Text>
        </View>
      )}

      <View as="div" margin="medium 0 0" padding="0 medium">
        <Flex justifyItems="end">
          <FlexItem margin="0 small 0 0">
            <Button disabled={!gradesPublished} onClick={dismiss}>
              {I18n.t('Close')}
            </Button>
          </FlexItem>

          <FlexItem>
            <Button onClick={onPostClick} disabled={!gradesPublished} variant="primary">
              {I18n.t('Post')}
            </Button>
          </FlexItem>
        </Flex>
      </View>
    </Fragment>
  )
}

Layout.propTypes = {
  assignment: shape({
    anonymizeStudents: bool.isRequired,
    gradesPublished: bool.isRequired
  }).isRequired,
  dismiss: func.isRequired,
  postBySections: bool.isRequired,
  postBySectionsChanged: func.isRequired,
  postingGrades: bool.isRequired,
  postType: string.isRequired,
  postTypeChanged: PostTypes.propTypes.postTypeChanged,
  onPostClick: func.isRequired,
  sections: arrayOf(
    shape({
      id: string.isRequired,
      name: string.isRequired
    })
  ).isRequired,
  sectionSelectionChanged: SpecificSections.propTypes.sectionSelectionChanged,
  selectedSectionIds: SpecificSections.propTypes.selectedSectionIds,
  unpostedCount: number.isRequired
}
