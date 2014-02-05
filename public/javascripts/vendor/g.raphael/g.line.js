/*!
 * g.Raphael 0.51 - Charting library, based on Raphaël
 *
 * Copyright (c) 2009-2012 Dmitry Baranovskiy (http://g.raphaeljs.com)
 * Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.
 */


define(['./g.raphael'], function (Raphael) {

    function shrink(values, dim) {
        var k = values.length / dim,
            j = 0,
            l = k,
            sum = 0,
            res = [];

        while (j < values.length) {
            l--;

            if (l < 0) {
                sum += values[j] * (1 + l);
                res.push(sum / k);
                sum = values[j++] * -l;
                l += k;
            } else {
                sum += values[j++] * 1;
            }
        }
        return res;
    }

    function getAnchors(p1x, p1y, p2x, p2y, p3x, p3y) {
        var l1 = (p2x - p1x) / 2,
            l2 = (p3x - p2x) / 2,
            a = Math.atan((p2x - p1x) / Math.abs(p2y - p1y)),
            b = Math.atan((p3x - p2x) / Math.abs(p2y - p3y));

        a = p1y < p2y ? Math.PI - a : a;
        b = p3y < p2y ? Math.PI - b : b;

        var alpha = Math.PI / 2 - ((a + b) % (Math.PI * 2)) / 2,
            dx1 = l1 * Math.sin(alpha + a),
            dy1 = l1 * Math.cos(alpha + a),
            dx2 = l2 * Math.sin(alpha + b),
            dy2 = l2 * Math.cos(alpha + b);

        return {
            x1: p2x - dx1,
            y1: p2y + dy1,
            x2: p2x + dx2,
            y2: p2y + dy2
        };
    }

    function Linechart(paper, x, y, width, height, valuesx, valuesy, opts) {

        var chartinst = this;

        opts = opts || {};

        if (!paper.raphael.is(valuesx[0], "array")) {
            valuesx = [valuesx];
        }

        if (!paper.raphael.is(valuesy[0], "array")) {
            valuesy = [valuesy];
        }

        var gutter = opts.gutter || 10,
            len = Math.max(valuesx[0].length, valuesy[0].length),
            symbol = opts.symbol || "",
            colors = opts.colors || chartinst.colors,
            columns = null,
            dots = null,
            chart = paper.set(),
            path = [];

        for (var i = 0, ii = valuesy.length; i < ii; i++) {
            len = Math.max(len, valuesy[i].length);
        }

 /*\
 * linechart.shades
 [ object ]
 **
 * Set containing Elements corresponding to shades plotted in the chart (if `opts.shade` was `true`).
 **
 **
 \*/
        var shades = paper.set();

        for (i = 0, ii = valuesy.length; i < ii; i++) {
            if (opts.shade) {
                shades.push(paper.path().attr({ stroke: "none", fill: colors[i], opacity: opts.nostroke ? 1 : .3 }));
            }

            if (valuesy[i].length > width - 2 * gutter) {
                valuesy[i] = shrink(valuesy[i], width - 2 * gutter);
                len = width - 2 * gutter;
            }

            if (valuesx[i] && valuesx[i].length > width - 2 * gutter) {
                valuesx[i] = shrink(valuesx[i], width - 2 * gutter);
            }
        }

        var allx = Array.prototype.concat.apply([], valuesx),
            ally = Array.prototype.concat.apply([], valuesy),
            xdim = chartinst.snapEnds(Math.min.apply(Math, allx), Math.max.apply(Math, allx), valuesx[0].length - 1),
            minx = xdim.from,
            maxx = xdim.to,
            ydim = chartinst.snapEnds(Math.min.apply(Math, ally), Math.max.apply(Math, ally), valuesy[0].length - 1),
            miny = ydim.from,
            maxy = ydim.to,
            kx = (width - gutter * 2) / ((maxx - minx) || 1),
            ky = (height - gutter * 2) / ((maxy - miny) || 1);

 /*\
 * linechart.axis
 [ object ]
 **
 * Set containing Elements of the chart axis. The set is populated if `'axis'` definition string was passed to @Paper.linechart
 **
 **
 \*/
        var axis = paper.set();

        if (opts.axis) {
            var ax = (opts.axis + "").split(/[,\s]+/);
            +ax[0] && axis.push(chartinst.axis(x + gutter, y + gutter, width - 2 * gutter, minx, maxx, opts.axisxstep || Math.floor((width - 2 * gutter) / 20), 2, paper));
            +ax[1] && axis.push(chartinst.axis(x + width - gutter, y + height - gutter, height - 2 * gutter, miny, maxy, opts.axisystep || Math.floor((height - 2 * gutter) / 20), 3, paper));
            +ax[2] && axis.push(chartinst.axis(x + gutter, y + height - gutter, width - 2 * gutter, minx, maxx, opts.axisxstep || Math.floor((width - 2 * gutter) / 20), 0, paper));
            +ax[3] && axis.push(chartinst.axis(x + gutter, y + height - gutter, height - 2 * gutter, miny, maxy, opts.axisystep || Math.floor((height - 2 * gutter) / 20), 1, paper));
        }

 /*\
 * linechart.lines
 [ object ]
 **
 * Set containing Elements corresponding to lines plotted in the chart.
 **
 **
 \*/
        var lines = paper.set(),
 /*\
 * linechart.symbols
 [ object ]
 **
 * Set containing Elements corresponding to symbols plotted in the chart.
 **
 **
 \*/
            symbols = paper.set(),
            line;

        for (i = 0, ii = valuesy.length; i < ii; i++) {
            if (!opts.nostroke) {
                lines.push(line = paper.path().attr({
                    stroke: colors[i],
                    "stroke-width": opts.width || 2,
                    "stroke-linejoin": "round",
                    "stroke-linecap": "round",
                    "stroke-dasharray": opts.dash || ""
                }));
            }

            var sym = Raphael.is(symbol, "array") ? symbol[i] : symbol,
                symset = paper.set();

            path = [];

            for (var j = 0, jj = valuesy[i].length; j < jj; j++) {
                var X = x + gutter + ((valuesx[i] || valuesx[0])[j] - minx) * kx,
                    Y = y + height - gutter - (valuesy[i][j] - miny) * ky;

                (Raphael.is(sym, "array") ? sym[j] : sym) && symset.push(paper[Raphael.is(sym, "array") ? sym[j] : sym](X, Y, (opts.width || 2) * 3).attr({ fill: colors[i], stroke: "none" }));

                if (opts.smooth) {
                    if (j && j != jj - 1) {
                        var X0 = x + gutter + ((valuesx[i] || valuesx[0])[j - 1] - minx) * kx,
                            Y0 = y + height - gutter - (valuesy[i][j - 1] - miny) * ky,
                            X2 = x + gutter + ((valuesx[i] || valuesx[0])[j + 1] - minx) * kx,
                            Y2 = y + height - gutter - (valuesy[i][j + 1] - miny) * ky,
                            a = getAnchors(X0, Y0, X, Y, X2, Y2);

                        path = path.concat([a.x1, a.y1, X, Y, a.x2, a.y2]);
                    }

                    if (!j) {
                        path = ["M", X, Y, "C", X, Y];
                    }
                } else {
                    path = path.concat([j ? "L" : "M", X, Y]);
                }
            }

            if (opts.smooth) {
                path = path.concat([X, Y, X, Y]);
            }

            symbols.push(symset);

            if (opts.shade) {
                shades[i].attr({ path: path.concat(["L", X, y + height - gutter, "L",  x + gutter + ((valuesx[i] || valuesx[0])[0] - minx) * kx, y + height - gutter, "z"]).join(",") });
            }

            !opts.nostroke && line.attr({ path: path.join(",") });
        }

        function createColumns(f) {
            // unite Xs together
            var Xs = [];

            for (var i = 0, ii = valuesx.length; i < ii; i++) {
                Xs = Xs.concat(valuesx[i]);
            }

            Xs.sort(function(a,b) { return a - b; });
            // remove duplicates

            var Xs2 = [],
                xs = [];

            for (i = 0, ii = Xs.length; i < ii; i++) {
                Xs[i] != Xs[i - 1] && Xs2.push(Xs[i]) && xs.push(x + gutter + (Xs[i] - minx) * kx);
            }

            Xs = Xs2;
            ii = Xs.length;

            var cvrs = f || paper.set();

            for (i = 0; i < ii; i++) {
                var X = xs[i] - (xs[i] - (xs[i - 1] || x)) / 2,
                    w = ((xs[i + 1] || x + width) - xs[i]) / 2 + (xs[i] - (xs[i - 1] || x)) / 2,
                    C;

                f ? (C = {}) : cvrs.push(C = paper.rect(X - 1, y, Math.max(w + 1, 1), height).attr({ stroke: "none", fill: "#000", opacity: 0 }));
                C.values = [];
                C.symbols = paper.set();
                C.y = [];
                C.x = xs[i];
                C.axis = Xs[i];

                for (var j = 0, jj = valuesy.length; j < jj; j++) {
                    Xs2 = valuesx[j] || valuesx[0];

                    for (var k = 0, kk = Xs2.length; k < kk; k++) {
                        if (Xs2[k] == Xs[i]) {
                            C.values.push(valuesy[j][k]);
                            C.y.push(y + height - gutter - (valuesy[j][k] - miny) * ky);
                            C.symbols.push(chart.symbols[j][k]);
                        }
                    }
                }

                f && f.call(C);
            }

            !f && (columns = cvrs);
        }

        function createDots(f) {
            var cvrs = f || paper.set(),
                C;

            for (var i = 0, ii = valuesy.length; i < ii; i++) {
                for (var j = 0, jj = valuesy[i].length; j < jj; j++) {
                    var X = x + gutter + ((valuesx[i] || valuesx[0])[j] - minx) * kx,
                        nearX = x + gutter + ((valuesx[i] || valuesx[0])[j ? j - 1 : 1] - minx) * kx,
                        Y = y + height - gutter - (valuesy[i][j] - miny) * ky;
                    f ? (C = {}) : cvrs.push(C = paper.circle(X, Y, Math.abs(nearX - X) / 2).attr({ stroke: "#000", fill: "#000", opacity: 1 }));
                    C.x = X;
                    C.y = Y;
                    C.value = valuesy[i][j];
                    C.line = chart.lines[i];
                    C.shade = chart.shades[i];
                    C.symbol = chart.symbols[i][j];
                    C.symbols = chart.symbols[i];
                    C.axis = (valuesx[i] || valuesx[0])[j];
                    f && f.call(C);
                }
            }

            !f && (dots = cvrs);
        }

        chart.push(lines, shades, symbols, axis, columns, dots);
        chart.lines = lines;
        chart.shades = shades;
        chart.symbols = symbols;
        chart.axis = axis;

 /*\
 * linechart.hoverColumn
 [ method ]
 > Parameters
 - mouseover handler (function) handler for the event
 - mouseout handler (function) handler for the event
 - this (object) callback is executed in a context of a cover element
 * Conveniece method to set up hover-in and hover-out event handlers on the entire area of the chart.
 * The handlers are passed a event object containing
 o {
 o x (number) x coordinate on all lines in the chart
 o y (array) y coordinates of all lines corresponding to the x
 o }
 = (object) @linechart object
 **
 \*/

        chart.hoverColumn = function (fin, fout) {
            !columns && createColumns();
            columns.mouseover(fin).mouseout(fout);
            return this;
        };

 /*\
 * linechart.clickColumn
 [ method ]
 > Parameters
 - click handler (function) handler for the event
 - this (object) callback is executed in a context of a cover element
 * Conveniece method to set up click event handler on the antire area of the chart.
 * The handler is passed a event object containing
 o {
 o x (number) x coordinate on all lines in the chart
 o y (array) y coordinates of all lines corresponding to the x
 o }
 = (object) @linechart object
 **
 \*/
        chart.clickColumn = function (f) {
            !columns && createColumns();
            columns.click(f);
            return this;
        };

 /*\
 * linechart.hrefColumn
 [ method ]
 > Parameters
 - cols (object) object containing values as keys and URLs as values, e.g. {1: 'http://www.raphaeljs.com', 2: 'http://g.raphaeljs.com'}
 * Creates click-throughs on the whole area of the chart corresponding to x values
 = (object) @linechart object
 **
 \*/
        chart.hrefColumn = function (cols) {
            var hrefs = paper.raphael.is(arguments[0], "array") ? arguments[0] : arguments;

            if (!(arguments.length - 1) && typeof cols == "object") {
                for (var x in cols) {
                    for (var i = 0, ii = columns.length; i < ii; i++) if (columns[i].axis == x) {
                        columns[i].attr("href", cols[x]);
                    }
                }
            }

            !columns && createColumns();

            for (i = 0, ii = hrefs.length; i < ii; i++) {
                columns[i] && columns[i].attr("href", hrefs[i]);
            }

            return this;
        };

 /*\
 * linechart.hover
 [ method ]
 > Parameters
 - mouseover handler (function) handler for the event
 - mouseout handler (function) handler for the event
 * Conveniece method to set up hover-in and hover-out event handlers working on the lines of the chart.
 * Use @linechart.hoverColumn to work with the entire chart area.
 = (object) @linechart object
 **
 \*/
        chart.hover = function (fin, fout) {
            !dots && createDots();
            dots.mouseover(fin).mouseout(fout);
            return this;
        };

 /*\
 * linechart.click
 [ method ]
 > Parameters
 - click handler (function) handler for the event
 - this (object) callback is executed in a context of a cover element
 * Conveniece method to set up click event handler on the lines of the chart
 * Use @linechart.clickColumn to work with the entire chart area.
 = (object) @linechart object
 **
 \*/
        chart.click = function (f) {
            !dots && createDots();
            dots.click(f);
            return this;
        };

 /*\
 * linechart.each
 [ method ]
 > Parameters
 - callback (function) function executed for every data point
 - this (object) context of the callback function.
 o {
 o x (number) x coordinate of the data point
 o y (number) y coordinate of the data point
 o value (number) value represented by the data point
 o }
 * Iterates over each unique data point plotted on every line on the chart.
 = (object) @linechart object
 **
 \*/
        chart.each = function (f) {
            createDots(f);
            return this;
        };

 /*\
 * linechart.eachColumn
 [ method ]
 > Parameters
 - callback (function) function executed for every column
 - this (object) context of the callback function.
 o {
 o x (number) x coordinate of the data point
 o y (array) y coordinates of data points existing for the given x
 o values (array) values represented by the data points existing for the given x
 o }
 * Iterates over each column area (area plotted above the chart).
 = (object) @linechart object
 **
 \*/
        chart.eachColumn = function (f) {
            createColumns(f);
            return this;
        };

        return chart;
    };

    //inheritance
    var F = function() {};
    F.prototype = Raphael.g;
    Linechart.prototype = new F;

 /*
 * linechart method on paper
 */
/*\
 * Paper.linechart
 [ method ]
 **
 * Creates a line chart
 **
 > Parameters
 **
 - x (number) x coordinate of the chart
 - y (number) y coordinate of the chart
 - width (number) width of the chart (including the axis)
 - height (number) height of the chart (including the axis)
 - valuesx (array) values to plot on axis x
 - valuesy (array) values to plot on axis y
 - opts (object) options for the chart
 o {
 o gutter (number) distance between symbols on the chart
 o symbol (string) (array) symbol to be plotted as nodes of the chart, if array are passed symbols are printed iteratively. Currently `'circle'` and `''` (no symbol) are the only supported options.
 o width (number) controls the size of the plotted symbol. Also controls the thickness of the line using a formula stroke-width=width/2. This option is likely to change in the future versions of g.raphael.
 o colors (array) colors to plot data series. Raphael default colors are used if not passed
 o shade (boolean) whether or not to plot a shade of the chart [default: false]. Currently only a shade between the line and x axis is supported.
 o nostroke (boolean) whether or not to plot lines [default: false]. Only practical when shade is enabled.
 o dash (string) changes display of the line from continues to dashed or dotted (Possible values are the same as stroke-dasharray attribute, see @Element.attr).
 o smooth (boolean) changes display of the line from point-to-point straight lines to curves (type C, see @Paper.path).
 o axis (string) Which axes should be renedered. String of four values evaluated in order `'top right bottom left'` e.g. `'0 0 1 1'`.
 o axisxstep (number) distance between values on axis X
 o axisystep (number) distance between values on axis Y
 o }
 **
 = (object) path element of the popup
 > Usage
 | r.linechart(0, 0, 99, 99, [1,2,3,4,5], [[1,2,3,4,5], [1,3,9,16,25], [100,50,25,12,6]], {smooth: true, colors: ['#F00', '#0F0', '#FF0'], symbol: 'circle'});
 \*/
    Raphael.fn.linechart = function(x, y, width, height, valuesx, valuesy, opts) {
        return new Linechart(this, x, y, width, height, valuesx, valuesy, opts);
    };

    return Raphael;
});