/** @jsx React.DOM */
define([
  'react',
  'i18n!gradebook'
], function (React, I18n) {

  var HeaderDropdownOption = React.createClass({

    propTypes: {
      title: React.PropTypes.string.isRequired,
      dataAction: React.PropTypes.string,
      url: React.PropTypes.string,
      handleClick: React.PropTypes.func
    },

    render() {
      return (
        <li>
          <a data-action={this.props.dataAction}
             href={this.props.url || '#'}
             onClick={this.props.handleClick}
             ref='link'>
            {this.props.title}
          </a>
        </li>
      );
    }
  });

  return HeaderDropdownOption;
});
