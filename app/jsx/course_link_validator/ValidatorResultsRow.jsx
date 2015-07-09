define([
  'react',
  'i18n!link_validator'
], function(React, I18n) {
  var ValidatorResultsRow = React.createClass({
    render () {
      var invalid_links = this.props.result.invalid_links;
      var rows = [];

      invalid_links.forEach((link) => {
        rows.push(<li key={link.url + invalid_links.indexOf(link)}>
          {link.url}
        </li>);
      });

      return (
        <div className="result">
          <h4>
            <a href={this.props.result.content_url} target="_blank">
              {this.props.result.name}
            </a>
          </h4>
          <ul>
            {rows}
          </ul>
        </div>
      );
    }
  });

  return ValidatorResultsRow;
});