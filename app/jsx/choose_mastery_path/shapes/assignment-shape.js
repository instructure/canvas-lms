import { PropTypes } from 'react'
import categoryShape from './category-shape'

const { shape, string, number, instanceOf } = PropTypes

export default shape({
  name: string.isRequired,
  description: string,
  points_possible: number.isRequired,
  due_at: instanceOf(Date),
  category: categoryShape.isRequired,
})
