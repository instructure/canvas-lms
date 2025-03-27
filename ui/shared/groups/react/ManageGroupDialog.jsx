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
import {without} from 'lodash'
import React from 'react'
import createReactClass from 'create-react-class'
import BackboneState from './mixins/BackboneState'
import PaginatedUserCheckList from './PaginatedUserCheckList'
import InfiniteScroll from './mixins/InfiniteScroll'
import '@canvas/jquery/jquery.instructure_forms'
import {TextInput} from '@instructure/ui-text-input'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'

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
      this.setState({checkboxErrorMessage: [
        {type: 'newError', text: I18n.t('Too many members')},
      ]})
      $(this.userListRef).attr("tabindex",-1).focus()
      errors = true
    }
    if (this.state.name.trim().length === 0) {
      this.setState({errorMessages: [
        {type: 'newError', text: I18n.t('Group name is required')},
      ]})
      this.nameInputRef?.focus()
      errors = true
    }
    if (this.state.name.trim().length > 200) {
      this.setState({errorMessages: [
        {type: 'newError', text: I18n.t('Enter a shorter group name')},
      ]})
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
      <Flex id="manage_group_form" as="div" alignItems="center" justifyItems="start" gap="none" direction="row" width="100%">
        <form className="form-dialog" onSubmit={this.handleFormSubmit}>
          <div ref={c => (this.scrollElementRef = c)} className="form-dialog-content">
            <Flex.Item margin="xx-small">
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
            <Flex.Item
              margin="xx-small"
              tabindex="-1"
              elementRef={c => (this.userListRef = c)}
            >
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
          </div>
          <div className="form-controls">
            <Button
              data-testid="manage-group-modal-cancel-button"
              color="secondary"
              margin="xxx-small"
              onClick={this.props.closeDialog}
            >
              {I18n.t('Cancel')}
            </Button>
            <Button
              data-testid="manage-group-modal-submit-button"
              color="primary"
              margin="xxx-small"
              type="submit"
              formNoValidate
            >
              {I18n.t('Submit')}
            </Button>
          </div>
        </form>
      </Flex>
    )
  },
})

export default ManageGroupDialog
