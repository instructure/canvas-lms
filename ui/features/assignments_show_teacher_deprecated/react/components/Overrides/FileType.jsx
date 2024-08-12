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
import {arrayOf, bool, string, element, func} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button} from '@instructure/ui-buttons'
import {IconTrashLine} from '@instructure/ui-icons'
import {Select} from '@instructure/ui-select'
import SubmitOptionShape from './SubmitOptionShape'

const I18n = useI18nScope('assignments_2')

/*
 *  CAUTION: The InstUI Select component is greatly changed in v7.
 *  Updating the import to the new ui-select location is almost certainly
 *  going to break the functionality of the component. Any failing tests
 *  will just be skipped, and the component can be fixed later when work
 *  resumes on A2.
 */

export default class FileType extends React.Component {
  static propTypes = {
    readOnly: bool,
    icon: element.isRequired,
    name: string.isRequired,
    value: string.isRequired,
    options: arrayOf(SubmitOptionShape).isRequired,
    onDelete: func,
    initialSelection: arrayOf(string),
  }

  static defaultProps = {
    readOnly: false,
  }

  constructor(props) {
    super(props)

    this.state = {
      selectedOptions: this.props.initialSelection,
    }
  }

  onDelete = () => {
    this.props.onDelete(this.props.value)
  }

  handleInputChange = (e, options) => {
    this.setState(state => {
      let newSelected
      const optionValues = options.map(opt => opt.value)
      const fromAll = state.selectedOptions.includes('all')
      const toAll = optionValues.includes('all') || options.length === 0
      if (fromAll) {
        newSelected = optionValues.filter(opt => opt !== 'all')
      } else if (toAll) {
        newSelected = ['all']
      } else {
        newSelected = optionValues
      }
      return {selectedOptions: newSelected}
    })
  }

  renderOptions() {
    return this.props.options.map(option => {
      return (
        <Select.Option id={option.key} key={option.key} value={option.key}>
          {option.display}
        </Select.Option>
      )
    })
  }

  render() {
    return (
      <>
        <View
          borderWidth="small"
          borderRadius="medium"
          display="inline-block"
          width="100%"
          padding="x-small 0"
          margin="x-small 0 0"
        >
          <Flex margin="0 x-small 0 0" padding="0 0 0 small">
            <Flex.Item padding="0 0 xx-small">{this.props.icon}</Flex.Item>
            <Flex.Item width="10rem">
              <div
                style={{lineHeight: '2.25', padding: '0 .75rem', border: '1px solid transparent'}}
              >
                {this.props.name}
              </div>
            </Flex.Item>
            {this.props.options && (
              <Flex.Item>
                <Select
                  multiple={true}
                  closeOnSelect={false}
                  renderLabel={<ScreenReaderContent>{I18n.t('Options')}</ScreenReaderContent>}
                  selectedOption={this.state.selectedOptions}
                  onChange={this.handleInputChange}
                >
                  {this.renderOptions()}
                </Select>
              </Flex.Item>
            )}
            {this.props.readOnly ? null : (
              <Flex.Item margin="0 0 0 small" shouldGrow={true} textAlign="end">
                <Button renderIcon={IconTrashLine} onClick={this.onDelete}>
                  <ScreenReaderContent>{I18n.t('Delete this submission type')}</ScreenReaderContent>
                </Button>
              </Flex.Item>
            )}
          </Flex>
        </View>
      </>
    )
  }
}
