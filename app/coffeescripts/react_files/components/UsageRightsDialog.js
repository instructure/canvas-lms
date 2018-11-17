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
import I18n from 'i18n!usage_rights_modal'
import customPropTypes from '../modules/customPropTypes'
import filesEnv from '../modules/filesEnv'
import setUsageRights from '../utils/setUsageRights'
import updateModelsUsageRights from '../utils/updateModelsUsageRights'
import '../../jquery.rails_flash_notifications'
import 'jquery.instructure_forms'

export default {
  displayName: 'ManageUsageRightsModal',

  propTypes: {
    isOpen: PropTypes.bool,
    closeModal: PropTypes.func,
    itemsToManage: PropTypes.arrayOf(customPropTypes.filesystemObject).isRequired
  },

  componentWillMount() {
    this.copyright = this.defaultCopyright()
    this.use_justification = this.defaultSelectedRight()
    return (this.cc_value = this.defaultCCValue())
  },

  apiUrl: `/api/v1/${filesEnv.contextType}/${filesEnv.contextId}/usage_rights`,

  copyright: null,
  use_justification: null,

  submit() {
    const values = this.usageSelection.getValues()

    // They didn't choose a copyright
    if (values.use_justification === 'choose') {
      $(this.usageSelection.usageRightSelection).errorBox(I18n.t('You must specify a usage right.'))
      return false
    }

    const usageRightValue = {
      use_justification: values.use_justification,
      legal_copyright: values.copyright,
      license: values.cc_license
    }

    const afterSet = (success, data) => {
      if (success) {
        updateModelsUsageRights(data, this.props.itemsToManage)
        $.flashMessage(I18n.t('Usage rights have been set.'))
        this.setRestrictedAccess(this.restrictedSelection.extractFormValues())
      } else {
        $.flashError(I18n.t('There was an error setting usage rights.'))
      }
      return this.props.closeModal()
    }

    return setUsageRights(this.props.itemsToManage, usageRightValue, afterSet)
  },

  setRestrictedAccess(attributes) {
    return this.props.itemsToManage.every(item => item.save({}, {attrs: attributes}))
  },

  // Determines the default usage right to be selected
  defaultSelectedRight() {
    const useJustification =
      this.props.itemsToManage[0].get('usage_rights') &&
      this.props.itemsToManage[0].get('usage_rights').use_justification

    if (
      this.props.itemsToManage.every(
        item =>
          (item.get('usage_rights') && item.get('usage_rights').use_justification) ===
          useJustification
      )
    ) {
      return useJustification
    } else {
      return 'choose'
    }
  },

  defaultCopyright() {
    const copyright =
      (this.props.itemsToManage[0].get('usage_rights') &&
        this.props.itemsToManage[0].get('usage_rights').legal_copyright) ||
      ''
    if (
      this.props.itemsToManage.every(
        item =>
          (item.get('usage_rights') && item.get('usage_rights').legal_copyright) === copyright ||
          (item.get('usage_rights') && item.get('usage_rights').license) === copyright
      )
    ) {
      return copyright
    } else {
      return null
    }
  },

  defaultCCValue() {
    if (this.use_justification === 'creative_commons') {
      return (
        this.props.itemsToManage[0].get('usage_rights') &&
        this.props.itemsToManage[0].get('usage_rights').license
      )
    } else {
      return null
    }
  }
}
