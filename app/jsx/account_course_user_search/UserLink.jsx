define([
  "react",
  "i18n!account_course_user_search"
], function(React, I18n) {

  var UserLink = React.createClass({
    propTypes: {
      id: React.PropTypes.string.isRequired,
      display_name: React.PropTypes.string.isRequired,
      avatar_image_url: React.PropTypes.string
    },

    render() {
      var { id, display_name, avatar_image_url } = this.props;
      var url = `/users/${id}`;
      return (
        <div>
          {!!avatar_image_url &&
          <span className="ic-avatar" style={{width: 30, height: 30, margin: "-1px 10px 1px 0"}}>
              <img src={avatar_image_url} />
            </span>
          }
          <a href={url} className="user_link">{display_name}</a>
        </div>
      );
    }
  });

  return UserLink;
});
