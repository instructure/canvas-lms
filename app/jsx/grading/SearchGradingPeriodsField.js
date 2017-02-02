import React from 'react'
import _ from 'underscore'
import I18n from 'i18n!grading_periods'
import SearchHelpers from 'jsx/shared/helpers/searchHelpers'

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

export default SearchGradingPeriodsField
