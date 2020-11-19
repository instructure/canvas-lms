import React from 'react';
import styled from 'styled-components';
import moment from 'moment';
import axios from 'axios';
import { flashError } from 'jquery';
import { flashMessage } from 'jquery';

const Card = styled.div`
  border: 1px solid #D7D7D7;
  border-radius: 4px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.3);
  text-align: center;
  height: 100%;
  width: 100%;
  max-width: 1000px;
  margin: 0 auto;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-direction: column;

  .title, .section {
    text-align: center;
  }

  .course-date-fields {
    display: flex;
  }

  .course-date-row {
    display: flex;
    flex-direction: column;
    padding: 1rem;
  }

  .due-date-btn {
    margin: .5rem .25rem;
  }

  .course-date-title {
    font-weight: 600;
  }

  .warning {
    color: red;
  }

  .disabled {
		opacity: 0.5;
    pointer-events: none;
  }
  
  .distributing-warning {
    font-weight: 600;
  }
`

class DueDateWizard extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      course: {},
      distributingDates: false
    }
  }

  componentDidMount() {
    this.setState({
      course: ENV.course,
      distributingDates: ENV.dates_distributing
    }, () => {console.log(this.state.course)});
  }

  setStateToDistributinng() {
    this.setState({distributingDates: true})
  }

  formatDateString(dateStr) {
    let date = dateStr === "start" ? this.state.course.start_at : this.state.course.conclude_at;
    return moment(date).format("MM-DD-YY");
  }

  courseHasDates() {
    let course = this.state.course;
    return course.start_at && course.conclude_at;
  }

  innerCard() {
    let component;

    if (this.courseHasDates()) {
      component = this.datePusher();
    } else {
      component = this.noDateWarning();
    }

    return (
      <section className="section">
        {component}
      </section>
    );
  }

  noDateWarning() {
    return (
      <div>
        <h2 className="warning">
          Due dates cannot be distributed.
        </h2>
        <h4>
          <span>
            <a href={`/courses/${this.state.course.id}/settings`}>Go to Course Settings</a>
            &nbsp;to add start and end dates in order to use this tool.
          </span>
        </h4>
      </div>
    );
  }

  datePusher() {
    return (
      <div>
        <div className="course-date-fields">
          <div className="course-date-row">
            <span className="course-date-title">
              Course Start Date:
            </span>
            <span>
              {this.formatDateString('start')}
            </span>
          </div>

          <div className="course-date-row">
            <span className="course-date-title">
              Course End Date:
            </span>
            <span>
              {this.formatDateString('end')}
            </span>
          </div>
        </div>
      </div>
    );
  }

  confirmDistribute() {
    return confirm(`You are about to distribute due dates between ${this.formatDateString('start')} \
      and ${this.formatDateString('end')}. Please confirm you want to complete this action.
    `.replace(/  +/g, ' '));
  }
  
  distributeDueDates() {
    if (this.confirmDistribute()) {
      axios.post(`/courses/${this.state.course.id}/distribute_due_dates`).then(() => {
        flashMessage('Dates are distributing');
        this.setStateToDistributinng();
      });
    }
  }

  confirmClear() {
    return confirm(`You are about to clear all due dates from this course. \
      Course assignments will no longer have due dates or calendar events. \
      Please confirm that you want to complete this action.`.replace(/  +/g, ' '));
  }

  clearDueDates() {
    if (this.confirmClear()) {
      axios.post(`/courses/${this.state.course.id}/clear_due_dates`).then(() => {
        flashMessage("Due dates are clearing");
        this.setStateToDistributinng();
      });
    }
  }
  
  renderButtons() {
    return (
      <div>
        <button className={`sm-btn-primary due-date-btn ${this.state.distributingDates ? "disabled" : ""}`} onClick={this.distributeDueDates.bind(this)}>Distribute Due Dates</button>
        <button className={`sm-btn-secondary due-date-btn ${this.state.distributingDates ? "disabled" : ""}`} onClick={this.clearDueDates.bind(this)}>Clear Due Dates</button>
        {this.state.distributingDates ? this.renderWarningIfDistributing() : ""}
      </div>
    )
  }

  renderWarningIfDistributing() {
    return (
      <div>
        <small className="distributing-warning">Due Dates are currently being distributed.</small>
      </div>
    )
  }

  render() {
    return (
      <Card>
        <h3 className="title">Distribute Dates for Course '{this.state.course.name}'</h3>
        {this.innerCard()}
        {this.courseHasDates() ? this.renderButtons() : ""}
      </Card>
    )
  }
}

export default DueDateWizard;