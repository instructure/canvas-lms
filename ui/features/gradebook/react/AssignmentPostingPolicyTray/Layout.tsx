// @ts-nocheck
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
import {bool, func} from 'prop-types'
import {Button, ButtonProps} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {List} from '@instructure/ui-list'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('assignment_posting_policy_tray')

const MANUAL_POST = 'manual'
const AUTOMATIC_POST = 'auto'

export interface LayoutProps {
  allowAutomaticPosting: boolean
  allowCanceling: boolean
  allowSaving: boolean
  onDismiss: ButtonProps['onClick']
  onPostPolicyChanged: ({postManually}: {postManually: boolean}) => void
  onSave: ButtonProps['onClick']
  selectedPostManually: boolean
}

export default function Layout(props: LayoutProps) {
  const automaticallyPostLabel = (
    <View as="div">
      <Text as="div">{I18n.t('Automatically')}</Text>

      <Text size="small">
        {I18n.t(`
          Assignment grades will be visible to students as soon as they are entered.
          Grades that have already been hidden will remain hidden.
        `)}
      </Text>
    </View>
  )

  const manuallyPostLabel = (
    <View as="div">
      <Text as="div">{I18n.t('Manually')}</Text>

      <Text size="small">
        {I18n.t(`
          Grades will be hidden by default. Any grades that have already posted will remain visible.
          Choose when to post grades for this assignment in the gradebook.
        `)}
      </Text>

      {props.selectedPostManually && (
        <View as="div">
          <Text size="small" as="p">
            {I18n.t(
              'While the grades for this assignment are set to manual, students will not receive new notifications about or be able to see:'
            )}
          </Text>

          <List margin="0 0 0 small" size="small" itemSpacing="small">
            <List.Item>{I18n.t('Their grade for the assignment')}</List.Item>
            <List.Item>{I18n.t('Grade change notifications')}</List.Item>
            <List.Item>{I18n.t('Submission comments')}</List.Item>
            <List.Item>{I18n.t('Curving assignments')}</List.Item>
            <List.Item>{I18n.t('Score change notifications')}</List.Item>
          </List>

          <Text size="small" as="p">
            {I18n.t(`
              Once a grade is posted manually, it will automatically send new notifications and be visible to students.
              Future grade changes for posted grades will not need to be manually posted.
            `)}
          </Text>
        </View>
      )}
    </View>
  )

  const handlePostPolicyChanged = event => {
    props.onPostPolicyChanged({postManually: event.target.value === MANUAL_POST})
  }

  return (
    <>
      <View
        as="div"
        margin="small 0"
        padding="0 medium"
        id="AssignmentPostingPolicyTray__RadioInputGroup"
      >
        <RadioInputGroup
          description={I18n.t('Post Grades')}
          name="postPolicy"
          onChange={handlePostPolicyChanged}
          value={props.selectedPostManually ? MANUAL_POST : AUTOMATIC_POST}
        >
          <RadioInput
            className="AssignmentPostingPolicyTray__RadioInput"
            disabled={!props.allowAutomaticPosting}
            name="postPolicy"
            label={automaticallyPostLabel}
            value={AUTOMATIC_POST}
          />

          <RadioInput
            className="AssignmentPostingPolicyTray__RadioInput"
            name="postPolicy"
            label={manuallyPostLabel}
            value={MANUAL_POST}
          />
        </RadioInputGroup>
      </View>

      <View as="div" margin="0 medium" className="hr" />

      <View
        as="div"
        margin="medium 0 0"
        padding="0 medium"
        id="AssignmentPostingPolicyTray__Buttons"
      >
        <Flex justifyItems="end">
          <Flex.Item margin="0 small 0 0">
            <Button onClick={props.onDismiss} disabled={!props.allowCanceling}>
              {I18n.t('Cancel')}
            </Button>
          </Flex.Item>

          <Flex.Item>
            <Button onClick={props.onSave} disabled={!props.allowSaving} color="primary">
              {I18n.t('Save')}
            </Button>
          </Flex.Item>
        </Flex>
      </View>
    </>
  )
}

Layout.propTypes = {
  allowAutomaticPosting: bool.isRequired,
  allowCanceling: bool.isRequired,
  allowSaving: bool.isRequired,
  onDismiss: func.isRequired,
  onPostPolicyChanged: func.isRequired,
  onSave: func.isRequired,
  selectedPostManually: bool.isRequired,
}
