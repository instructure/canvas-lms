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

import React from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Menu} from '@instructure/ui-menu'
import {Button} from '@instructure/ui-buttons'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {IconPlusLine} from '@instructure/ui-icons'
import CustomHelpLinkPropTypes from './CustomHelpLinkPropTypes'
import CustomHelpLinkConstants from './CustomHelpLinkConstants'

const I18n = useI18nScope('custom_help_link')

export default class CustomHelpLinkMenu extends React.Component {
  static propTypes = {
    links: PropTypes.arrayOf(CustomHelpLinkPropTypes.link).isRequired,
    onChange: PropTypes.func,
  }

  static defaultProps = {
    onChange: () => {},
  }

  handleChange = (e, link) => {
    if (link.is_disabled) {
      e.preventDefault()
      return
    }
    if (typeof this.props.onChange === 'function') {
      e.preventDefault()
      this.props.onChange(link)
    }
  }

  focus = () => {
    this.addButton.focus()
  }

  focusable = () => this.addButton

  handleAddLinkSelection = (e, selected) => {
    const item = selected[0]
    if (item === 'add_custom_link') {
      this.handleChange(e, {...CustomHelpLinkConstants.DEFAULT_LINK})
    } else {
      this.handleChange(e, this.props.links.filter(l => l.text === item)[0])
    }
  }

  render() {
    return (
      <div className="HelpMenuOptions__Container">
        <Menu
          trigger={
            <Button
              ref={c => {
                this.addButton = c
              }}
            >
              <AccessibleContent alt={I18n.t('Add Link')}>
                <IconPlusLine className="HelpMenuOptions__ButtonIcon" />
                &nbsp; {I18n.t('Link')}
              </AccessibleContent>
            </Button>
          }
        >
          <Menu.Group label={I18n.t('Add help menu links')} onSelect={this.handleAddLinkSelection}>
            <Menu.Item key="add_custom_link" value="add_custom_link">
              {I18n.t('Add Custom Link')}
            </Menu.Item>
            {this.props.links.map(link => (
              <Menu.Item key={link.text} value={link.text} disabled={link.is_disabled}>
                {link.text}
              </Menu.Item>
            ))}
          </Menu.Group>
        </Menu>
      </div>
    )
  }
}
