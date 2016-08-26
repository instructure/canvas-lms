 define([
  'react',
  './BaseIcon'
], function(React, BaseIcon) {
  var IconFolder = React.createClass({
    render () {
      const content = `
        <path d="M180 45H97.5L81 23c-3.8-5-9.7-8-16-8H20C9 15 0 24 0 35v130c0 11 9 20 20 20h160c11 0 20-9
          20-20V65C200 54 191 45 180 45zM20 165V35h45l16.5 22c3.8 5 9.7 8 16 8H180l0 100H20z"/>
      `;
      return (
        <BaseIcon
          {...this.props}
          name="IconFolder"
          viewBox="0 0 200 200" content={content} />
      )
    }
  });

  return IconFolder;
});
