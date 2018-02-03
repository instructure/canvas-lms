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
import I18n from 'i18n!editor'
import RichContentEditor from '../shared/rce/RichContentEditor'

  var SwitchEditorControl = React.createClass({
    displayName: 'SwitchEditor',
    propTypes: {
      textarea: PropTypes.object.isRequired
    },

    getInitialState () {
      return { mode: "rce" };
    },

    toggle(e){
      e.preventDefault()
      RichContentEditor.callOnRCE(this.props.textarea, 'toggle')
      if(this.state.mode == "rce"){
        this.setState({mode: "html"})
      }else{
        this.setState({mode: "rce"})
      }
    },

    //
    // Rendering
    //

    switchLinkText(){
      if(this.state.mode == 'rce'){
        return I18n.t('switch_editor_html', 'HTML Editor')
      }else {
        return I18n.t('switch_editor_rich_text', 'Rich Content Editor')
      }
    },

    linkClass(){
      if(this.state.mode == 'rce'){
        return "switch-views__link__html"
      }else {
        return "switch-views__link__rce"
      }
    },

    render() {
      return (
        <div style={{float: "right"}}>
          <a href="#" className={this.linkClass()} onClick={this.toggle}>
            {this.switchLinkText()}
          </a>
        </div>
      );
    }
  });

export default SwitchEditorControl
