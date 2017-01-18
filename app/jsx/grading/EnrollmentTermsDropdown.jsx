define([
  'react',
  'underscore',
  'i18n!grading_periods',
], function(React, _, I18n) {

  let EnrollmentTermsDropdown = React.createClass({
    propTypes: {
      terms: React.PropTypes.array.isRequired,
      changeSelectedEnrollmentTerm: React.PropTypes.func.isRequired
    },

    sortedTerms(terms) {
      const dated = _.select(terms, term => term.startAt);
      const datedTermsSortedByStart = _.sortBy(dated, term => term.startAt).reverse();

      const undated = _.select(terms, term => !term.startAt);
      const undatedTermsSortedByCreate = _.sortBy(undated, term => term.createdAt).reverse();
      return datedTermsSortedByStart.concat(undatedTermsSortedByCreate);
    },

    termOptions(terms) {
      const allTermsOption = (<option key={0} value={0}>{I18n.t("All Terms")}</option>);
      let options = _.map(this.sortedTerms(terms), function(term) {
        return (<option key={term.id} value={term.id}>{term.displayName}</option>);
      });

      options.unshift(allTermsOption);
      return options;
    },

    render() {
      return (
        <select
          className="EnrollmentTerms__dropdown ic-Input"
          name="enrollment_term"
          data-view="termSelect"
          aria-label="Enrollment Term"
          ref="termsDropdown"
          onChange={this.props.changeSelectedEnrollmentTerm} >
          {this.termOptions(this.props.terms)}
        </select>
      );
    }
  });

  return EnrollmentTermsDropdown;
});
