# this class coordinates multiple slick grids to behave as if they are
# different views on the same data -- if one scrolls vertically, the others
# scroll vertically as well.
define [
  'jquery'
  'vendor/slickgrid'
  'jquery.instructure_jquery_patches'
  'vendor/jquery.scrollTo'
], ($, Slick) ->

  MultiGrid = class MultiGrid
    constructor: (data, default_options, grids, parent_grid) ->
      @data = data
      @parent_grid_idx = parent_grid
      @grids = for grid_opts in grids
        options = $.extend({}, default_options, grid_opts.options)
        grid = new Slick.Grid(grid_opts.selector, @data, grid_opts.columns, options)
        grid.multiview_grid_opts = grid_opts
        grid_opts.$viewport = $(grid_opts.selector).find('.slick-viewport')
        if grid_opts == grids[@parent_grid_idx]
          @parent_grid = grid
        else
          grid_opts.$viewport.css('overflow-y', 'hidden')
        grid
      @parent_grid.onViewportChanged.subscribe =>
        for grid in @grids when grid != @parent_grid
          grid.multiview_grid_opts.$viewport[0].scrollTop =
            @parent_grid.multiview_grid_opts.$viewport[0].scrollTop
          grid.multiview_grid_opts.$viewport.trigger('scroll.slickgrid')

  # simple delegation
  for method in ['render', 'invalidateRow', 'updateRowCount', 'autosizeColumns', 'resizeCanvas', 'invalidate']
    do (method) ->
      MultiGrid::[method] = () ->
        grid[method].apply(grid, arguments) for grid in @grids

  MultiGrid

