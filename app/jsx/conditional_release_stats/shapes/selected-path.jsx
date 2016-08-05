define([
  'react',
], ({ PropTypes }) => {
  const { shape, number } = PropTypes

  return shape({
    range: number,
    student: number,
  })
})
