import { PropTypes } from 'react'
const { shape, string } = PropTypes

export default shape({
  course_id: string.isRequired,
  trigger_assignment: string.isRequired,
})
