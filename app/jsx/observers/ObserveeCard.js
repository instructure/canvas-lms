import React from 'react'
import styled from 'styled-components'
import axios from 'axios'
import ObserveeCourseDetails from './ObserveeCourseDetails'

const Card = styled.div`
  border: 1px solid #D7D7D7;
  border-radius: 4px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.3);
  text-align: center;
  // I'm sorry, future Jessic ):
  min-height: 360px;
  height: 100%;
  width: 100%;
  position: relative;
  overflow-x: hidden;

  .observee-info {
    text-align: center;
    width: 100%;
    padding: 1rem 0;
    border-bottom: 1px solid #d7d7d7;
    
    > p {
      color: #006ba6;
      font-size: 14px;
      font-weight: bold;
    }

    .avatar {
      background-image: url(${props => props.avatar_image});
      width: 50px;
      height: 50px;
      max-width: 50px;
      max-height: 50px;
      margin: 0 auto;

      &.online-now {
        &:after {
          margin-left: 40px;
        }
      }
    }
  }

  .attendance-lockout {
    background-color: #F68F92;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: -1rem;
    padding: 0 1rem;

    > * {
      color: #5F0D13;
    }

    i {
      margin-right: 1rem;
    }

    p {
      display: inline-block;
      font-weight: bold;
    }
  }

  .observee-courses {
    width: 100%;

    > div {
      border-bottom: 1px solid #e4e4e4;

      .course-list-item {
        font-size: 12px;
        box-sizing: border-box;
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin: 0;
        padding: 0.7rem 1rem;
        width: 100%;
        cursor: pointer;
  
        .course-name {
          color: #1e1e1e;
          text-align: left;
          word-break: break-word;
  
          &:hover {
            color: #1e1e1e;
            text-decoration: underline;
          }
        }
  
        .course-score {
          font-weight: bold;
          text-align: right;
          flex-basis: 25%;
        }
      }
  
      &:last-of-type {
        border-bottom: 0;
      }
    }
  }
`

class ObserveeCard extends React.Component {
  constructor(props) {
    super(props);

    this.reset = this.reset.bind(this);

    this.state = {
      user: this.props.student.attributes.user,
      enrollments: this.props.student.attributes.enrollments,
      showDetails: 0,
      courseDetails: {},
      detailClicked: false,
    }
  }

  static defaultProps = {
    student: {},
  };

  // pass a state change from child so we can hide the child on an event inside the child component
  reset() {
    this.setState({showDetails: 0, detailClicked: false})
  }

  getCustomColor(enr) {
    if (this.state.user) {
      let colors = this.state.user.preferences.custom_colors;
      for (const k in colors) {
        if (k.toString() === `course_${enr.course_id}`) {
          return colors[k]
        }
      }
      return "#006ba6";
    } else {
      return "#006ba6";
    }
  }

  formatScore(score) {
    if (score && score.final_score) {
      return score.final_score + '%'
    } else {
      return "--";
    }
  }

  showCourseInfo(enr) {
    axios.get(`api/v1/courses/${enr.course_id}/enrollments/${enr.id}/course_info`).then(response => {
      this.setState({showDetails: enr.id, detailClicked: true, courseDetails: response.data})
    })
  }

  renderCourseDetails(enr, color, score, course_details) {
    return <ObserveeCourseDetails enrollment={enr}
      color={color}
      score={score} 
      course_details={course_details}
      reset_action={this.reset}
      is_showing={this.state.detailClicked}></ObserveeCourseDetails>
  }

  renderAttendanceLockout(status) {
    if (status) {
      return <div className="attendance-lockout"><i className="icon-lock"></i><p>Student locked out of courses</p></div>;
    }
  }

  render() {
    return (
      <Card avatar_image={this.state.user.avatar_image_url}>
        <div className="observee-info">
          <div className={`avatar ${this.state.user.is_online ? 'online-now' : ''}`}></div>
          <p>{this.state.user.name}</p>
          {this.renderAttendanceLockout(this.state.user.locked_out)}
        </div>
        <div className="observee-courses">
            {
              this.state.enrollments.map(enr => {
                return (
                  <div>
                    { this.state.showDetails === enr.id ? this.renderCourseDetails(enr, this.getCustomColor(enr), this.formatScore(enr.score), this.state.courseDetails) : undefined }
                    <p className="course-list-item" onClick={this.showCourseInfo.bind(this, enr)}>
                      <span className="course-name">{enr.course_name}</span>
                      <span className="course-score">{this.formatScore(enr.score)}</span>
                    </p>
                  </div>
                )
              })
            }
        </div>
      </Card>
    )
  }
}

export default ObserveeCard
