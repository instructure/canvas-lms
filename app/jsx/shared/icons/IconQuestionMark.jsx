 define([
  'react',
  './BaseIcon'
], function(React, BaseIcon) {
  var IconQuestionMark = React.createClass({
    render () {
      const content = `
        <path d="M100 200C44.9 200 0 155.1 0 100 0 44.9 44.9 0 100 0s100 44.9 100 100C200 155.1 155.1 200
          100 200zM100 20c-44.1 0-80 35.9-80 80s35.9 80 80 80 80-35.9 80-80S144.1 20 100 20z"/>
        <path d="M110 130H90v-30h10c11 0 20-9 20-20 0-11-9-20-20-20s-20 9-20 20H60c0-22.1 17.9-40 40-40s40
          17.9 40 40c0 18.6-12.8 34.3-30 38.7V130z"/>
        <circle cx="100" cy="150" r="12.5"/>
      `;
      return (
        <BaseIcon
          {...this.props}
          name="IconQuestionMark"
          viewBox="0 0 200 200" content={content} />
      )
    }
  });

  return IconQuestionMark;
});
