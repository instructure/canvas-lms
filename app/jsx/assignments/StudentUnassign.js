import React from 'react'
import TokenInput, {Option as ComboboxOption} from 'react-tokeninput'
import StudentExemptions from 'jsx/assignments/StudentExemptions'
import OverrideStudentStore from "jsx/due_dates/OverrideStudentStore";

class StudentUnassignments extends StudentExemptions {
  constructor(props) {
    super(props)
    this.filterTags = this.filterTags.bind(this)
    this.names = this.names.bind(this)
    this.handleTokenAdd = this.handleTokenAdd.bind(this)
    this.handleTokenRemove = this.handleTokenRemove.bind(this)
  }

  componentDidMount() {
    this.setState({
      overrides: OverrideStudentStore.getCurrentOverrides()
    })
  }

  componentWillUpdate() {
    OverrideStudentStore.setCurrentUnassignments(this.state.exemptions)
  }

  filterTags(userInput) {
    this.setState({
      overrides: OverrideStudentStore.getCurrentOverrides()
    })

    if (userInput === '') return this.setState({options: []});
    this.setState({
      options: this.names().filter((name) =>
        new RegExp('^'+userInput, 'i').test(name)
      )
    })
  }

  lmsData(props){
    return {
      input: '',
      loading: false,
      options: [],
      students: props['students'],
      exemptions: props['exemptions'],
      overrides: []
    }
  }

  names(){
    return this.state.students.map(student => {
      return student.name
    }).filter(name =>
      this.filterArray().find(stu => stu.name === name)
    )
  }

  filterArray() {
    return this.state.students.filter(student => !this.state.overrides.includes(student.id))
  }

  filterOverrides() {
    return this.filterArray().map(students => students.name)
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

  renderComboboxOptions() {
    if (this.filterOverrides().length) {
      return this.filterOverrides().map((name) => {
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
}

export default StudentUnassignments
