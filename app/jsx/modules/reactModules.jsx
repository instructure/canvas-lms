define([
  'react',
  'react-dom'
], (React, ReactDOM) => {
  return {
    render: (domElt) => {
      ReactDOM.render(<p>React Modules</p>, domElt)
    }
  };
});
