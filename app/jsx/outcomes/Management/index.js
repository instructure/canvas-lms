/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import $ from 'jquery'
import 'compiled/jquery.rails_flash_notifications'
import {Billboard} from '@instructure/ui-billboard'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import SVGWrapper from '../../shared/SVGWrapper'
import {PresentationContent} from '@instructure/ui-a11y'
import I18n from 'i18n!OutcomeManagement'
import React from 'react'
import {GET_OUTCOME_GROUPS_QUERY} from './api'
import {useQuery} from 'react-apollo'
/* OutcomeGroupHeader for QA purposes
 * Remove component after integration
 * with outcome group display component
 */
import OutcomeGroupHeader from './OutcomeGroupHeader'

const OutcomeManagementPanel = ({contextType, contextId}) => {
  const isCourse = contextType === 'Course'
  const query = GET_OUTCOME_GROUPS_QUERY(contextType.toLowerCase())
  const {loading, error, data} = useQuery(query, {
    variables: {contextId}
  })

  if (loading) {
    return (
      <div style={{textAlign: 'center'}}>
        <Spinner renderTitle={I18n.t('Loading')} size="large" />
      </div>
    )
  }
  if (error) {
    isCourse
      ? $.flashError(I18n.t('An error occurred while loading course outcomes.'))
      : $.flashError(I18n.t('An error occurred while loading account outcomes.'))
    return (
      <div>
        <Text color="danger">
          {isCourse
            ? I18n.t('An error occurred while loading course outcomes: %{error}', {error})
            : I18n.t('An error occurred while loading account outcomes: %{error}', {error})}
        </Text>
      </div>
    )
  }
  const hasOutcomes = data.context.rootOutcomeGroup.childGroupsCount > 0

  return (
    <div className="management-panel" data-testid="outcomeManagementPanel">
      {!hasOutcomes ? (
        <Billboard
          size="large"
          headingLevel="h3"
          heading={
            isCourse
              ? I18n.t('Outcomes have not been added to this course yet.')
              : I18n.t('Outcomes have not been added to this account yet.')
          }
          message={
            isCourse
              ? I18n.t('Get started by finding, importing or creating your course outcomes.')
              : I18n.t('Get started by finding, importing or creating your account outcomes.')
          }
          hero={
            <PresentationContent>
              <SVGWrapper url="/images/magnifying_glass.svg" />
            </PresentationContent>
          }
        />
      ) : (
        <Flex>
          <Flex.Item width="33%" display="inline-block" position="relative" height="50vh" as="div">
            <View padding="small none none x-small">
              <Text size="large" weight="light" fontStyle="normal">
                {I18n.t('Outcome Groups')}
              </Text>
              <div>
                {/* Space for displaying root outcome group component associated with the course */}
              </div>
            </View>
          </Flex.Item>
          <Flex.Item
            width="1%"
            display="inline-block"
            position="relative"
            padding="small none large none"
            margin="small none none none"
            borderWidth="none small none none"
            height="50vh"
            as="div"
          />
          <Flex.Item width="66%" display="inline-block" position="relative" height="50vh" as="div">
            <View padding="small none none x-small">
              {/* space for outcome group display component */}
              {/* OutcomeGroupHeader for QA purposes
               * Remove component after integration
               * with outcome group display component
               */}
              <View as="div" padding="0 medium">
                <OutcomeGroupHeader
                  title="Grade.2.Math.3A.Elementary.5B.Calculus.1C"
                  description={'<p>This is a <strong><em>description</em></strong>. And because it’s so <strong>long</strong>, it will run out of space and hence be truncated. </p>'.repeat(
                    3
                  )}
                  onMenuHandler={() => {}}
                />
              </View>
            </View>
          </Flex.Item>
        </Flex>
      )}
    </div>
  )
}

export default OutcomeManagementPanel
