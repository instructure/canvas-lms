define([
  'react',
], ({ PropTypes }) => {
  const { shape, string } = PropTypes

  return shape({
    course_id: string.isRequired,
    trigger_assignment: string.isRequired,
  })
})
