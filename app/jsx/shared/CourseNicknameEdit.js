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
import I18n from 'i18n!course_nickname_edit'
import TextInput from '@instructure/ui-core/lib/components/TextInput'

  var CourseNicknameEdit = React.createClass({

    // ===============
    //     CONFIG
    // ===============

    displayName: 'CourseNicknameEdit',

    propTypes: {
      nicknameInfo: PropTypes.object.isRequired,
      onEnter: PropTypes.func
    },

    // ===============
    //    LIFECYCLE
    // ===============

    getInitialState () {
      var nickname = (this.props.nicknameInfo.nickname == this.props.nicknameInfo.originalName) ?
        '' : this.props.nicknameInfo.nickname;
      return {nickname: nickname, originalNickname: nickname};
    },

    // ===============
    //     ACTIONS
    // ===============

    onKeyPress (event) {
      if (this.props.onEnter && event.charCode == 13) {
        this.props.onEnter();
      }
    },

    handleChange (event) {
      this.setState({nickname:event.target.value});
    },

    setCourseNickname () {
      if (this.state.originalNickname != this.state.nickname) {
        return $.ajax({
            url: '/api/v1/users/self/course_nicknames/' + this.props.nicknameInfo.courseId,
            type: (this.state.nickname.length > 0) ? 'PUT' : 'DELETE',
            data: {
              nickname: this.state.nickname
            },
            success: (data) => {
              this.props.nicknameInfo.onNicknameChange(data.nickname || data.name);
            },
            error: () => {
            }
        });
      }
    },

    focus () {
      if (this.nicknameInput) {
        this.nicknameInput.focus();
      }
    },

    // ===============
    //    RENDERING
    // ===============

    render () {
      return (
        <TextInput
          id="NicknameInput"
          label={ I18n.t('Nickname') }
          placeholder={this.props.nicknameInfo.originalName}
          value={this.state.nickname}
          onChange={this.handleChange}
          onKeyPress={this.onKeyPress}
          inputRef={(c) => { this.nicknameInput = c }}
          size="small"
        />
      );
    }

  });
export default CourseNicknameEdit
