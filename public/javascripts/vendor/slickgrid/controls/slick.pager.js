/*
 * Copyright (c) 2010 Michael Leibman, http://github.com/mleibman/slickgrid
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

;(function($) {
  function SlickGridPager(dataView, grid, $container) {
    let $status

    function init() {
      dataView.onPagingInfoChanged.subscribe((e, pagingInfo) => {
        updatePager(pagingInfo)
      })

      constructPagerUI()
      updatePager(dataView.getPagingInfo())
    }

    function getNavState() {
      const cannotLeaveEditMode = !Slick.GlobalEditorLock.commitCurrentEdit()
      const pagingInfo = dataView.getPagingInfo()
      const lastPage = pagingInfo.totalPages - 1

      return {
        canGotoFirst: !cannotLeaveEditMode && pagingInfo.pageSize != 0 && pagingInfo.pageNum > 0,
        canGotoLast:
          !cannotLeaveEditMode && pagingInfo.pageSize != 0 && pagingInfo.pageNum != lastPage,
        canGotoPrev: !cannotLeaveEditMode && pagingInfo.pageSize != 0 && pagingInfo.pageNum > 0,
        canGotoNext:
          !cannotLeaveEditMode && pagingInfo.pageSize != 0 && pagingInfo.pageNum < lastPage,
        pagingInfo
      }
    }

    function setPageSize(n) {
      dataView.setRefreshHints({
        isFilterUnchanged: true
      })
      dataView.setPagingOptions({pageSize: n})
    }

    function gotoFirst() {
      if (getNavState().canGotoFirst) {
        dataView.setPagingOptions({pageNum: 0})
      }
    }

    function gotoLast() {
      const state = getNavState()
      if (state.canGotoLast) {
        dataView.setPagingOptions({pageNum: state.pagingInfo.totalPages - 1})
      }
    }

    function gotoPrev() {
      const state = getNavState()
      if (state.canGotoPrev) {
        dataView.setPagingOptions({pageNum: state.pagingInfo.pageNum - 1})
      }
    }

    function gotoNext() {
      const state = getNavState()
      if (state.canGotoNext) {
        dataView.setPagingOptions({pageNum: state.pagingInfo.pageNum + 1})
      }
    }

    function constructPagerUI() {
      $container.empty()

      const $nav = $("<span class='slick-pager-nav' />").appendTo($container)
      const $settings = $("<span class='slick-pager-settings' />").appendTo($container)
      $status = $("<span class='slick-pager-status' />").appendTo($container)

      $settings.append(
        "<span class='slick-pager-settings-expanded' style='display:none'>Show: <a data=0>All</a><a data='-1'>Auto</a><a data=25>25</a><a data=50>50</a><a data=100>100</a></span>"
      )

      $settings.find('a[data]').click(e => {
        const pagesize = $(e.target).attr('data')
        if (pagesize != undefined) {
          if (pagesize == -1) {
            const vp = grid.getViewport()
            setPageSize(vp.bottom - vp.top)
          } else {
            setPageSize(parseInt(pagesize))
          }
        }
      })

      const icon_prefix =
        "<span class='ui-state-default ui-corner-all ui-icon-container'><span class='ui-icon "
      const icon_suffix = "' /></span>"

      $(`${icon_prefix}ui-icon-lightbulb${icon_suffix}`)
        .click(() => {
          $('.slick-pager-settings-expanded').toggle()
        })
        .appendTo($settings)

      $(`${icon_prefix}ui-icon-seek-first${icon_suffix}`)
        .click(gotoFirst)
        .appendTo($nav)

      $(`${icon_prefix}ui-icon-seek-prev${icon_suffix}`)
        .click(gotoPrev)
        .appendTo($nav)

      $(`${icon_prefix}ui-icon-seek-next${icon_suffix}`)
        .click(gotoNext)
        .appendTo($nav)

      $(`${icon_prefix}ui-icon-seek-end${icon_suffix}`)
        .click(gotoLast)
        .appendTo($nav)

      $container.find('.ui-icon-container').hover(function() {
        $(this).toggleClass('ui-state-hover')
      })

      $container.children().wrapAll("<div class='slick-pager' />")
    }

    function updatePager(pagingInfo) {
      const state = getNavState()

      $container.find('.slick-pager-nav span').removeClass('ui-state-disabled')
      if (!state.canGotoFirst) {
        $container.find('.ui-icon-seek-first').addClass('ui-state-disabled')
      }
      if (!state.canGotoLast) {
        $container.find('.ui-icon-seek-end').addClass('ui-state-disabled')
      }
      if (!state.canGotoNext) {
        $container.find('.ui-icon-seek-next').addClass('ui-state-disabled')
      }
      if (!state.canGotoPrev) {
        $container.find('.ui-icon-seek-prev').addClass('ui-state-disabled')
      }

      if (pagingInfo.pageSize == 0) {
        $status.text(`Showing all ${pagingInfo.totalRows} rows`)
      } else {
        $status.text(`Showing page ${pagingInfo.pageNum + 1} of ${pagingInfo.totalPages}`)
      }
    }

    init()
  }

  // Slick.Controls.Pager
  $.extend(true, window, {Slick: {Controls: {Pager: SlickGridPager}}})
})(jQuery)
