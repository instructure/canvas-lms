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
import I18n from 'i18n!custom_help_link'
import CustomHelpLinkPropTypes from './CustomHelpLinkPropTypes'
import CustomHelpLinkHiddenInputs from './CustomHelpLinkHiddenInputs'
import CustomHelpLinkAction from './CustomHelpLinkAction'
import {Pill} from '@instructure/ui-pill'

export default class CustomHelpLink extends React.Component {
  static propTypes = {
    link: CustomHelpLinkPropTypes.link.isRequired,
    onMoveUp: PropTypes.func,
    onMoveDown: PropTypes.func,
    onEdit: PropTypes.func,
    onRemove: PropTypes.func
  }

  static defaultProps = {
    onMoveUp: () => {},
    onMoveDown: () => {},
    onEdit: () => {},
    onRemove: () => {}
  }

  focus = action => {
    // screenreaders are the worst
    // We have to force a focus change and a delay because clicking the "up" or "delete" buttons
    // just causes React to rearrange the DOM nodes, so the focus doesn't actually change. If the
    // focus doesn't change, screenreaders don't read the up button or delete button again like we
    // want them to. If we don't delay, then screenreaders don't notice the focus changed.
    this.actions.edit.focus()
    setTimeout(() => {
      const ref = this.actions[action]

      if (ref && ref.props.onClick) {
        ref.focus()
      } else {
        const focusable = this.focusable()
        if (focusable) {
          focusable.focus()
        }
      }
    }, 100)
  }

  focusable = () => {
    const focusable = this.rootElement?.querySelectorAll('button:not([disabled])')
    return focusable?.[0]
  }

  renderPill() {
    if (!ENV?.FEATURES?.featured_help_links) {
      return null
    }
    const {is_featured, is_new} = this.props.link
    if (is_featured || is_new) {
      const text = is_featured ? I18n.t('Featured') : I18n.t('New')
      return <Pill variant="success" margin="0 small" text={text} />
    } else {
      return null
    }
  }

  render() {
    const {text} = this.props.link

    this.actions = {}

    return (
      <li
        className="ic-Sortable-item"
        ref={c => {
          this.rootElement = c
        }}
      >
        <div className="ic-Sortable-item__Text">
          {text}
          {this.renderPill()}
        </div>
        <div className="ic-Sortable-item__Actions">
          <div className="ic-Sortable-sort-controls">
            <CustomHelpLinkAction
              ref={c => {
                this.actions.moveUp = c
              }}
              link={this.props.link}
              label={I18n.t('Move %{text} up', {text})}
              onClick={this.props.onMoveUp}
              iconClass="icon-mini-arrow-up"
            />
            <CustomHelpLinkAction
              ref={c => {
                this.actions.moveDown = c
              }}
              link={this.props.link}
              label={I18n.t('Move %{text} down', {text})}
              onClick={this.props.onMoveDown}
              iconClass="icon-mini-arrow-down"
            />
          </div>
          <CustomHelpLinkAction
            ref={c => {
              this.actions.edit = c
            }}
            link={this.props.link}
            label={I18n.t('Edit %{text}', {text})}
            onClick={this.props.onEdit}
            iconClass="icon-edit"
          />
          <CustomHelpLinkAction
            ref={c => {
              this.actions.remove = c
            }}
            link={this.props.link}
            label={I18n.t('Remove %{text}', {text})}
            onClick={this.props.onRemove}
            iconClass="icon-trash"
          />
        </div>
        <CustomHelpLinkHiddenInputs link={this.props.link} />
      </li>
    )
  }
}
