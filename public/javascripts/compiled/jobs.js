(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  I18n.scoped('jobs', function(I18n) {
    var FlavorGrid, Jobs, Tags, Workers;
    FlavorGrid = (function() {
      function FlavorGrid(options, type_name, grid_name) {
        this.options = options;
        this.type_name = type_name;
        this.grid_name = grid_name;
        this.change_flavor = __bind(this.change_flavor, this);
        this.refresh = __bind(this.refresh, this);
        this.setTimer = __bind(this.setTimer, this);
        this.data = this.options.data;
        this.$element = $(this.grid_name);
        if (this.options.refresh_rate) {
          this.setTimer();
        }
        this.query = '';
      }
      FlavorGrid.prototype.setTimer = function() {
        return setTimeout((__bind(function() {
          return this.refresh(this.setTimer);
        }, this)), this.options.refresh_rate);
      };
      FlavorGrid.prototype.refresh = function(cb) {
        return this.$element.queue(__bind(function() {
          return $.ajaxJSON(this.options.url, "GET", {
            flavor: this.options.flavor,
            q: this.query
          }, __bind(function(data) {
            var i, item, _i, _len, _ref, _ref2, _ref3;
            this.data.length = 0;
            this.loading = {};
            _ref = data[this.type_name];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              item = _ref[_i];
              this.data.push(item);
            }
            if (data.total && data.total > this.data.length) {
              for (i = _ref2 = this.data.length, _ref3 = data.total; _ref2 <= _ref3 ? i < _ref3 : i > _ref3; _ref2 <= _ref3 ? i++ : i--) {
                this.data.push({});
              }
            }
            this.grid.removeAllRows();
            this.grid.updateRowCount();
            this.grid.render();
            if (typeof cb === "function") {
              cb();
            }
            if (typeof this.updated === "function") {
              this.updated();
            }
            return this.$element.dequeue();
          }, this));
        }, this));
      };
      FlavorGrid.prototype.change_flavor = function(flavor) {
        this.options.flavor = flavor;
        this.grid.setSelectedRows([]);
        return this.refresh();
      };
      FlavorGrid.prototype.grid_options = function() {
        return {
          rowHeight: 20
        };
      };
      FlavorGrid.prototype.init = function() {
        this.columns = this.build_columns();
        this.loading = {};
        this.grid = new Slick.Grid(this.grid_name, this.data, this.columns, this.grid_options());
        return this;
      };
      return FlavorGrid;
    })();
    Jobs = (function() {
      __extends(Jobs, FlavorGrid);
      function Jobs(options, type_name, grid_name) {
        if (type_name == null) {
          type_name = 'jobs';
        }
        if (grid_name == null) {
          grid_name = '#jobs-grid';
        }
        this.id_formatter = __bind(this.id_formatter, this);
        this.load = __bind(this.load, this);
        this.attempts_formatter = __bind(this.attempts_formatter, this);
        if (options.max_attempts) {
          Jobs.max_attempts = options.max_attempts;
        }
        Jobs.__super__.constructor.call(this, options, type_name, grid_name);
      }
      Jobs.prototype.search = function(query) {
        this.query = query;
        return this.refresh();
      };
      Jobs.prototype.attempts_formatter = function(r, c, d) {
        var klass, max, out_of;
        if (!this.data[r].id) {
          return '';
        }
        max = this.data[r].max_attempts || Jobs.max_attempts;
        if (d === 0) {
          klass = '';
        } else if (d < max) {
          klass = 'has-failed-attempts';
        } else if (d === this.options.on_hold_attempt_count) {
          klass = 'on-hold';
          d = 'hold';
        } else {
          klass = 'has-failed-max-attempts';
        }
        out_of = d === 'hold' ? '' : "/ " + max;
        return "<span class='" + klass + "'>" + d + out_of + "</span>";
      };
      Jobs.prototype.load = function(row) {
        return this.$element.queue(__bind(function() {
          row = row - (row % this.options.limit);
          if (this.loading[row]) {
            this.$element.dequeue();
            return;
          }
          this.loading[row] = true;
          return $.ajaxJSON(this.options.url, "GET", {
            flavor: this.options.flavor,
            q: this.query,
            offset: row
          }, __bind(function(data) {
            var _ref;
            [].splice.apply(this.data, [row, row + data.jobs.length - row].concat(_ref = data.jobs)), _ref;
            this.grid.removeAllRows();
            this.grid.render();
            return this.$element.dequeue();
          }, this));
        }, this));
      };
      Jobs.prototype.id_formatter = function(r, c, d) {
        if (this.data[r].id) {
          return this.data[r].id;
        } else {
          this.load(r);
          return "<span class='unloaded-id'>-</span>";
        }
      };
      Jobs.prototype.build_columns = function() {
        return [
          {
            id: 'id',
            name: I18n.t('columns.id', 'id'),
            field: 'id',
            width: 75,
            formatter: this.id_formatter
          }, {
            id: 'tag',
            name: I18n.t('columns.tag', 'tag'),
            field: 'tag',
            width: 200
          }, {
            id: 'attempts',
            name: I18n.t('columns.attempt', 'attempt'),
            field: 'attempts',
            width: 60,
            formatter: this.attempts_formatter
          }, {
            id: 'priority',
            name: I18n.t('columns.priority', 'priority'),
            field: 'priority',
            width: 70
          }, {
            id: 'strand',
            name: I18n.t('columns.strand', 'strand'),
            field: 'strand',
            width: 100
          }, {
            id: 'run_at',
            name: I18n.t('columns.run_at', 'run at'),
            field: 'run_at',
            width: 165
          }
        ];
      };
      Jobs.prototype.init = function() {
        Jobs.__super__.init.call(this);
        this.grid.onSelectedRowsChanged = __bind(function() {
          var job, row, rows;
          rows = this.grid.getSelectedRows();
          row = (rows != null ? rows.length : void 0) === 1 ? rows[0] : -1;
          job = this.data[rows[0]] || {};
          $('#show-job .show-field').each(__bind(function(idx, field) {
            var field_name;
            field_name = field.id.replace("job-", '');
            return $(field).text(job[field_name] || '');
          }, this));
          return $('#job-id-link').attr('href', "/jobs?id=" + job.id + "&flavor=" + this.options.flavor);
        }, this);
        if (this.data.length === 1 && this.type_name === 'jobs') {
          this.grid.setSelectedRows([0]);
          this.grid.onSelectedRowsChanged();
        }
        return this;
      };
      Jobs.prototype.selectAll = function() {
        var _i, _ref, _results;
        this.grid.setSelectedRows((function() {
          _results = [];
          for (var _i = 0, _ref = this.data.length; 0 <= _ref ? _i < _ref : _i > _ref; 0 <= _ref ? _i++ : _i--){ _results.push(_i); }
          return _results;
        }).apply(this));
        return this.grid.onSelectedRowsChanged();
      };
      Jobs.prototype.onSelected = function(action) {
        var all_jobs, params, row;
        params = {
          flavor: this.options.flavor,
          q: this.query,
          update_action: action
        };
        all_jobs = this.grid.getSelectedRows().length === this.data.length;
        if (all_jobs && action === 'destroy') {
          if (!confirm(I18n.t('confirm.delete_all', "Are you sure you want to delete *all* jobs of this type and matching this query?"))) {
            return;
          }
        }
        if (!all_jobs) {
          params.job_ids = (function() {
            var _i, _len, _ref, _results;
            _ref = this.grid.getSelectedRows();
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              row = _ref[_i];
              _results.push(this.data[row].id);
            }
            return _results;
          }).call(this);
        }
        $.ajaxJSON(this.options.batch_update_url, "POST", params, this.refresh);
        return this.grid.setSelectedRows([]);
      };
      Jobs.prototype.updated = function() {
        return $('#jobs-total').text(this.data.length);
      };
      return Jobs;
    })();
    Workers = (function() {
      __extends(Workers, Jobs);
      function Workers(options) {
        Workers.__super__.constructor.call(this, options, 'running', '#running-grid');
      }
      Workers.prototype.build_columns = function() {
        var cols;
        cols = [
          {
            id: 'worker',
            name: I18n.t('columns.worker', 'worker'),
            field: 'locked_by',
            width: 175
          }
        ].concat(Workers.__super__.build_columns.call(this));
        cols.pop();
        return cols;
      };
      Workers.prototype.updated = function() {};
      return Workers;
    })();
    Tags = (function() {
      __extends(Tags, FlavorGrid);
      function Tags(options) {
        Tags.__super__.constructor.call(this, options, 'tags', '#tags-grid');
      }
      Tags.prototype.build_columns = function() {
        return [
          {
            id: 'tag',
            name: I18n.t('columns.tag', 'tag'),
            field: 'tag',
            width: 200
          }, {
            id: 'count',
            name: I18n.t('columns.count', 'count'),
            field: 'count',
            width: 50
          }
        ];
      };
      Tags.prototype.grid_options = function() {
        return $.extend(Tags.__super__.grid_options.call(this), {
          enableCellNavigation: false
        });
      };
      return Tags;
    })();
    $.extend(window, {
      Jobs: Jobs,
      Workers: Workers,
      Tags: Tags
    });
    return $(document).ready(function() {
      var search_event;
      $('#tags-flavor').change(function() {
        return window.tags.change_flavor($(this).val());
      });
      $('#jobs-flavor').change(function() {
        return window.jobs.change_flavor($(this).val());
      });
      $('#jobs-refresh').click(function() {
        return window.jobs.refresh();
      });
      search_event = $('#jobs-search')[0].onsearch === void 0 ? 'change' : 'search';
      $('#jobs-search').bind(search_event, function() {
        return window.jobs.search($(this).val());
      });
      $('#select-all-jobs').click(function() {
        return window.jobs.selectAll();
      });
      $('#hold-jobs').click(function() {
        return window.jobs.onSelected('hold');
      });
      $('#un-hold-jobs').click(function() {
        return window.jobs.onSelected('unhold');
      });
      $('#delete-jobs').click(function() {
        return window.jobs.onSelected('destroy');
      });
      $('#job-handler-show').click(function() {
        $('#job-handler-wrapper').clone().dialog({
          title: I18n.t('titles.job_handler', 'Job Handler'),
          width: 900,
          height: 700,
          modal: true
        });
        return false;
      });
      return $('#job-last_error-show').click(function() {
        $('#job-last_error-wrapper').clone().dialog({
          title: I18n.t('titles.last_error', 'Last Error'),
          width: 900,
          height: 700,
          modal: true
        });
        return false;
      });
    });
  });
}).call(this);
