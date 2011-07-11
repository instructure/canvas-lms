(function() {
  var MultiGrid, method, _fn, _i, _len, _ref;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  this.MultiGrid = MultiGrid = (function() {
    function MultiGrid(data, default_options, grids, parent_grid) {
      var grid, grid_opts, options;
      this.data = data;
      this.parent_grid_idx = parent_grid;
      this.grids = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = grids.length; _i < _len; _i++) {
          grid_opts = grids[_i];
          options = $.extend({}, default_options, grid_opts.options);
          grid = new Slick.Grid(grid_opts.selector, this.data, grid_opts.columns, options);
          grid.multiview_grid_opts = grid_opts;
          grid_opts.$viewport = $(grid_opts.selector).find('.slick-viewport');
          if (grid_opts === grids[this.parent_grid_idx]) {
            this.parent_grid = grid;
          } else {
            grid_opts.$viewport.css('overflow-y', 'hidden');
          }
          _results.push(grid);
        }
        return _results;
      }).call(this);
      this.parent_grid.onViewportChanged = __bind(function() {
        var grid, _i, _len, _ref, _results;
        _ref = this.grids;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          grid = _ref[_i];
          _results.push(grid !== this.parent_grid ? (grid.multiview_grid_opts.$viewport[0].scrollTop = this.parent_grid.multiview_grid_opts.$viewport[0].scrollTop, grid.multiview_grid_opts.$viewport.trigger('scroll.slickgrid')) : void 0);
        }
        return _results;
      }, this);
    }
    return MultiGrid;
  })();
  _ref = ['render', 'removeRow', 'removeAllRows', 'updateRowCount', 'autosizeColumns', 'resizeCanvas'];
  _fn = function(method) {
    return MultiGrid.prototype[method] = function() {
      var grid, _j, _len2, _ref2, _results;
      _ref2 = this.grids;
      _results = [];
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        grid = _ref2[_j];
        _results.push(grid[method].apply(grid, arguments));
      }
      return _results;
    };
  };
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    method = _ref[_i];
    _fn(method);
  }
}).call(this);
