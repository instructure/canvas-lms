define([
  'react',
  'classnames',
], (React, classnames) => {
  const { bool, object, func } = React.PropTypes

  return class StickySidebar extends React.Component {
    static propTypes = {
      children: object,
      isHidden: bool,
      closeSidebar: func.isRequired,
    }

    componentDidUpdate (prevProps) {
      if (!this.props.isHidden && prevProps.isHidden) {
        this.refs.closeBtn.focus()
      }
    }

    render () {
      const sidebarClasses = classnames({
        'crs-sticky-sidebar': true,
        'crs-sticky-sidebar__hidden': this.props.isHidden,
      })

      return (
        <div className={sidebarClasses}>
          <button ref='closeBtn' className='Button Button--icon-action crs-sticky-sidebar__close' aria-label='close' onClick={this.props.closeSidebar} type='button'>
            <i aria-hidden className='icon-x crs-icon-x'></i>
          </button>
          {this.props.children}
        </div>
      )
    }
  }
})
