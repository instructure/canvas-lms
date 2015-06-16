/** @jsx React.DOM */

define([
  'underscore',
  'i18n!external_tools',
  'react',
  'react-router'
], function (_, I18n, React, {Link}) {

  return React.createClass({
    displayName: 'Header',

    render() {

      var paragraph = I18n.t(
        '*See some LTI tools* that work great with Canvas. You can also check out the **Canvas Community topics about LTI tools**.',
        { wrappers: [
          '<a href="https://www.eduappcenter.com/">$1</a>',
          '<a href="http://help.instructure.com/entries/20878626-lti-tools-and-examples">$1</a>'
        ]}
      );

      return (
        <div className="Header">
          <h2 className="page-header" ref="pageHeader">
            <span className="externalApps_label_text">{I18n.t('External Apps')}</span>
            <div className="externalApps_buttons_container">
              {this.props.children}
            </div>
          </h2>

          <div className="well well-sm">
            <p>{I18n.t('Apps are an easy way to add new features to Canvas. They can be added to individual courses, or to all courses in an account. Once configured, you can link to them through course modules and create assignments for assessment tools.')}</p>
            <p dangerouslySetInnerHTML={{ __html: paragraph }}></p>
          </div>
        </div>
      )
    }
  });
});
