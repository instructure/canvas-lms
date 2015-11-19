var React = require('react')
var ReactDOM = require('react-dom')
var TokenInput = require('../index')
var ComboboxOption = require('../index').Option

var without = require('lodash-node/modern/arrays/without')
var uniq = require('lodash-node/modern/arrays/uniq')
var names = require('./names')

var App = React.createClass({
  getInitialState: function() {
    return {
      input: '',
      loading: false,
      selected: [],
      options: names
    };
  },

  handleChange: function(value) {
    this.setState({
      selected: value
    })
  },

  handleRemove: function(value) {
    var selectedOptions = uniq(without(this.state.selected,value))
    this.handleChange(selectedOptions)
  },

  handleSelect: function(value, combobox) {
    if(typeof value === 'string') {
      value = {id: value, name: value};
    }

    var selected = uniq(this.state.selected.concat([value]))
    this.setState({
      selected: selected,
      selectedToken: null
    })

    this.handleChange(selected)
  },

  handleInput: function(userInput) {
    this.setState({
      input: userInput,
      loading: true,
      options: []
    })
    setTimeout(function () {
      this.filterTags(this.state.input)
      this.setState({
        loading: false
      })
    }.bind(this), 500)
  },

  filterTags: function(userInput) {
    if (userInput === '')
      return this.setState({options: []});
    var filter = new RegExp('^'+userInput, 'i');
    var filteredNames = names.filter(function(state) {
      return filter.test(state.name); // || filter.test(state.id);
    }).filter(function(state) {
      return this.state.selected
        .map(function(value) { return value.name })
        .indexOf(state.name) === -1
    }.bind(this))
    this.setState({
      options: filteredNames
    });
  },

  renderComboboxOptions: function() {
    return this.state.options.map(function(name) {
      return (
        <ComboboxOption
          key={name.id}
          value={name}
        >{name.name}</ComboboxOption>
      );
    });
  },

  render: function() {
    var selectedNames = this.state.selected.map(function(tag) {
      return <li key={tag.id}>{tag.name}</li>
    })

    var options = this.state.options.length ?
      this.renderComboboxOptions() : [];

    const loadingComponent = (
      <img src='spinner.gif' />
    )

    return (
      <div>
        <h1>React TokenInput Example</h1>

        <TokenInput
            isLoading={this.state.loading}
            loadingComponent={loadingComponent}
            menuContent={options}
            onChange={this.handleChange}
            onInput={this.handleInput}
            onSelect={this.handleSelect}
            onRemove={this.handleRemove}
            selected={this.state.selected}
            placeholder='Enter tokens here'
          />

        <h2>Selected</h2>
        <ul>
          {selectedNames}
        </ul>
      </div>
    );
  }
})

ReactDOM.render(<App/>, document.getElementById('application'))
