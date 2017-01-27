import { PropTypes } from 'react'
import assignmentShape from './assignment-shape'

const { shape, number, arrayOf } = PropTypes

export default shape({
  setId: number.isRequired,
  assignments: arrayOf(assignmentShape).isRequired,
})
