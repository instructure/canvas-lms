 define([
  'react',
  'i18n!custom_help_link',
  './CustomHelpLinkPropTypes'
], function(React, I18n, CustomHelpLinkPropTypes) {
  const CustomHelpLinkHiddenInputs = React.createClass({
    propTypes: {
      link: CustomHelpLinkPropTypes.link.isRequired
    },
    render () {
      const {
        text,
        url,
        subtext,
        available_to,
        type,
        index,
        state
      } = this.props.link
      const namePrefix = `account[custom_help_links][${index}]`
      return (
        <span>
          <input type="hidden" name={`${namePrefix}[text]`} value={text} />
          <input type="hidden" name={`${namePrefix}[subtext]`} value={subtext} />
          <input type="hidden" name={`${namePrefix}[url]`} value={url} />
          <input type="hidden" name={`${namePrefix}[type]`} value={type} />
          <input type="hidden" name={`${namePrefix}[state]`} value={state} />
          {
            available_to && available_to.map(value =>
              <input type="hidden" key={value} name={`${namePrefix}[available_to][]`} value={value} />
            )
          }
        </span>
      )
    }
  });

  return CustomHelpLinkHiddenInputs;
});
