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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {MutableRefObject} from 'react'
import {Text} from '@instructure/ui-text'
import {Checkbox} from '@instructure/ui-checkbox'
import {TextArea} from '@instructure/ui-text-area'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import CanvasSelect from '@canvas/instui-bindings/react/Select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconUserSolid} from '@instructure/ui-icons'
import {courseParamsShape, inputParamsShape} from './shapes'
import {Flex} from '@instructure/ui-flex'
import {FormMessage} from '@instructure/ui-form-field'

const I18n = createI18nScope('PeopleSearch')

type SearchType = 'sis_user_id' | 'unique_id' | 'cc_path'

type Role = {id: string; label: string}

type Section = {id: string; name: string}

interface PeopleSearchProps {
  searchType: SearchType
  nameList: string
  role?: Role['id']
  section?: string
  limitPrivilege?: boolean
  roles: Array<Role>
  sections: Array<Section>
  canReadSIS?: boolean
  textareaRef?: MutableRefObject<HTMLTextAreaElement | null>
  searchInputError?: FormMessage | null
  onChange?: (
    params: Partial<
      Pick<
        PeopleSearchProps,
        'searchType' | 'canReadSIS' | 'limitPrivilege' | 'nameList' | 'role'
      > & {section: Section['id']}
    >,
  ) => void
}

class PeopleSearch extends React.Component<PeopleSearchProps> {
  static propTypes = {...inputParamsShape, ...courseParamsShape}

  static defaultProps: PeopleSearchProps = {
    searchType: 'cc_path',
    nameList: '',
    roles: [],
    sections: [],
  }

  shouldComponentUpdate(nextProps: PeopleSearchProps) {
    return (
      nextProps.searchType !== this.props.searchType ||
      nextProps.nameList !== this.props.nameList ||
      nextProps.role !== this.props.role ||
      nextProps.section !== this.props.section ||
      nextProps.limitPrivilege !== this.props.limitPrivilege ||
      nextProps.searchInputError !== this.props.searchInputError
    )
  }

  onChangeSearchType = (newValue: string) => {
    this.props.onChange?.({searchType: newValue as SearchType})
  }

  onChangeNameList = (event: React.ChangeEvent<HTMLTextAreaElement>) => {
    this.props.onChange?.({nameList: event.target.value})
  }

  onChangeSection = (_event: React.ChangeEvent<HTMLSelectElement>, optionValue: string) => {
    this.props.onChange?.({section: optionValue})
  }

  onChangeRole = (_event: React.ChangeEvent<HTMLSelectElement>, optionValue: string) => {
    this.props.onChange?.({role: optionValue})
  }

  onChangePrivilege = (event: React.ChangeEvent<HTMLInputElement>) => {
    this.props.onChange?.({limitPrivilege: event.target.checked})
  }

  render() {
    let exampleText = ''
    let description = ''
    let inputLabel = ''

    switch (this.props.searchType) {
      case 'sis_user_id':
        exampleText = 'student_2708, student_3693'
        description = I18n.t(
          'Enter the SIS IDs of the users you would like to add, separated by commas or line breaks',
        )
        inputLabel = I18n.t('SIS IDs')
        break
      case 'unique_id':
        exampleText = 'lsmith, mfoster'
        description = I18n.t(
          'Enter the login IDs of the users you would like to add, separated by commas or line breaks',
        )
        inputLabel = I18n.t('Login IDs')
        break
      case 'cc_path':
      default:
        exampleText = 'lsmith@myschool.edu, mfoster@myschool.edu'
        description = I18n.t(
          'Enter the email addresses of the users you would like to add, separated by commas or line breaks',
        )
        inputLabel = I18n.t('Email Addresses')
    }

    return (
      <div className="addpeople__peoplesearch">
        <RadioInputGroup
          name="search_type"
          defaultValue={this.props.searchType}
          description={I18n.t('Add user(s) by')}
          onChange={(_event, value) => this.onChangeSearchType(value)}
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
        <div className="peoplesearch_container">
          <TextArea
            label={
              <>
                {inputLabel}
                <ScreenReaderContent>{description}</ScreenReaderContent>
              </>
            }
            required
            autoGrow={false}
            resize="vertical"
            height="9em"
            value={this.props.nameList}
            placeholder={exampleText}
            textareaRef={textarea => {
              if (!this.props.textareaRef) {
                return
              }
              this.props.textareaRef.current = textarea
            }}
            messages={this.props.searchInputError ? [this.props.searchInputError] : undefined}
            onChange={this.onChangeNameList}
          />
        </div>
        <div className="peoplesearch_container">
          <Flex
            wrap="wrap"
            gap="large"
            justifyItems="center"
            data-testid="people-search-role-section-container"
            className="peoplesearch__role-section-container"
          >
            <Flex.Item>
              <CanvasSelect
                label={I18n.t('Role')}
                id="peoplesearch_select_role"
                value={this.props.role || (this.props.roles.length ? this.props.roles[0].id : '')}
                onChange={this.onChangeRole}
              >
                {this.props.roles.map(r => (
                  <CanvasSelect.Option key={r.id} id={r.id} value={r.id}>
                    {r.label}
                  </CanvasSelect.Option>
                ))}
              </CanvasSelect>
            </Flex.Item>
            <Flex.Item>
              <CanvasSelect
                label={I18n.t('Section')}
                id="peoplesearch_select_section"
                value={
                  this.props.section ||
                  (this.props.sections.length ? this.props.sections[0].id : '')
                }
                onChange={this.onChangeSection}
              >
                {this.props.sections.map(s => (
                  <CanvasSelect.Option key={s.id} id={s.id} value={s.id}>
                    {s.name}
                  </CanvasSelect.Option>
                ))}
              </CanvasSelect>
            </Flex.Item>
          </Flex>
        </div>
        <div className="peoplesearch_container">
          <Checkbox
            key="limit_privileges_to_course_section"
            id="limit_privileges_to_course_section"
            label={I18n.t('Can interact with users in their section only')}
            value={0}
            checked={this.props.limitPrivilege}
            onChange={this.onChangePrivilege}
          />
        </div>
        <div className="peoplesearch__instructions">
          <div className="usericon" aria-hidden={true}>
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
