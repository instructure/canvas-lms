define([
  'react',
  'instructure-ui/Avatar'
], (React, { default: InstUIAvatar }) => {

  class Avatar extends React.Component {
    static propTypes = {
      user: React.PropTypes.object.isRequired
    }

    render () {
      if (Object.keys(this.props.user).includes('avatar_url')) {
        return (
          <div className="StudentContextTray__Avatar">
            <InstUIAvatar
              size="x-large"
              userName={this.props.user.name}
              userImgUrl={this.props.user.avatar_url}
            />
          </div>
        )
      } else { return null }
    }
  }

  return Avatar
})
