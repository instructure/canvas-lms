define([
  'react'
], function (React) {
  return {
    link: React.PropTypes.shape({
      text: React.PropTypes.string.isRequired,
      url: React.PropTypes.string.isRequired,
      subtext: React.PropTypes.string,
      available_to: React.PropTypes.array,
      type: React.PropTypes.oneOf(['default', 'custom']),
      id: React.PropTypes.string,

      index: React.PropTypes.number,
      state: React.PropTypes.oneOf(['new', 'active', 'deleted']),
      action: React.PropTypes.oneOf(['edit', 'focus']),
      is_disabled: React.PropTypes.bool
    })
  }
});
