define([
  'react',
  './assignment-shape',
], ({ PropTypes }, assignmentShape) => {
  const { shape, number, arrayOf } = PropTypes

  return shape({
    setId: number.isRequired,
    assignments: arrayOf(assignmentShape).isRequired,
  })
})
