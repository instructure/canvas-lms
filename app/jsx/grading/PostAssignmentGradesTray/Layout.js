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
import Heading from '@instructure/ui-elements/lib/components/Heading'
import Text from '@instructure/ui-elements/lib/components/Text'
import View from '@instructure/ui-layout/lib/components/View'
import I18n from 'i18n!post_assignment_grades_tray'

import PostTypes from './PostTypes'
import SpecificSections from '../SpecificSections'

export default function Layout(props) {
  const {
    assignment,
    dismiss,
    postBySections,
    postBySectionsChanged,
    postType,
    postTypeChanged,
    postingGrades,
    onPostClick,
    sections,
    sectionSelectionChanged,
    selectedSectionIds
  } = props
  const {anonymizeStudents, gradesPublished} = assignment
  const hasSections = sections.length > 0

  return (
    <Fragment>
      <View as="div" margin="0 0 small" padding="0 medium">
        <Heading as="h3" level="h4">
          {I18n.t('Post Grades')}
        </Heading>
      </View>

      <View as="div" margin="small 0" padding="0 medium">
        <PostTypes defaultValue={postType} postTypeChanged={postTypeChanged} />
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
          disabled={assignment.anonymizeStudents}
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
            <Button onClick={dismiss}>{I18n.t('Close')}</Button>
          </FlexItem>

          <FlexItem>
            <Button
              disabled={postingGrades || !gradesPublished}
              onClick={onPostClick}
              variant="primary"
            >
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
  postTypeChanged: func.isRequired,
  onPostClick: func.isRequired,
  sections: arrayOf(
    shape({
      id: string.isRequired,
      name: string.isRequired
    })
  ).isRequired,
  sectionSelectionChanged: func.isRequired,
  selectedSectionIds: arrayOf(string).isRequired
}
