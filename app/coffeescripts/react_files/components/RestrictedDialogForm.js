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
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'
import I18n from 'i18n!restrict_student_access'
import Folder from '../../models/Folder'
import customPropTypes from '../modules/customPropTypes'
import setUsageRights from '../utils/setUsageRights'
import updateModelsUsageRights from '../utils/updateModelsUsageRights'
import 'jquery.instructure_date_and_time'
import 'jquery.instructure_forms'

export default {
  displayName: 'RestrictedDialogForm',

  propTypes: {
    closeDialog: PropTypes.func.isRequired,
    models: PropTypes.arrayOf(customPropTypes.filesystemObject).isRequired,
    usageRightsRequiredForContext: PropTypes.bool.isRequired
  },

  getInitialState() {
    return {submitable: false}
  },

  componentDidMount() {
    this.updateSubmitable()
    $('.ui-dialog-titlebar-close').focus()
  },

  updateSubmitable() {
    if (this.refs.restrictedSelection.state && this.refs.restrictedSelection.state.selectedOption) {
      this.setState({submitable: true})
    }
  },

  // === Custom Functions === #
  // Function Summary
  //
  // Event though you can technically set each of these fields independently, since we
  // are using them with a radio button we will grab all of the values and treat it as
  // a state based on the input fields.

  handleSubmit(event) {
    event.preventDefault()

    if (
      this.props.usageRightsRequiredForContext &&
      !this.usageRightsOnAll() &&
      !this.allFolders()
    ) {
      const values = this.refs.usageSelection.getValues()
      // They didn't choose a use justification
      if (values.use_justification === 'choose') {
        $(ReactDOM.findDOMNode(this.refs.usageSelection.refs.usageRightSelection)).errorBox(
          I18n.t('You must specify a usage right.')
        )
        return false
      }

      const usageRightValue = {
        use_justification: values.use_justification,
        legal_copyright: values.copyright,
        license: values.cc_license
      }

      // We need to first set usage rights before handling the setting of
      // restricted access things.
      return setUsageRights(this.props.models, usageRightValue, (success, data) => {
        if (success) {
          updateModelsUsageRights(data, this.props.models)
          this.setRestrictedAccess()
        } else {
          $.flashError(I18n.t('There was an error setting usage rights.'))
        }
      })
    } else {
      this.setRestrictedAccess()
    }
  },

  setRestrictedAccess() {
    const attributes = this.refs.restrictedSelection.extractFormValues()
    if (attributes.unlock_at && attributes.lock_at && attributes.unlock_at > attributes.lock_at) {
      $(ReactDOM.findDOMNode(this.refs.restrictedSelection.refs.unlock_at)).errorBox(
        I18n.t('"Available From" date must precede "Available Until"')
      )
      return false
    }
    const promises = this.props.models.map(item =>
      // Calling .save like this (passing data as the 'attrs' property on
      // the 'options' argument instead of as the first argument) is so that we just send
      // the 3 attributes we care about (hidden, lock_at, unlock_at) in the PUT
      // request (like you would for a PATCH request, execept our api doesn't support PATCH).
      // We do this so if some other user changes the name while we are looking at the page,
      // when we submit this form, we don't blow away their change and change the name back
      // to what it was. we just update the things we intended.
      item.save({}, {attrs: attributes})
    )

    const dfd = $.when(...Array.from(promises || []))
    dfd.done(() => this.props.closeDialog())
    $(ReactDOM.findDOMNode(this.refs.dialogForm)).disableWhileLoading(dfd)
  },

  /*
     * Returns true if all the models passed in have usage rights
     */
  usageRightsOnAll() {
    return this.props.models.every(model => model.get('usage_rights'))
  },

  /*
     * Returns true if all the models passed in are folders.
     */
  allFolders() {
    return this.props.models.every(model => model instanceof Folder)
  },

  /*
     * Returns true if all the models passed in are folders.
     */
  anyFolders() {
    return this.props.models.filter(model => model instanceof Folder).length
  },

  // callback function passed to RestrictedRadioButtons as props
  // for disabling/enabling of the Update Button
  radioStateChange() {
    this.setState({submitable: true})
  }
}
