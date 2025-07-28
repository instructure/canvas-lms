/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import React from 'react'
import createReactClass from 'create-react-class'
import BackboneState from './mixins/BackboneState'
import PaginatedUserCheckList from './PaginatedUserCheckList'
import InfiniteScroll from './mixins/InfiniteScroll'
import '@canvas/jquery/jquery.instructure_forms'
import {TextInput} from '@instructure/ui-text-input'
import {Text} from '@instructure/ui-text'
import {Modal} from '@instructure/ui-modal'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'

const I18n = createI18nScope('student_groups')

const ManageGroupDialog = createReactClass({
  displayName: 'ManageGroupDialog',
  mixins: [BackboneState, InfiniteScroll],

  loadMore() {
    this.props.loadMore()
  },

  getInitialState() {
    return {
      userCollection: this.props.userCollection,
      checked: this.props.checked,
      name: this.props.name,
      errorMessages: [],
      checkboxErrorMessage: [],
    }
  },

  handleFormSubmit(e) {
    e.preventDefault()
    let errors = false
    if (this.props.maxMembership && this.state.checked.length > this.props.maxMembership) {
      this.setState({checkboxErrorMessage: [{type: 'newError', text: I18n.t('Too many members')}]})
      $(this.userListRef).attr('tabindex', -1).focus()
      errors = true
    }
    if (this.state.name.trim().length === 0) {
      this.setState({errorMessages: [{type: 'newError', text: I18n.t('Group name is required')}]})
      this.nameInputRef?.focus()
      errors = true
    }
    if (this.state.name.trim().length > 200) {
      this.setState({
        errorMessages: [{type: 'newError', text: I18n.t('Enter a shorter group name')}],
      })
      this.nameInputRef?.focus()
      errors = true
    }
    if (!errors) {
      this.props.updateGroup(this.props.groupId, this.state.name, this.state.checked)
      this.props.closeDialog(e)
    }
  },

  _onUserCheck(checkedUsers) {
    this.setState({
      checked: checkedUsers,
      checkboxErrorMessage: [],
    })
  },

  render() {
    const users = this.state.userCollection.toJSON().filter(u => u.id !== ENV.current_user_id)
    let inviteLimit = null
    if (this.props.maxMembership) {
      const className = this.state.checked.length > this.props.maxMembership ? 'text-error' : null
      inviteLimit = (
        <span>
          <span className="screenreader-only" aria-live="polite" aria-atomic="true">
            {I18n.t('%{member_count} members out of maximum of %{max_membership}', {
              member_count: this.state.checked.length,
              max_membership: this.props.maxMembership,
            })}
          </span>
          <span className={className} aria-hidden="true">
            ({this.state.checked.length}/{this.props.maxMembership})
          </span>
        </span>
      )
    }

    return (
      <Modal
        as="form"
        onSubmit={e => this.handleFormSubmit(e)}
        open={true}
        size="small"
        label={I18n.t('Manage student ${group_name}', {group_name: this.props.name})}
      >
        <Modal.Header>
          <Heading data-testid="dialog-heading">{I18n.t('Manage Student Group')}</Heading>
        </Modal.Header>
        <Modal.Body elementRef={c => (this.scrollElementRef = c)} className="form-dialog-content">
          <Flex direction="column" margin="xx-small" height="400px">
            <Flex.Item padding="xx-small">
              <TextInput
                inputRef={c => (this.nameInputRef = c)}
                id="group_name"
                type="text"
                name="name"
                width="50%"
                isRequired={true}
                renderLabel={<Text>{I18n.t('Group Name')}</Text>}
                value={this.state.name}
                messages={this.state.errorMessages}
                onChange={event => this.setState({name: event.target.value, errorMessages: []})}
              />
            </Flex.Item>
            <Flex.Item padding="xx-small" tabindex="-1" elementRef={c => (this.userListRef = c)}>
              <PaginatedUserCheckList
                checked={this.state.checked}
                permanentUsers={[ENV.current_user]}
                users={users}
                onUserCheck={this._onUserCheck}
                messages={this.state.checkboxErrorMessage}
                label={
                  <Text aria-live="polite" aria-atomic="true" weight="bold">
                    {I18n.t('Members')} {inviteLimit}
                  </Text>
                }
              />
            </Flex.Item>
          </Flex>
        </Modal.Body>
        <Modal.Footer>
          <Flex className="form-controls" gap="x-small">
            <Button
              data-testid="manage-group-modal-cancel-button"
              color="secondary"
              onClick={this.props.closeDialog}
            >
              {I18n.t('Cancel')}
            </Button>
            <Button
              data-testid="manage-group-modal-submit-button"
              color="primary"
              type="submit"
              formNoValidate
            >
              {I18n.t('Submit')}
            </Button>
          </Flex>
        </Modal.Footer>
      </Modal>
    )
  },
})

export default ManageGroupDialog
