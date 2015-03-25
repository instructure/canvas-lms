/** @jsx React.DOM */

define([
  'old_unsupported_dont_use_react',
  './SFUCopyrightComplianceNoticeMoreInfo'
  ], function (React, SFUCopyrightComplianceNoticeMoreInfo) {

  var SFUCopyrightComplianceNotice = React.createClass({
    getDefaultProps() {
      return {
        show_more: false
      };
    },

    getInitialState() {
      return {
        show_more: this.props.show_more
      };
    },

    handleClick() {
      this.setState({ show_more: !this.state.show_more });
    },

    showMoreMaybe() {
      if (this.state.show_more) {
        return <SFUCopyrightComplianceNoticeMoreInfo />
      } else {
        return (
          <p>
            <button onClick={this.handleClick} className="Button Button--mini">Read More&hellip;</button>
          </p>
        )
      }
    },

    render() {
      return (
        <div>
          <p className={this.props.className}>
            I confirm that the use of copyright protected materials in this course
            complies with Canada's Copyright Act and SFU Policy R30.04 - Copyright
            Compliance and Administration.
          </p>
          {this.showMoreMaybe()}
        </div>
      )
    }
  });

  return SFUCopyrightComplianceNotice;

});