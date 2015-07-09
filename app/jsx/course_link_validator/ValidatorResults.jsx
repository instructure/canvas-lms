define([
  'react',
  'i18n!link_validator',
  './ValidatorResultsRow'
], function(React, I18n, ValidatorResultsRow) {

  var ValidatorResults = React.createClass({
    getDisplayMessage (number) {
      return I18n.t({one: "Found 1 broken link", other: "Found %{count} broken links"}, {count: number});
    },

    render () {
      var allResults = [],
        alertMessage,
        numberofBrokenLinks = 0,
        errorMessage = I18n.t("An error occured. Please try again."),
        noBrokenLinksMessage = I18n.t("No broken links found");

      if (this.props.error) {
        alertMessage = <div className='alert alert-error'>{errorMessage}</div>;
      } else if (!this.props.displayResults) {
        return null;
      } else if (this.props.results.length === 0) {
        alertMessage = <div className='alert alert-success'>{noBrokenLinksMessage}</div>;
      } else {
        this.props.results.forEach((result) => {
          allResults.push(<ValidatorResultsRow result={result} />);
          numberofBrokenLinks += result.invalid_links.length;
        });

        alertMessage = <div className='alert alert-info'>{this.getDisplayMessage(numberofBrokenLinks)}</div>;
      }

      return (
        <div id="all-results">
          {alertMessage}
          {allResults}
        </div>
      );
    }
  });
  return ValidatorResults;
});