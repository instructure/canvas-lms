/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import I18n from 'i18n!PeopleSearch'
import React from 'react'
import {Text} from '@instructure/ui-text'
import {Checkbox} from '@instructure/ui-checkbox'
import {TextArea} from '@instructure/ui-text-area'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import CanvasSelect from '@canvas/instui-bindings/react/Select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconUserSolid} from '@instructure/ui-icons'
import {courseParamsShape, inputParamsShape} from './shapes'
import {parseNameList, findEmailInEntry, emailValidator} from '../helpers'

class PeopleSearch extends React.Component {
  static propTypes = {...inputParamsShape, ...courseParamsShape}

  static defaultProps = {
    searchType: 'cc_path',
    nameList: ''
  }

  constructor(props) {
    super(props)

    this.namelistta = null
  }

  shouldComponentUpdate(nextProps /* nextState */) {
    return (
      nextProps.searchType !== this.props.searchType ||
      nextProps.nameList !== this.props.nameList ||
      nextProps.role !== this.props.role ||
      nextProps.section !== this.props.section ||
      nextProps.limitPrivilege !== this.props.limitPrivilege
    )
  }

  // event handlers ------------------------------------
  // inst-ui form elements are currently inconsistent in what args they send
  // to their onChange handler. Some send the event, others just the new value.
  // When they all send the event, we can coallesce these onChange handlers
  // into one and use the name attribute to set the proper state
  onChangeSearchType = newValue => {
    this.props.onChange({searchType: newValue})
  }

  onChangeNameList = event => {
    this.props.onChange({nameList: event.target.value})
  }

  onChangeSection = (event, optionValue) => {
    this.props.onChange({section: optionValue})
  }

  onChangeRole = (event, optionValue) => {
    this.props.onChange({role: optionValue})
  }

  onChangePrivilege = event => {
    this.props.onChange({limitPrivilege: event.target.checked})
  }

  // validate the user's input of names in the textbox
  // @returns: a message for <TextArea> or null
  getHint() {
    let message = ' ' // that's a copy/pasted en-space to trick TextArea into
    // reserving space for the message so the UI doesn't jump
    if (this.props.nameList.length > 0 && this.props.searchType === 'cc_path') {
      // search by email
      const users = parseNameList(this.props.nameList)
      const badEmail = users.find(u => {
        const email = findEmailInEntry(u)
        return !emailValidator.test(email)
      })
      if (badEmail) {
        message = I18n.t('It looks like you have an invalid email address: "%{addr}"', {
          addr: badEmail
        })
      }
    }
    return [{text: message, type: 'hint'}]
  }

  // rendering ------------------------------------
  render() {
    let exampleText = ''
    let description = ''
    let inputLabel = ''
    const message = this.getHint()

    switch (this.props.searchType) {
      case 'sis_user_id':
        exampleText = 'student_2708, student_3693'
        description = I18n.t(
          'Enter the SIS IDs of the users you would like to add, separated by commas or line breaks'
        )
        inputLabel = I18n.t('SIS IDs (required)')
        break
      case 'unique_id':
        exampleText = 'lsmith, mfoster'
        description = I18n.t(
          'Enter the login IDs of the users you would like to add, separated by commas or line breaks'
        )
        inputLabel = I18n.t('Login IDs (required)')
        break
      case 'cc_path':
      default:
        exampleText = 'lsmith@myschool.edu, mfoster@myschool.edu'
        description = I18n.t(
          'Enter the email addresses of the users you would like to add, separated by commas or line breaks'
        )
        inputLabel = I18n.t('Email Addresses (required)')
    }

    return (
      <div className="addpeople__peoplesearch">
        <RadioInputGroup
          name="search_type"
          defaultValue={this.props.searchType}
          description={I18n.t('Add user(s) by')}
          onChange={(e, val) => this.onChangeSearchType(val)}
          layout="columns"
        >
          <RadioInput
            id="peoplesearch_radio_cc_path"
            key="cc_path"
            value="cc_path"
            label={I18n.t('Email Address')}
          />
          <RadioInput
            id="peoplesearch_radio_unique_id"
            key="unique_id"
            value="unique_id"
            label={I18n.t('Login ID')}
          />
          {this.props.canReadSIS ? (
            <RadioInput
              id="peoplesearch_radio_sis_user_id"
              key="sis_user_id"
              value="sis_user_id"
              label={I18n.t('SIS ID')}
            />
          ) : null}
        </RadioInputGroup>
        <fieldset>
          <TextArea
            label={
              <>
                {inputLabel}
                <ScreenReaderContent>{description}</ScreenReaderContent>
              </>
            }
            autoGrow={false}
            resize="vertical"
            height="9em"
            value={this.props.nameList}
            placeholder={exampleText}
            textareaRef={ta => {
              this.namelistta = ta
            }}
            messages={message}
            onChange={this.onChangeNameList}
          />
        </fieldset>
        <fieldset className="peoplesearch__selections">
          <div>
            <div className="peoplesearch__selection">
              <CanvasSelect
                label={I18n.t('Role')}
                id="peoplesearch_select_role"
                value={this.props.role || (this.props.roles.length ? this.props.roles[0].id : null)}
                onChange={this.onChangeRole}
              >
                {this.props.roles.map(r => (
                  <CanvasSelect.Option key={r.id} id={r.id} value={r.id}>
                    {r.label}
                  </CanvasSelect.Option>
                ))}
              </CanvasSelect>
            </div>
            <div className="peoplesearch__selection">
              <CanvasSelect
                label={I18n.t('Section')}
                id="peoplesearch_select_section"
                value={
                  this.props.section ||
                  (this.props.sections.length ? this.props.sections[0].id : null)
                }
                onChange={this.onChangeSection}
              >
                {this.props.sections.map(s => (
                  <CanvasSelect.Option key={s.id} id={s.id} value={s.id}>
                    {s.name}
                  </CanvasSelect.Option>
                ))}
              </CanvasSelect>
            </div>
          </div>
          <div style={{marginTop: '1em'}}>
            <Checkbox
              key="limit_privileges_to_course_section"
              id="limit_privileges_to_course_section"
              label={I18n.t('Can interact with users in their section only')}
              value={0}
              checked={this.props.limitPrivilege}
              onChange={this.onChangePrivilege}
            />
          </div>
        </fieldset>
        <div className="peoplesearch__instructions">
          <div className="usericon" aria-hidden>
            <IconUserSolid />
          </div>
          <Text size="medium">
            {I18n.t('When adding multiple users, use a comma or line break to separate users.')}
          </Text>
        </div>
      </div>
    )
  }
}

export default PeopleSearch
