/** @jsx React.DOM */

define([
  'i18n!student_groups',
  'old_unsupported_dont_use_react'
], (I18n, React) => {
  var Filter = React.createClass({
    render() {
      return (
        <div className="form-inline clearfix content-box">
          <input id="search_field" placeholder={I18n.t('Search Groups or People')} type="search" onChange={this.props.onChange} 
            aria-label={I18n.t('As you type in this field, the list of groups will be automatically filtered to only include those whose names match your input.')} />
        </div>);
    }
  });

  return Filter;
});
