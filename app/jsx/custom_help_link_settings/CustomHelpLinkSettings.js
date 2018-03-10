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

import 'compiled/jquery.rails_flash_notifications'
import React from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!custom_help_link'
import $ from 'jquery'
import CustomHelpLinkIcons from './CustomHelpLinkIcons'
import CustomHelpLink from './CustomHelpLink'
import CustomHelpLinkForm from './CustomHelpLinkForm'
import CustomHelpLinkMenu from './CustomHelpLinkMenu'
import CustomHelpLinkPropTypes from './CustomHelpLinkPropTypes'

export default class CustomHelpLinkSettings extends React.Component {
  static propTypes = {
    name: PropTypes.string,
    links: PropTypes.arrayOf(CustomHelpLinkPropTypes.link),
    defaultLinks: PropTypes.arrayOf(CustomHelpLinkPropTypes.link),
    icon: PropTypes.string
  }

  static defaultProps = {
    name: I18n.t('Help'),
    icon: 'questionMark',
    defaultLinks: [],
    links: []
  }

  constructor(props) {
    super(props)
    let nextIndex = this.nextLinkIndex(props.links)
    const links = props.links.map(link => {
      return {
        ...link,
        id: link.id || `link${nextIndex++}`,
        available_to: link.available_to || [],
        state: link.state || 'active'
      }
    })

    this.state = {
      links,
      editing: null // id of link that is being edited
    }
  }

  getDefaultLinks = () => {
    const linkTexts = this.state.links.map(link => link.text)

    return this.props.defaultLinks.map(link => ({
      ...link,
      is_disabled: linkTexts.indexOf(link.text) > -1
    }))
  }

  nextLinkIndex = (links) => {
    let max = 0;
    links.forEach(link => {
      const match = link.id && link.id.match(/^link(\d+)$/)
      const index = match && parseInt(match[1], 10)
      if (index && index > max) {
        max = index
      }
    })
    return max + 1
  }

  // define handlers here so that we don't create one for each render
  handleMoveUp = link => {
    // if we are moving an element to the top slot, focus the previous component
    // instead of moving focus forward to the move-down button (see CNVS-35393)
    this.move(
      link,
      -1,
      link.index === 1 ? this.focusPreviousComponent : this.focus.bind(this, link.id, 'moveUp')
    )
  }

  handleMoveDown = link => {
    this.move(link, 1, this.focus.bind(this, link.id, 'moveDown'))
  }

  handleEdit = link => {
    this.edit(link)
  }

  handleRemove = link => {
    this.remove(link)
  }

  handleAdd = link => {
    this.add(link)
  }

  handleFormSave = link => {
    if (this.validate(link)) {
      this.update(link)
    }
  }

  handleFormCancel = link => {
    if (link.text) {
      this.cancelEdit(link)
    } else {
      this.remove(link)
    }
  }

  nextFocusable = start => {
    const links = this.state.links

    const nextIndex = function(i) {
      return i > 0 ? i - 1 : null
    }

    let focusable
    let index = nextIndex(start)

    while (!focusable && index !== null) {
      const id = links[index].id

      if (this.links[id].focusable()) {
        focusable = id
      }

      index = nextIndex(index)
    }

    return focusable
  }

  focus = (linkId, action) => {
    if (linkId) {
      const link = this.links[linkId]
      link.focus(action)
    } else {
      this.focusPreviousComponent()
    }
  }

  focusPreviousComponent = () => {
    $(
      '#custom_help_link_settings input[name="account[settings][help_link_icon]"]:checked'
    )[0].focus()
  }

  cancelEdit = link => {
    this.setState(
      {
        editing: null
      },
      this.focus.bind(this, link.id, 'edit')
    )
  }

  edit = link => {
    this.setState(
      {
        editing: link.id
      },
      this.focus.bind(this, link.id)
    )
  }

  add = link => {
    const links = [...this.state.links]
    const id = link.id || `link${this.nextLinkIndex(links)}`

    links.splice(0, 0, {
      ...link,
      state: link.type === 'default' ? link.state : 'new',
      id,
      type: link.type || 'custom'
    })

    this.setState(
      {
        links,
        editing: link.type === 'default' ? this.state.editing : id
      },
      this.focus.bind(this, id)
    )
  }

  update = link => {
    const links = [...this.state.links]

    links[link.index] = {
      ...link,
      state: link.text ? 'active' : link.state
    }

    this.setState(
      {
        links,
        editing: null
      },
      this.focus.bind(this, link.id, 'edit')
    )
  }

  remove = link => {
    const links = [...this.state.links]
    const editing = this.state.editing

    links.splice(link.index, 1)

    this.setState(
      {
        links,
        editing: editing === link.id ? null : editing
      },
      this.focus.bind(this, this.nextFocusable(link.index), 'remove')
    )
  }

  move = (link, change, callback) => {
    const links = [...this.state.links]

    links.splice(link.index + change, 0, links.splice(link.index, 1)[0])

    this.setState(
      {
        links
      },
      callback
    )
  }

  validate = link => {
    if (!link.text) {
      $.flashError(I18n.t('Please enter a name for this link.'))
      return false
    } else if (
      link.type !== 'default' &&
      (!link.url || !/((http|ftp)s?:\/\/)|(tel:)|(mailto:).+/.test(link.url))
    ) {
      $.flashError(
        I18n.t(
          'Please enter a valid URL. Protocol is required (e.g. http://, https://, ftp://, tel:, mailto:).'
        )
      )
      return false
    } else if (!link.available_to || link.available_to.length < 1) {
      $.flashError(I18n.t('Please select a user role for this link.'))
      return false
    } else {
      return true
    }
  }

  renderForm = link => (
    <CustomHelpLinkForm
      ref={c => {
        this.links[link.id] = c
      }}
      key={link.id}
      link={link}
      onSave={this.handleFormSave}
      onCancel={this.handleFormCancel}
    />
  )

  renderLink = link => {
    const {links} = this.state
    const {index, id} = link

    return (
      <CustomHelpLink
        ref={c => {
          this.links[link.id] = c
        }}
        key={id}
        link={link}
        onMoveUp={index === 0 ? null : this.handleMoveUp}
        onMoveDown={index === links.length - 1 ? null : this.handleMoveDown}
        onRemove={this.handleRemove}
        onEdit={this.handleEdit}
      />
    )
  }

  render() {
    const {name, icon} = this.props

    this.links = {}

    return (
      <fieldset>
        <h2 className="screenreader-only">{I18n.t('Help menu options')}</h2>
        <legend>{I18n.t('Help menu options')}</legend>
        <div className="ic-Form-group ic-Form-group--horizontal">
          <label className="ic-Form-control" htmlFor="account_settings_custom_help_link_name">
            <span className="ic-Label">{I18n.t('Name')}</span>
            <input
              id="account_settings_custom_help_link_name"
              type="text"
              className="ic-Input"
              required
              aria-required="true"
              name="account[settings][help_link_name]"
              defaultValue={name}
            />
          </label>
          <CustomHelpLinkIcons defaultValue={icon} />
          <div className="ic-Form-control ic-Form-control--top-align-label">
            <span className="ic-Label">{I18n.t('Help menu links')}</span>
            <div className="ic-Forms-component">
              {this.state.links.length > 0 ? (
                <ol className="ic-Sortable-list">
                  {this.state.links.map((link, index) => {
                    const linkWithIndex = {
                      ...link,
                      index // this is needed for moving up/down
                    }
                    return linkWithIndex.id === this.state.editing
                      ? this.renderForm(linkWithIndex)
                      : this.renderLink(linkWithIndex)
                  })}
                </ol>
              ) : (
                <span>
                  <input type="hidden" name="account[custom_help_links][0][text]" value="" />
                  <input
                    type="hidden"
                    name="account[custom_help_links][0][state]"
                    value="deleted"
                  />
                </span>
              )}
              <div className="ic-Sortable-list-add-new">
                <CustomHelpLinkMenu
                  ref={c => {
                    this.links.addLink = c
                  }}
                  links={this.getDefaultLinks()}
                  onChange={this.handleAdd}
                />
              </div>
            </div>
          </div>
        </div>
      </fieldset>
    )
  }
}
