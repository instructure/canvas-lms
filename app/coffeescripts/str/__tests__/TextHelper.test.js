import {truncateText} from '../TextHelper'

test('truncateText', () => {
  expect(truncateText('this is longer than 30 characters')).toBe('this is longer than 30...')
})
