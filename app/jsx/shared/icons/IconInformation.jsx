 define([
  'react',
  './BaseIcon'
], function(React, BaseIcon) {
  var IconInformation = React.createClass({
    render () {
      const content = `
        <path d="M100 200C44.9 200 0 155.1 0 100 0 44.9 44.9 0 100 0s100 44.9 100 100C200 155.1 155.1 200 100
          200zM100 20c-44.1 0-80 35.9-80 80s35.9 80 80 80 80-35.9 80-80S144.1 20 100 20z"/>
          <path d="M110 130V90c0-5.5-4.5-10-10-10H80v20h10v30H70v20h60v-20H110z"/>
          <circle cx="100" cy="60" r="12.5"/>
      `;
      return (
        <BaseIcon
          {...this.props}
          name="IconInformation"
          viewBox="0 0 200 200" content={content} />
      )
    }
  });

  return IconInformation;
});
