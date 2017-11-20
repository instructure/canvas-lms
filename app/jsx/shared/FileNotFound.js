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

import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import ReactDOM from 'react-dom'
import I18n from 'i18n!file_not_found'

  const LABEL_TEXT = I18n.t('Please let them know which page you were viewing and the link you clicked on.');

  class FileNotFound extends React.Component {
    constructor () {
      super();
      this.state = {
        status: 'composing'
      };
    }

    submitMessage = (e) => {
      e.preventDefault();
      const conversationData = {
        subject: I18n.t('Broken file link found in your course'),
        recipients: this.props.contextCode + '_teachers',
        body: `${I18n.t('This most likely happened because you imported course content without its associated files.')}

        ${I18n.t('This student wrote:')} ${ReactDOM.findDOMNode(this.refs.message).value}`,
        context_code: this.props.contextCode
      };

      const dfd = $.post('/api/v1/conversations', conversationData);
      $(ReactDOM.findDOMNode(this.refs.form)).disableWhileLoading(dfd);

      dfd.done(() => this.setState({status: 'sent'}));
    }

    render () {
      if (this.state.status === 'composing') {
        return (
          <div>
            <p>{I18n.t('Be a hero and ask your instructor to fix this link.')}</p>
            <form
              style={{marginBottom: 0}}
              ref='form'
              onSubmit={this.submitMessage}
            >
              <div className='form-group pad-box'>
                <label htmlFor='fnfMessage' className='screenreader-only'>
                  {LABEL_TEXT}
                </label>
                <textarea
                  className='input-block-level'
                  id='fnfMessage'
                  placeholder={LABEL_TEXT}
                  ref='message'
                />
              </div>
              <div className='form-actions' style={{marginBottom: 0}}>
                <button type='submit' className='btn btn-primary'>{I18n.t('Send')}</button>
              </div>
            </form>
          </div>
        );
      } else {
        return (
          <p>{I18n.t('Your message has been sent. Thank you!')}</p>
        );
      }
    }
  }

  FileNotFound.propTypes = {
    contextCode: PropTypes.string.isRequired
  };

export default FileNotFound
