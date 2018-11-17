/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import _ from 'underscore'
import React from 'react'
import createReactClass from 'create-react-class'
import I18n from 'i18n!restrict_student_access'
import $ from 'jquery'
import classNames from 'classnames'
import UsageRightsSelectBox from '../files/UsageRightsSelectBox'
import RestrictedRadioButtons from '../files/RestrictedRadioButtons'
import DialogPreview from '../files/DialogPreview'
import RestrictedDialogForm from 'compiled/react_files/components/RestrictedDialogForm'

RestrictedDialogForm.renderUsageRightsWarning = function() {
  return (
    <div className="RestrictedDialogForm__banner col-xs-12">
      <span className="alert">
        <i className="icon-warning RestrictedDialogForm__warning" />
        {I18n.t('Before publishing, you must set usage rights on your files.')}
      </span>
    </div>
  )
}

// Renders out the restricted access form
// - options is an object which can be used to conditionally set certain aspects
//   of rendering.
//   Future Refactor: Move this to another component should it's use elsewhere
//                  be meritted.
RestrictedDialogForm.renderRestrictedAccessForm = function(options) {
  const formContainerClasses = classNames({
    RestrictedDialogForm__form: true,
    'col-xs-9': true,
    'off-xs-3': options && options.offset
  })

  return (
    <div className={formContainerClasses}>
      <form
        ref={e => (this.dialogForm = e)}
        onSubmit={this.handleSubmit}
        className="form-horizontal form-dialog permissions-dialog-form"
      >
        <RestrictedRadioButtons
          ref={e => (this.restrictedSelection = e)}
          models={this.props.models}
          radioStateChange={this.radioStateChange}
        />
        <div className="form-controls">
          <button type="button" onClick={this.props.closeDialog} className="btn">
            {I18n.t('Cancel')}
          </button>
          <button
            ref={e => (this.updateBtn = e)}
            type="submit"
            className="btn btn-primary"
            disabled={!this.state.submitable}
          >
            {I18n.t('Update')}
          </button>
        </div>
      </form>
    </div>
  )
}

RestrictedDialogForm.render = function() {
  // Doing this here to prevent possible repeat runs of this.usageRightsOnAll and this.allFolders
  const showUsageRights =
    this.props.usageRightsRequiredForContext && !this.usageRightsOnAll() && !this.allFolders()

  return (
    <div className="RestrictedDialogForm__container">
      {/* If showUsageRights then show the Usage Rights Warning */}
      {!!showUsageRights && (
        <div className="RestrictedDialogForm__firstRow grid-row">
          {this.renderUsageRightsWarning()}
        </div>
      )}
      <div className="RestrictedDialogForm__secondRow grid-row">
        <div className="RestrictedDialogForm__preview col-xs-3">
          <DialogPreview itemsToShow={this.props.models} />
        </div>
        {/* If showUsageRights then show the select box for it.*/}
        {!!showUsageRights && (
          <div className="RestrictedDialogForm__usageRights col-xs-9">
            <UsageRightsSelectBox ref={e => (this.usageSelection = e)} />
            <hr />
          </div>
        )}
        {/* Not showing usage rights?, then show the form here.*/}
        {!showUsageRights && this.renderRestrictedAccessForm()}
      </div>
      {/* If showUsageRights,] it needs to be here instead */}
      {!!showUsageRights && (
        <div className="RestrictedDialogForm__thirdRow grid-row">
          {this.renderRestrictedAccessForm({offset: true})}
        </div>
      )}
    </div>
  )
}

export default createReactClass(RestrictedDialogForm)
