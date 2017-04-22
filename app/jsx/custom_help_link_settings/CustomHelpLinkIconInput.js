import React from 'react'

  const CustomHelpLinkIconInput = React.createClass({
    propTypes: {
      value: React.PropTypes.string.isRequired,
      children: React.PropTypes.node.isRequired,
      label: React.PropTypes.string.isRequired,
      defaultChecked: React.PropTypes.bool
    },
    getDefaultProps () {
      return {
        checked: false
      }
    },
    render () {
      const {
        value,
        icon,
        label,
        defaultChecked,
        children
      } = this.props
      return (
        <label className="ic-Radio ic-Radio--icon-only" data-icon-value={value}>
          <input type="radio" value={value} name="account[settings][help_link_icon]" defaultChecked={defaultChecked} />
          <span className="ic-Label">
            <span className="screenreader-only">{label}</span>
            {children}
          </span>
        </label>
      )
    }
  });

export default CustomHelpLinkIconInput
