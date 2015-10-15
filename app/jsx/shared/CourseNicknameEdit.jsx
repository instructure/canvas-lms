/** @jsx React.DOM */

define([
  'jquery',
  'react',
  'i18n!course_nickname_edit',
], function ($, React, I18n) {

  var CourseNicknameEdit = React.createClass({

    // ===============
    //     CONFIG
    // ===============

    displayName: 'CourseNicknameEdit',

    propTypes: {
      nicknameInfo: React.PropTypes.object.isRequired
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

    handleChange (event) {
      this.setState({nickname:event.target.value});
    },

    setCourseNickname () {
      if (this.state.originalNickname != this.state.nickname) {
        $.ajax({
            url: '/api/v1/users/self/course_nicknames/' + this.props.nicknameInfo.courseId,
            type: (this.state.nickname.length > 0) ? 'PUT' : 'DELETE',
            data: {
              nickname: this.state.nickname
            },
            success: (data) => {
              this.props.nicknameInfo.onNicknameChange(data.nickname || data.name);
            },
            error: () => {
              console.log('Error setting course nickname');
            }
        });
      }
    },

    // ===============
    //    RENDERING
    // ===============

    render () {
      return (
        <div className='ic-Form-control'>
          <label htmlFor='NicknameInput' className='ic-Label'>
            {I18n.t('Nickname:')}
          </label>
          <input id='NicknameInput'
                 type='text'
                 ref='nicknameInput'
                 className='ic-Input'
                 placeholder={this.props.nicknameInfo.originalName}
                 value={this.state.nickname}
                 onChange={this.handleChange}
          />
        </div>
      );
    }

  });
  return CourseNicknameEdit;
});