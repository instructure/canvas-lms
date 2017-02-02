import { PropTypes } from 'react'

const { shape, arrayOf, string, number } = PropTypes

export default shape({
  course_id: number,
  name: string,
  title: string,
  grading_scheme: string,
  grading_type: string.isRequired,
  points_possible: number.isRequired,
  submission_types: arrayOf(string),
})
