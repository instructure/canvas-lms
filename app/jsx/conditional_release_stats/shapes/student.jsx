import { PropTypes } from 'react'
const { shape, string, number } = PropTypes

export default shape({
  id: number.isRequired,
  name: string.isRequired,
  avatar_url: string,
})
