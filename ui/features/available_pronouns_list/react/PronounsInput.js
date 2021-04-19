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

import React from 'react'
import {Tag} from '@instructure/ui-tag'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {nanoid} from 'nanoid'
import {IconInfoLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Tooltip} from '@instructure/ui-tooltip'
import I18n from 'i18n!PronounsInput'

export default class PronounsInput extends React.Component {
  constructor(props) {
    super(props)

    const pronounList = ENV.PRONOUNS_LIST.filter(x => x !== null)

    this.state = {
      pronouns: pronounList,
      input_id: `new_pronoun_input_${nanoid()}`
    }
  }

  createNewTag = value => (
    <>
      <Tag
        dismissible
        key={`pronoun_${value}`}
        text={value}
        margin="0 small 0 0"
        onClick={() => this.deletePronoun(value)}
      />
      <input
        key={`pronoun_input_holder_${value}`}
        name="account[pronouns][]"
        type="hidden"
        value={value}
      />
    </>
  )

  handleChange = (e, value) => {
    this.setState({value})
  }

  deletePronoun = pronounToDelete => {
    this.setState(prevState => ({
      pronouns: prevState.pronouns.filter(pronoun => pronounToDelete !== pronoun)
    }))
  }

  render() {
    const infoToolTip = I18n.t(
      'These pronouns will be available to Canvas users in your account to choose from.'
    )
    return (
      <TextInput
        id={`${this.state.input_id}`}
        data-testid="test_pronoun_input"
        onChange={this.handleChange}
        onKeyDown={e => {
          if (e.key === 'Enter') {
            e.preventDefault()
            this.setState(prevState => {
              if (prevState.value && prevState.value.trim() !== '') {
                prevState.pronouns.push(prevState.value.trim())
                return {pronouns: [...new Set(prevState.pronouns)]}
              }
              return prevState
            })
            document.querySelector(`#${this.state.input_id}`).value = ''
          }
        }}
        label={
          <>
            <Text>{I18n.t('Available Pronouns')}</Text>
            <Tooltip tip={infoToolTip} on={['hover', 'focus']} variant="inverse">
              <span
                style={{margin: '0 10px 0 10px'}}
                // eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex
                tabIndex="0"
              >
                <IconInfoLine data-testid="pronoun_info" />
                <ScreenReaderContent>{infoToolTip}</ScreenReaderContent>
              </span>
            </Tooltip>
          </>
        }
        size="medium"
        resize="vertical"
        height="4 rem"
        renderBeforeInput={this.state.pronouns.map(pronoun => {
          return this.createNewTag(pronoun)
        })}
      />
    )
  }
}
