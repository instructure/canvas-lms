/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {bool, func, oneOf, string} from 'prop-types'
import I18n from 'i18n!assignments_2'

import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Text from '@instructure/ui-elements/lib/components/Text'

import IconAssignment from '@instructure/ui-icons/lib/Line/IconAssignment'
import IconGroup from '@instructure/ui-icons/lib/Line/IconGroup'
import IconQuiz from '@instructure/ui-icons/lib/Line/IconQuiz'
import IconPeerReview from '@instructure/ui-icons/lib/Line/IconPeerReview'

import SelectableText from './SelectableText'

const assignment_type = {value: 'assignment', label: I18n.t('Assignment'), icon: IconAssignment}
const peer_review_type = {
  value: 'peer-review',
  label: I18n.t('Peer Review Assignment'),
  icon: IconPeerReview
}
const group_type = {value: 'group', label: I18n.t('Group Assignment'), icon: IconGroup}
const quiz_type = {value: 'quiz', label: I18n.t('Quiz'), icon: IconQuiz}

const assignmentTypePlaceholder = I18n.t('Assignment Type')

export default class AssignmentType extends React.Component {
  static propTypes = {
    mode: oneOf(['edit', 'view']).isRequired,
    onChange: func.isRequired,
    onChangeMode: func.isRequired,
    selectedAssignmentType: string,
    readOnly: bool
  }

  static defaultProps = {
    readOnly: false
  }

  constructor(props) {
    super(props)

    this.assignmentTypes = [assignment_type, peer_review_type, group_type]
    if (window.ENV && window.ENV.QUIZ_LTI_ENABLED) {
      this.assignmentTypes.splice(2, 0, quiz_type)
    }
  }

  handleChange = selection => {
    this.props.onChange(selection && selection.value)
  }

  renderTypeView = typeOption => {
    const selectedType = typeOption && this.assignmentTypes.find(t => t.value === typeOption.value)
    if (!selectedType) {
      return <Text weight="light">{assignmentTypePlaceholder}</Text>
    }

    return (
      <Flex>
        <FlexItem>
          <selectedType.icon />
        </FlexItem>
        <FlexItem margin="0 0 0 small">
          <Text>{selectedType.label}</Text>
        </FlexItem>
      </Flex>
    )
  }

  render() {
    const type = this.assignmentTypes.find(t => t.value === this.props.selectedAssignmentType)
    return (
      <div data-testid="AssignmentType">
        <SelectableText
          mode={this.props.mode}
          label={I18n.t('Assignment Type')}
          value={type}
          onChange={this.handleChange}
          onChangeMode={this.props.onChangeMode}
          renderView={this.renderTypeView}
          size="medium"
          readOnly={this.props.readOnly}
          options={this.assignmentTypes}
        />
      </div>
    )
  }
}
