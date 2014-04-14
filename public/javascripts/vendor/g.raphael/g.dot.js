/*!
 * g.Raphael 0.51 - Charting library, based on Raphaël
 *
 * Copyright (c) 2009-2012 Dmitry Baranovskiy (http://g.raphaeljs.com)
 * Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.
 */
define(['./g.raphael'], function (Raphael) {

    var colorValue = function (value, total, s, b) {
        return 'hsb(' + [Math.min((1 - value / total) * .4, 1), s || .75, b || .75] + ')';
    };

    function Dotchart(paper, x, y, width, height, valuesx, valuesy, size, opts) {

        function drawAxis(ax) {
            +ax[0] && (ax[0] = chartinst.axis(x + gutter, y + gutter, width - 2 * gutter, minx, maxx, opts.axisxstep || Math.floor((width - 2 * gutter) / 20), 2, opts.axisxlabels || null, opts.axisxtype || "t", null, paper));
            +ax[1] && (ax[1] = chartinst.axis(x + width - gutter, y + height - gutter, height - 2 * gutter, miny, maxy, opts.axisystep || Math.floor((height - 2 * gutter) / 20), 3, opts.axisylabels || null, opts.axisytype || "t", null, paper));
            +ax[2] && (ax[2] = chartinst.axis(x + gutter, y + height - gutter + maxR, width - 2 * gutter, minx, maxx, opts.axisxstep || Math.floor((width - 2 * gutter) / 20), 0, opts.axisxlabels || null, opts.axisxtype || "t", null, paper));
            +ax[3] && (ax[3] = chartinst.axis(x + gutter - maxR, y + height - gutter, height - 2 * gutter, miny, maxy, opts.axisystep || Math.floor((height - 2 * gutter) / 20), 1, opts.axisylabels || null, opts.axisytype || "t", null, paper));
        }

        //providing defaults

        opts = opts || {};
        var chartinst = this;
        var xdim = chartinst.snapEnds(Math.min.apply(Math, valuesx), Math.max.apply(Math, valuesx), valuesx.length - 1),
            minx = xdim.from,
            maxx = xdim.to,
            gutter = opts.gutter || 10,
            ydim = chartinst.snapEnds(Math.min.apply(Math, valuesy), Math.max.apply(Math, valuesy), valuesy.length - 1),
            miny = ydim.from,
            maxy = ydim.to,
            len = Math.max(valuesx.length, valuesy.length, size.length),
            symbol = paper[opts.symbol] || "circle",
            res = paper.set(),
            series = paper.set(),
            max = opts.max || 100,
            top = Math.max.apply(Math, size),
            R = [],
            k = Math.sqrt(top / Math.PI) * 2 / max;

        for (var i = 0; i < len; i++) {
            R[i] = Math.min(Math.sqrt(size[i] / Math.PI) * 2 / k, max);
        }

        gutter = Math.max.apply(Math, R.concat(gutter));

    /*\
    * dotchart.axis
    [ object ]
    **
    * Set containing Elements of the chart axis. Only exists if `'axis'` definition string was passed to @Paper.dotchart
    **
    \*/
        var axis = paper.set(),
            maxR = Math.max.apply(Math, R);

        if (opts.axis) {
            var ax = (opts.axis + "").split(/[,\s]+/);

            drawAxis.call(chartinst, ax);

            var g = [], b = [];

            for (var i = 0, ii = ax.length; i < ii; i++) {
                var bb = ax[i].all ? ax[i].all.getBBox()[["height", "width"][i % 2]] : 0;

                g[i] = bb + gutter;
                b[i] = bb;
            }

            gutter = Math.max.apply(Math, g.concat(gutter));

            for (var i = 0, ii = ax.length; i < ii; i++) if (ax[i].all) {
                ax[i].remove();
                ax[i] = 1;
            }

            drawAxis.call(chartinst, ax);

            for (var i = 0, ii = ax.length; i < ii; i++) if (ax[i].all) {
                axis.push(ax[i].all);
            }

            res.axis = axis;
        }

        var kx = (width - gutter * 2) / ((maxx - minx) || 1),
            ky = (height - gutter * 2) / ((maxy - miny) || 1);

        for (var i = 0, ii = valuesy.length; i < ii; i++) {
            var sym = paper.raphael.is(symbol, "array") ? symbol[i] : symbol,
                X = x + gutter + (valuesx[i] - minx) * kx,
                Y = y + height - gutter - (valuesy[i] - miny) * ky;

            sym && R[i] && series.push(paper[sym](X, Y, R[i]).attr({ fill: opts.heat ? colorValue(R[i], maxR) : chartinst.colors[0], "fill-opacity": opts.opacity ? R[i] / max : 1, stroke: "none" }));
        }

        var covers = paper.set();

        for (var i = 0, ii = valuesy.length; i < ii; i++) {
            var X = x + gutter + (valuesx[i] - minx) * kx,
                Y = y + height - gutter - (valuesy[i] - miny) * ky;

            covers.push(paper.circle(X, Y, maxR).attr(chartinst.shim));
            opts.href && opts.href[i] && covers[i].attr({href: opts.href[i]});
            covers[i].r = +R[i].toFixed(3);
            covers[i].x = +X.toFixed(3);
            covers[i].y = +Y.toFixed(3);
            covers[i].X = valuesx[i];
            covers[i].Y = valuesy[i];
            covers[i].value = size[i] || 0;
            covers[i].dot = series[i];
        }

    /*\
    * dotchart.covers
    [ object ]
    **
    * Set of Elements positioned above the symbols and mirroring them in size and shape. Covers are used as a surface for events capturing. Each cover has a property `'dot'` being a reference to the actual data-representing symbol.
    **
    **
    \*/
        res.covers = covers;
    /*\
    * dotchart.series
    [ object ]
    **
    * Set of Elements containing the actual data-representing symbols.
    **
    **
    \*/
        res.series = series;
        res.push(series, axis, covers);

    /*\
    * dotchart.hover
    [ method ]
    > Parameters
    - mouseover handler (function) handler for the event
    - mouseout handler (function) handler for the event
    * Conveniece method to set up hover-in and hover-out event handlers
    = (object) @dotchart object
    **
    \*/
        res.hover = function (fin, fout) {
            covers.mouseover(fin).mouseout(fout);
            return this;
        };

    /*\
    * dotchart.click
    [ method ]
    > Parameters
    - click handler (function) handler for the event
    * Conveniece method to set up click event handler
    = (object) @dotchart object
    **
    \*/
        res.click = function (f) {
            covers.click(f);
            return this;
        };

    /*\
    * dotchart.each
    [ method ]
    > Parameters
    - callback (function) called for every item in @dotchart.covers.
    - this (object) callback is executed in a context of a cover element object
    * Conveniece method iterating on every symbol in the chart
    = (object) @dotchart object
    **
    \*/
        res.each = function (f) {
            if (!paper.raphael.is(f, "function")) {
                return this;
            }

            for (var i = covers.length; i--;) {
                f.call(covers[i]);
            }

            return this;
        };

    /*\
    * dotchart.href
    [ method ]
    > Parameters
    - map (array) Array of objects `{x: 1, y: 20, value: 15, href: "http://www.raphaeljs.com"}`
    * Iterates on all @dotchart.covers elements. If x, y and value on the object are the same as on the cover it sets up a link on a symbol using the passef `href`.
    = (object) @dotchart object
    **
    \*/
        res.href = function (map) {
            var cover;

            for (var i = covers.length; i--;) {
                cover = covers[i];

                if (cover.X == map.x && cover.Y == map.y && cover.value == map.value) {
                    cover.attr({href: map.href});
                }
            }
        };
        return res;
    };

    //inheritance
    var F = function() {};
    F.prototype = Raphael.g
    Dotchart.prototype = new F;

    /*
    * dotchart method on paper
    */
    /*\
    * Paper.dotchart
    [ method ]
    **
    * Plots a dot chart
    **
    > Parameters
    - x (number) x coordinate of the chart
    - y (number) y coordinate of the chart
    - width (number) width of the chart (respected by all elements in the set)
    - height (number) height of the chart (respected by all elements in the set)
    - valuesx (array) values used to plot x asis
    - valuesy (array) values used to plot y asis
    - size (array) values used as data
    - opts (object) options for the chart
    > Possible options
    o {
    o max (number) maximum diameter of a dot [default: 100]
    o symbol (string) symbol used for rendering on the chart. The only possible option is `'circle'` [default]
    o gutter (number) distance between symbols on the chart [default: 10]
    o heat (boolean) whether or not to enable coloring higher value symbols with warmer hue [default: false]
    o opacity (number) opacity of the symbols [default: 1]
    o href (array) array of URLs to set up click-throughs on the symbols
    o axis (string) Which axes should be renedered. String of four values evaluated in order `'top right bottom left'` e.g. `'0 0 1 1'`.
    o axisxstep (number) the number of steps to plot on the axis X
    o axisystep (number) the number of steps to plot on the axis Y
    o axisxlabels (array) labels to be rendered instead of numeric values on axis X
    o axisylabels (array) labels to be rendered instead of numeric values on axis Y
    o axisxtype (string) Possible values: `'t'` [default], `'|'`, `' '`, `'-'`, `'+'`
    o axisytype (string) Possible values: `'t'` [default], `'|'`, `' '`, `'-'`, `'+'`
    o }
    **
    = (object) @dotchart object
    > Usage
    | //life, expectancy, country and spending per capita (fictional data)
    | r.dotchart(0, 0, 620, 260, [76, 70, 67, 71, 69], [0, 1, 2, 3, 4], [100, 120, 140, 160, 500], {max: 10, axisylabels: ['Mexico', 'Argentina', 'Cuba', 'Canada', 'United States of America'], heat: true, axis: '0 0 1 1'})
    \*/
    Raphael.fn.dotchart = function(x, y, width, height, valuesx, valuesy, size, opts) {
        return new Dotchart(this, x, y, width, height, valuesx, valuesy, size, opts);
    }

    return Raphael;
});