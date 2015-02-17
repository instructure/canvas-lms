/** @jsx React.DOM */

define([
  'react'
], function(React) {

  var SFUGoogleDocsStudentPrivacyNotice = React.createClass({
    render() {
      var alertClassName = `SFUPrivacyNotice ${this.props.alertStyle}`
      return (
        <div className={alertClassName} >
          <h1><i className="icon-warning"></i> Is your Google Docs usage privacy compliant?</h1>
          <p>
            Google Docs is a collaboration tool that allows you to create and share documents with other people. <strong>Before using Google Docs</strong>, carefully review the <a href="http://www.sfu.ca/canvasprivacynotice" target="_blank">Canvas Privacy Protection Notice</a> to <strong>understand the personal privacy implications</strong> for yourself <strong>as well as your responsibilities to other persons</strong> and their information.
          </p>
          <p>
            By authorizing your SFU Canvas account to use Google Docs, you acknowledge that you read and are agreeing to the Privacy Protection Notice.
          </p>
        </div>
      );
    }
  });

  var SFUPrivacyNotice = React.createClass({
    propTypes: {
      usage: React.PropTypes.string.isRequired
    },

    getString (string) {
      const GOOGLE_DOCS = 'Google Docs'
      var strings = {
        h1_usage: {
          external_apps: 'app',
          google_docs: `${GOOGLE_DOCS} usage`
        },
        before_using: {
          external_apps: 'any app',
          google_docs: GOOGLE_DOCS
        },
        tlc_will_help: {
          external_apps: 'complete an app privacy assessment and, if needed, advise you how to obtain students’ consent in the manner prescribed by law',
          google_docs: 'with the student consent procedure that you must use'
        },
        by_using_in_course: {
          external_apps: 'using apps in your course and the App Centre in Canvas',
          google_docs: `authorizing your SFU Canvas account to use ${GOOGLE_DOCS} in your course`
        }
      };
      // TODO this should throw a runtime warning instead of returning an empty string
      return (strings.hasOwnProperty(string) && strings[string].hasOwnProperty(this.props.usage)) ? strings[string][this.props.usage] : '';
    },

    render () {
      var alertClassName = `SFUPrivacyNotice ${this.props.alertStyle}`

      if (this.props.usage === 'google_docs_student') {
        return <SFUGoogleDocsStudentPrivacyNotice alertStyle={this.props.alertStyle} />
      } else {
        return (
          <div className={alertClassName}>
            <h1><i className="icon-warning"></i> Is your {this.getString('h1_usage')} privacy compliant?</h1>
            <p>
              There are <strong> personal legal consequences</strong> if you use an app that discloses and stores students&rsquo; personal information elsewhere inside or outside Canada without their consent. Unauthorized disclosure is a privacy protection offense under BC law. Employees and SFU are liable to investigation and possible fines.
            </p>
            <p>
              <strong>Before using {this.getString('before_using')}</strong>, carefully review the complete <a href="http://www.sfu.ca/canvasprivacynotice" target="_blank"> Canvas Privacy Protection Notice</a> to <strong>understand your legal responsibilities</strong> and please contact <a href="mailto:learntech@sfu.ca">learntech@sfu.ca</a>. The Learning Technology Specialists in the Teaching and Learning Centre will help you {this.getString('tlc_will_help')}.
            </p>
            <p>
              By {this.getString('by_using_in_course')}, you acknowledge that you have <strong>read the <a href="http://www.sfu.ca/canvasprivacynotice" target="_blank">Canvas Privacy Protection Notice</a></strong> and will <strong>follow the described protection of privacy requirements and procedure</strong>.
            </p>
          </div>
        );
      }
    }
  });



  return SFUPrivacyNotice;
});

