var React = require('react')
var TokenInput = require('../index')
var ComboboxOption = require('../index').Option

var without = require('lodash-node/modern/arrays/without')
var uniq = require('lodash-node/modern/arrays/uniq')
var names = require('./names')

var App = React.createClass({
  getInitialState: function() {
    return {
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
    // this.setState({selectedStateId: null});
    this.filterTags(userInput);
  },

  filterTags: function(userInput) {
    if (userInput === '')
      return this.setState({options: []});
    var filter = new RegExp('^'+userInput, 'i');
    this.setState({options: names.filter(function(state) {
      return filter.test(state.name) || filter.test(state.id);
    })});
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
    var selectedFlavors = this.state.selected.map(function(tag) {
      return <li key={tag.id}>{tag.name}</li>
    })


    var options = this.state.options.length ?
      this.renderComboboxOptions() : [];

    return (
      <div>
        <h1>React TokenInput Example</h1>

        <TokenInput
            onChange={this.handleChange}
            onInput={this.handleInput}
            onSelect={this.handleSelect}
            onRemove={this.handleRemove}
            selected={this.state.selected}
            menuContent={options} />

        <h2>Selected</h2>
        <ul>
          {selectedFlavors}
        </ul>
      </div>
    );
  }
})

React.render(<App/>, document.getElementById('application'))
