import $ from 'jquery'
import I18n from 'i18n!course_list'

function success (target) {
  const favorited_tooltip = I18n.t('favorited_tooltip', 'Click to remove from the courses menu.')
  const nonfavorite_tooltip = I18n.t('nonfavorited_tooltip', 'Click to add to the courses menu.')
  const notfavoritable_tooltip = I18n.t('This course cannot be added to the courses menu at this time.')

  if (target.hasClass('course-list-favorite-course')) {
    target.removeClass('course-list-favorite-course')
    if (target.hasClass('course-list-not-favoritable')) {
      target.removeAttr('data-favorite-url')// Remove the data so it won't be used later.
      target.off('click keyclick')
      target.attr('title', notfavoritable_tooltip)
      target.data('ui-tooltip-title', notfavoritable_tooltip)
      target.children('.screenreader-only').text(notfavoritable_tooltip)
      return
    }

    target.attr('title', nonfavorite_tooltip)
      // The tooltip wouldn't update with just changing the title so
      // it's forced to do so here. Same below in the else case.
    target.data('ui-tooltip-title', nonfavorite_tooltip)
    target.children('.screenreader-only').text(nonfavorite_tooltip)
    target.children('.course-list-favorite-icon').toggleClass('icon-star icon-star-light')
  }
  target.addClass('course-list-favorite-course')
  target.attr('title', favorited_tooltip)
  target.data('ui-tooltip-title', favorited_tooltip)
  target.children('.screenreader-only').text(favorited_tooltip)
  target.children('.course-list-favorite-icon').toggleClass('icon-star icon-star-light')
}

$('[data-favorite-url]').on('click keyclick', function (event) {
  event.preventDefault()
  const url = $(this).data('favoriteUrl')
  const target = $(event.currentTarget)
  if (target.hasClass('course-list-favorite-course')) {
    $.ajaxJSON(url, 'DELETE', {}, success(target), null)
  } else {
    $.ajaxJSON(url, 'POST', {}, success(target), null)
  }
})

