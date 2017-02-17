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
      nicknameInfo: React.PropTypes.object.isRequired,
      onEnter: React.PropTypes.func
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
        <div className='ic-Form-control'>
          <label htmlFor='NicknameInput' className='ic-Label'>
            {I18n.t('Nickname:')}
          </label>
          <input
            id="NicknameInput"
            type="text"
            ref={(c) => { this.nicknameInput = c; }}
            className="ic-Input"
            maxLength="59"
            placeholder={this.props.nicknameInfo.originalName}
            value={this.state.nickname}
            onChange={this.handleChange}
            onKeyPress={this.onKeyPress}
          />
        </div>
      );
    }

  });
  return CourseNicknameEdit;
});
