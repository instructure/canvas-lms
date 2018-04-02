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

import $ from 'jquery'
import PropTypes from 'prop-types'
import I18n from 'i18n!broccoli_cloud'
import customPropTypes from '../modules/customPropTypes'
import '../../jquery.rails_flash_notifications'

export default {
  displayName: 'PublishCloud',

  propTypes: {
    togglePublishClassOn: PropTypes.object,
    model: customPropTypes.filesystemObject,
    userCanManageFilesForContext: PropTypes.bool.isRequired,
    fileName: PropTypes.string
  },

  // == React Functions == #
  getInitialState() {
    return this.extractStateFromModel(this.props.model)
  },

  componentDidMount() {
    if (this.props.togglePublishClassOn) this.updatePublishClassElements()
  },
  componentDidUpdate() {
    if (this.props.togglePublishClassOn) this.updatePublishClassElements()
  },

  componentWillMount() {
    const setState = model => this.setState(this.extractStateFromModel(model))
    this.props.model.on('change', setState, this)
  },

  componentWillUnmount() {
    this.props.model.off(null, null, this)
  },

  updatePublishClassElements() {
    return this.props.togglePublishClassOn.classList[this.state.published ? 'add' : 'remove'](
      'ig-published'
    )
  },

  getRestrictedText() {
    if (this.props.model.get('unlock_at') && this.props.model.get('lock_at')) {
      return I18n.t('Available after %{unlock_at} until %{lock_at}', {
        unlock_at: $.datetimeString(this.props.model.get('unlock_at')),
        lock_at: $.datetimeString(this.props.model.get('lock_at'))
      })
    } else if (this.props.model.get('unlock_at') && !this.props.model.get('lock_at')) {
      return I18n.t('Available after %{unlock_at}', {
        unlock_at: $.datetimeString(this.props.model.get('unlock_at'))
      })
    } else if (!this.props.model.get('unlock_at') && this.props.model.get('lock_at')) {
      return I18n.t('Available until %{lock_at}', {
        lock_at: $.datetimeString(this.props.model.get('lock_at'))
      })
    }
  },

  // == Custom Functions == #

  // Function Summary
  // extractStateFromModel expects a backbone model wtih the follow attributes
  // * hidden, lock_at, unlock_at
  //
  // It takes those attributes and returns an object that can be used to set the
  // components internal state
  //
  // returns object

  extractStateFromModel(model) {
    return {
      published: !model.get('locked'),
      restricted: !!model.get('lock_at') || !!model.get('unlock_at'),
      hidden: !!model.get('hidden')
    }
  },

  // Function Summary
  // Toggling always sets restricted state to false because we only
  // allow publishing/unpublishing in this component.

  togglePublishedState() {
    this.setState({published: !this.state.published, restricted: false, hidden: false})
  }
}
