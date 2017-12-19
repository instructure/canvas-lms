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

import React from 'react'
import ReactDOM from 'react-dom'
import I18n from 'i18n!modules'
import PostGradesDialog from '../../gradebook/SISGradePassback/PostGradesDialog'
import classnames from 'classnames'

  // The PostGradesApp mounts a single "Sync Grades" button, which pops up
  // the PostGradesDialog when clicked.

  var PostGradesApp = React.createClass({
    componentDidMount () {
      this.boundForceUpdate = this.forceUpdate.bind(this)
      this.props.store.addChangeListener(this.boundForceUpdate)
    },
    componentWillUnmount () { this.props.store.removeChangeListener(this.boundForceUpdate) },

    render () {
      var navClass = classnames({
        "ui-button": this.props.renderAsButton
      });
      if(this.props.renderAsButton){
        return (
          <button
            id="post-grades-button"
            className={navClass}
            onClick={this.openDialog}
          >{this.props.labelText}</button>
        );
      } else {
        return (
          <a
            id="post-grades-button"
            className={navClass}
            onClick={this.openDialog}
          >{this.props.labelText}</a>
        );
      }
    },

    openDialog(e) {
      e.preventDefault();
      var returnFocusTo = this.props.returnFocusTo;

      var $dialog = $('<div class="post-grades-dialog">').dialog({
        title: I18n.t('Sync Grades to SIS'),
        maxWidth: 650,     maxHeight: 450,
        minWidth: 650,     minHeight: 450,
        width:    650,     height:    450,
        resizable: false,
        buttons: [],
        close(e) {
          ReactDOM.unmountComponentAtNode(this);
          $(this).remove();
          if(returnFocusTo){
            returnFocusTo.focus();
          }
        }
      });

      var closeDialog = function(e) {
        e.preventDefault();
        $dialog.dialog('close');
      }

      this.props.store.reset()
      ReactDOM.render(<PostGradesDialog store={this.props.store} closeDialog={closeDialog} />, $dialog[0]);
    },
  });

export default PostGradesApp
