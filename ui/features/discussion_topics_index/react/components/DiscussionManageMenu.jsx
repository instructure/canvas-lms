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
import {useScope as useI18nScope} from '@canvas/i18n'
import React, {Component} from 'react'
import {func, string} from 'prop-types'

import {Button} from '@instructure/ui-buttons'
import {IconMoreLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('shared_components')

export default class DiscussionManageMenu extends Component {
  static propTypes = {
    onSelect: func.isRequired,
    // This should be a *function* that returns an array of MenuList
    // components; this way we don't actually create a gargantuan array
    // of things until we actually need them (i.e. when this menu is
    // clicked).  This somewhat benefits performance in discussions, where
    // we might have hundreds on the page.
    menuOptions: func.isRequired,
    entityTitle: string.isRequired,
    // Use this if you want the calling component to have a handle to this menu
    menuRefFn: func,
  }

  static defaultProps = {
    menuRefFn: _ => {},
  }

  state = {
    manageMenuOpen: false,
  }

  toggleManageMenuOpen = (shown, _) => {
    this.setState({manageMenuOpen: shown})
  }

  render() {
    return (
      <span className="discussions-index-manage-menu">
        <Menu
          ref={this.props.menuRefFn}
          onSelect={this.props.onSelect}
          onToggle={this.toggleManageMenuOpen}
          trigger={
            <Button renderIcon={IconMoreLine} size="small">
              <ScreenReaderContent>
                {I18n.t('Manage options for %{name}', {name: this.props.entityTitle})}
              </ScreenReaderContent>
            </Button>
          }
        >
          {this.state.manageMenuOpen ? this.props.menuOptions() : null}
        </Menu>
      </span>
    )
  }
}
