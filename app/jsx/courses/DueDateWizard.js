import React from 'react';

class DueDateWizard extends React.Component {
  constructor(props) {
    super(props);
  }
  
  static defaultProps = {
    course: {},
  };

  render() {
    return (
      <h1>YARR HERE BE THY BURIED COMPONENT</h1>
    )
  }
}

export default DueDateWizard;