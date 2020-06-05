import React from 'react'
import styled from 'styled-components'
import ObserveeCard from './ObserveeCard'
import ObserverZeroState from './ObserverZeroState'
import axios from 'axios'

const CardWrapper = styled.div`
  flex-basis: 25%;
  width: 100%;
  padding: 0.75rem;
  box-sizing: border-box;
  position: relative;

  @media (max-width: 1200px) {
    flex-basis: 33.33%;
  }

  @media(max-width: 992px) {
    flex-basis: 50%;
  }

  @media(max-width: 767px) {
    flex-basis: 100%;
  }
`

const DashboardContainer = styled.div`
  .dashboard-title {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1rem;

    .ic-Form-control {
      margin-bottom: 0;
    }

    .ic-Super-toggle--ui-switch .ic-Super-toggle__switch {
      margin: 0 10px;
    }

    .ic-Super-toggle--ui-switch .ic-Super-toggle__input:checked ~ .ic-Super-toggle__container {
      .ic-Super-toggle__option--RIGHT, .ic-Super-toggle__option--LEFT {
        transform: none;
      }
    }
    
    .ic-Super-toggle__option--RIGHT, .ic-Super-toggle__option--LEFT {
      font-size: 12px;
      transform: none;
    }
  }
`

const Dashboard = styled.div`
  display: flex;
  flex-flow: row wrap;
  justify-content: flex-start;
  margin: 0 -0.75rem;
`

class ObserverDashboard extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      observees: this.props.observees.models,
      showProgressGrades: ENV.show_progress_grades
    }
  }
  
  static defaultProps = {
    observees: [],
  };

  updateProgressGradeSetting() {
    let self = this
    let value = self.refs.showProgressGrades.checked

    axios.post(
      `api/v1/users/${ENV.current_user.id}/toggle_progress_grade`,
      {show_progress_grades: value}
    ).then((response) => {
      self.setState({showProgressGrades: response.data.show_progress_grades})
    })
  }

  renderObserveeCards() {
    if (!this.state.observees.length) { return (<ObserverZeroState></ObserverZeroState>) }
    return this.state.observees.map((student, i) => { 
      return (<CardWrapper><ObserveeCard key={i} student={student} showProgressGrades={this.state.showProgressGrades} /></CardWrapper>) 
    })
  }

  render() {
    return (
      <DashboardContainer>
        <div className="dashboard-title">
          <h2>Observed Students</h2>
          <div className="ic-Form-control">
            <label className="ic-Super-toggle--ui-switch" htmlFor="super-toggle-grades">
              <span className="screenreader-only">Grades Toggle</span>
              <input type="checkbox" id="super-toggle-grades" className="ic-Super-toggle__input" checked={this.state.showProgressGrades}
              ref="showProgressGrades" onChange={this.updateProgressGradeSetting.bind(this)} />
              <div className="ic-Super-toggle__container" aria-hidden="true" data-checked="Show Current Grade" data-unchecked="Show Final Grade">
                <div className="ic-Super-toggle__option--LEFT">
                  <span>Final Grade</span>
                </div>
                <div className="ic-Super-toggle__switch"></div>
                <div className="ic-Super-toggle__option--RIGHT">
                  <span>Current Grade</span>
                </div>
              </div>
            </label>
          </div>
        </div>
        <Dashboard>
          {this.renderObserveeCards()}
        </Dashboard>
      </DashboardContainer>
    )
  }
}

export default ObserverDashboard
