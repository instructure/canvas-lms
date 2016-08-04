define([
  'react',
  'underscore',
  'i18n!grading_periods',
  'jsx/shared/helpers/searchHelpers'
], function(React, _, I18n, SearchHelpers) {

  let SearchGradingPeriodsField = React.createClass({
    propTypes: {
      changeSearchText: React.PropTypes.func.isRequired
    },

    onChange(event) {
      let trimmedText = event.target.value.trim();
      this.search(trimmedText);
    },

    search: _.debounce(function(trimmedText) {
      this.props.changeSearchText(trimmedText);
    }, 200),

    render() {
      return (
        <div className="GradingPeriodSearchField ic-Form-control">
          <input type="text"
                 ref="input"
                 className="ic-Input"
                 placeholder={I18n.t("Search grading periods...")}
                 onChange={this.onChange}/>
        </div>
      );
    }
  });

  return SearchGradingPeriodsField;
});
