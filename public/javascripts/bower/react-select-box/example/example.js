var React = require('react')
var SelectBox = React.createFactory(require('../lib/select-box'))

var div = React.createElement.bind(null,'div')
var option = React.createElement.bind(null,'option')
var h1 = React.createElement.bind(null,'h1')

var Example = React.createFactory(React.createClass({displayName: 'Example',
  getInitialState: function () {
    return {
      color: null,
      colors: []
    }
  },
  handleChange: function (color) {
    this.setState({ color: color })
  },
  handleMultiChange: function (colors) {
    this.setState({ colors: colors })
  },
  render: function () {
    return(
      div({className: "example"},
        h1(null, "Select Box Example"),
        SelectBox(
          {
            label: "Favorite Color",
            className: 'my-example-select-box',
            onChange: this.handleChange,
            value: this.state.color
          },
          option({key: 'red', value: 'red'}, 'Red'),
          option({value: 'green'}, 'Green'),
          option({value: 'blue'}, 'Blue'),
          option({value: 'black'}, 'Black'),
          option({value: 'orange'}, 'Orange'),
          option({value: 'greenish'}, 'Light greenish with a little bit of yellow')
        ),
        h1(null, "Multi Select Example"),
        SelectBox(
          {
            label: "Favorite Colors",
            onChange: this.handleMultiChange,
            value: this.state.colors,
            multiple: true
          },
          option({value: 'red'}, 'Red'),
          option({value: 'green'}, 'Green'),
          option({value: 'blue'}, 'Blue'),
          option({value: 'black'}, 'Black'),
          option({value: 'orange'}, 'Orange'),
          option({value: 'greenish'}, 'Light greenish with a little bit of yellow')
        )
      )
    )
  }
}))

React.render(Example(null), document.body)
