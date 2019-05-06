import React from 'react'
import ReactDOM from 'react-dom'
import TokenInput, {Option as ComboboxOption} from 'react-tokeninput'

class StudentExemptions extends React.Component {
    constructor(props) {
        super(props)
        this.state = this.lmsData(props)
        this.handleInput = this.handleInput.bind(this)
        this.renderComboboxOptions = this.renderComboboxOptions.bind(this)
        this.handleTokenAdd = this.handleTokenAdd.bind(this)
        this.handleTokenRemove = this.handleTokenRemove.bind(this)
        this.filterTags = this.filterTags.bind(this)
    }

    lmsData(props){
      return {
        input: '',
        loading: false,
        options: [],
        students: props['students'],
        exemptions: props['exemptions']
      }
    }

    // Use this to set test state if you aren't connecting to
    // Data from the server
    fixture(){
      return {
        input: '',
        loading: false,
        options: [],
        students: 
          [
            { name: 'chris', id: 1},
            { name: 'conrad', id: 4},
            { name: 'joe', id: 2},
            { name: 'pete', id: 3}
          ],
        exemptions: 
          [
            { name: 'pete', id: 3 }
          ]
      }
    }

    names(){
      return this.state.students.map(student => {
        return student.name
      }).filter(name =>
        !this.state.exemptions.find(stu => stu.name === name)
      )
    }

    handleInput(userInput) {
      this.setState({
        input: userInput,
        loading: true,
        options: []
      })
      setTimeout(() => {
        this.filterTags(this.state.input)
        this.setState({
          loading: false
        })
      }, 500)
    }

    findStudentName(userInput){
      var filter = new RegExp('^'+userInput, 'i');
      return this.names().find((name) => 
        filter.test(name)
      )
    }

    filterTags(userInput) {
      if (userInput === '') return this.setState({options: []});
      this.setState({
        options: this.names().filter((name) => 
          new RegExp('^'+userInput, 'i').test(name)
        )
      })
    }

    findStudent(studentName){
      return this.state.students.find((element) => element.name === studentName)
    }

    handleTokenAdd(token) {
      var studentName = this.findStudentName(token);
      if(!studentName) return
      var student = this.findStudent(studentName)
      this.setState({exemptions: [...this.state.exemptions, student]})
    }

    handleTokenRemove(token) {
      this.setState({exemptions: this.state.exemptions.filter((student) =>  
        student.id !== token.id
      )});
    }

    renderComboboxOptions(){
      if (this.state.options.length) {
        return this.state.options.map((name) => {
          var student = this.findStudent(name)
          return (
            <ComboboxOption
              key={student.id}
              value={student.name}
              isFocusable={student.name.length > 1}
            >{student.name}</ComboboxOption>
          )
        })
      } else if (this.state.input && !this.state.loading) {
        return (
          [
            <ComboboxOption key="No results found" value="No results found">
              No results found
            </ComboboxOption>
          ]
        )
      } else {
        return []
      }
    }

    rowStyle() {
      return({
        'border': '1px solid #ccc',
        'borderRadius': '5px',
        'borderBottomLeftRadius': 0,
        'borderBottomRightRadius': 0,
        'borderBottom': 'none'
      })
    };

    containerStyle(){
      return({
        borderBottom: '1px solid #ccc',
        padding: '15px'
      })
    }
    
    render() {
        this.props.syncWithBackbone(this.state.exemptions)
        if(!this.state.exemptions){return <ul></ul>}
        if(!this.state.students){return <ul></ul>}

        return(
          <div style={this.rowStyle()}>
            <div style={this.containerStyle()}>
              <div id="exempt-label" class="ic-Label" title="Exempt these students" aria-label="Exempt these students">
                Exempt these students
              </div>
              <TokenInput
                  menuContent = {this.renderComboboxOptions()}
                  selected    = {this.state.exemptions}
                  onInput     = {this.handleInput}
                  onSelect    = {this.handleTokenAdd}
                  onRemove    = {this.handleTokenRemove}
                  value       = {true}
                  ref         = "TokenInput"
              />
            </div>
          </div>
        )
    }
}

export default StudentExemptions