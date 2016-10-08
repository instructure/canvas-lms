define([
  'react',
], ({ PropTypes }) => {
  const { shape, string } = PropTypes

  return shape({
    id: string.isRequired,
    label: string.isRequired,
  })
})
