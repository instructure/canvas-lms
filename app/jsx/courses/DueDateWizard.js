import React from 'react';
import moment from 'moment';
import axios from 'axios';
import { flashError } from 'jquery';
import { flashMessage } from 'jquery';

class DueDateWizard extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      course: {},
      distributingDates: false,
      currentlyImporting: false
    }
  }

  componentWillMount() {
    this.setState({
      course: ENV.course,
      distributingDates: ENV.dates_distributing,
      currentlyImporting: ENV.currently_importing
    }, () => {
      console.log(this.state.course)
      if (this.state.distributingDates) { this.getProgress() }
    });
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

    if (!this.courseHasDates()) {
      component = this.noDateWarning();
    } else if (this.state.currentlyImporting) {
      component = this.currentImportWarning();
    } else {
      component = this.datePusher();
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
          Missing start or end date. Due dates cannot be distributed.
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

  currentImportWarning() {
    return (
      <div>
        <h2 className="warning">
          An import is currently running. Due dates cannot be distributed.
        </h2>
        <h4>
          <span>
            <a href={`/courses/${this.state.course.id}/content_migrations`}>Go to Imports</a>
            &nbsp;to view the status of current course imports.
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
        this.getProgress();
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
        this.getProgress();
      });
    }
  }
  
  renderButtons() {
    if (this.courseHasDates() && !this.state.currentlyImporting) {
      return (
        <div>
          <button className={`sm-btn-primary due-date-btn ${this.state.distributingDates ? "disabled" : ""}`} onClick={this.distributeDueDates.bind(this)}>Distribute Due Dates</button>
          <button className={`sm-btn-secondary due-date-btn ${this.state.distributingDates ? "disabled" : ""}`} onClick={this.clearDueDates.bind(this)}>Clear Due Dates</button>
          {this.state.distributingDates ? this.renderWarningIfDistributing() : ""}
        </div>
      )
    }
  }

  renderWarningIfDistributing() {
    return (
      <div className="distributing-warning-section">
        <div>
          <small className="distributing-warning">Due Dates are currently being distributed</small>
        </div>
        <div className="progress">
          <span className="value">
            <span style={{width: `${this.state.distributionProgress}%`}}></span>
          </span>
        </div>
      </div>
    )
  }

  getProgress() {
    let progressCheck = setInterval(() => {
      axios.get(`/courses/${this.state.course.id}/progress/show_distribution_progress`).then((response) => {
        this.setState({
          distributingDates: response.data.distributing,
          distributionProgress: response.data.completion
        }, () => {
          if (!this.state.distributingDates) { clearInterval(progressCheck) }
        });
      })
    }, 1000);
  }

  render() {
    return (
      <div className="due-date-wizard-card">
        <h3 className="title">Distribute Dates for Course '{this.state.course.name}'</h3>
        {this.innerCard()}
        {this.courseHasDates() ? this.renderButtons() : ""}
      </div>
    )
  }
}

export default DueDateWizard;