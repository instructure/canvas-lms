import React from 'react'
import styled from 'styled-components'
import axios from 'axios'
import ObserveeCourseDetails from './ObserveeCourseDetails'

const Card = styled.div`
  border: 1px solid #D7D7D7;
  text-align: center;
  // I'm sorry, future Jessic ):
  min-height: 340px;
  height: 100%;
  width: 100%;
  position: relative;
  overflow-x: hidden;

  .observee-info {
    text-align: center;
    width: 100%;
    padding: 1rem 0;
    border-bottom: 1px solid #d7d7d7;
    
    p {
      color: #006ba6;
      font-size: 14px;
      font-weight: bold;
    }

    img {
      width: 50px;
      height: 50px;
      border-radius: 100%;
      border: 1px solid #d7d7d7;
      overflow: hidden;
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

  render() {
    return (
      <Card>
        <div className="observee-info">
          <img src={this.state.user.avatar_image_url}></img>
          <p>{this.state.user.name}</p>
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
