/** React.DOM */

// first person to actually save a .jsx file, please delete this file.

define(['react'], function(React) {

  var Thing = React.createClass({
    render () {
      return (
        <div>Look ma! no "function"</div>
      );
    }
  });

  React.renderComponent(<Thing/>, document.getElementById('content'));

});
