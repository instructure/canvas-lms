define([
  'react',
  'underscore'
], (React, _) => {

  const styles = {
    list: {
      backgroundColor: "#eeeeee"
    },
    label: {
      backgroundColor: "white",
      borderRadius: "3px"
    }
  };

  class DisabledTokenInput extends React.Component {
    static propTypes = {
      tokens: React.PropTypes.arrayOf(React.PropTypes.string)
    }

    renderTokens() {
      return _.map(this.props.tokens, function(token, index) {
        return (
          <li key={`token-${index}`} className="ic-token inline-flex">
            <span className="ic-token-label" style={styles.label}>{token}</span>
          </li>
        );
      });
    }

    render() {
      return(
        <ul tabIndex="0" aria-labelledby="assign-to-label" className="ic-tokens flex" style={styles.list}>
          {this.renderTokens()}
        </ul>
      );
    }
  }

  return DisabledTokenInput;
});
