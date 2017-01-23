/*
 RequireJS 2.1.8 Copyright (c) 2010-2012, The Dojo Foundation All Rights Reserved.
 Available via the MIT or new BSD license.
 see: http://github.com/jrburke/requirejs for details
*/
let requirejs,
  require,
  define;
(function (Z) {
  function H (b) { return L.call(b) === '[object Function]' } function I (b) { return L.call(b) === '[object Array]' } function y (b, c) { if (b) { let d; for (d = 0; d < b.length && (!b[d] || !c(b[d], d, b)); d += 1); } } function M (b, c) { if (b) { let d; for (d = b.length - 1; d > -1 && (!b[d] || !c(b[d], d, b)); d -= 1); } } function s (b, c) { return ga.call(b, c) } function l (b, c) { return s(b, c) && b[c] } function F (b, c) { for (const d in b) if (s(b, d) && c(b[d], d)) break } function Q (b, c, d, h) {
    c && F(c, (c, j) => {
      if (d || !s(b, j)) {
        h && typeof c !== 'string' ? (b[j] || (b[j] = {}), Q(b[j],
c, d, h)) : b[j] = c
      }
    }); return b
  } function u (b, c) { return function () { return c.apply(b, arguments) } } function aa (b) { throw b; } function ba (b) { if (!b) return b; let c = Z; y(b.split('.'), (b) => { c = c[b] }); return c } function A (b, c, d, h) { c = Error(`${c}\nhttp://requirejs.org/docs/errors.html#${b}`); c.requireType = b; c.requireModules = h; d && (c.originalError = d); return c } function ha (b) {
    function c (a, f, b) {
      let e,
        m,
        c,
        g,
        d,
        h,
        j,
        i = f && f.split('/'); e = i; let n = k.map,
          p = n && n['*']; if (a && a.charAt(0) === '.') {
            if (f) {
              e = l(k.pkgs, f) ? i = [f] : i.slice(0, i.length -
1); f = a = e.concat(a.split('/')); for (e = 0; f[e]; e += 1) if (m = f[e], m === '.')f.splice(e, 1), e -= 1; else if (m === '..') if (e === 1 && (f[2] === '..' || f[0] === '..')) break; else e > 0 && (f.splice(e - 1, 2), e -= 2); e = l(k.pkgs, f = a[0]); a = a.join('/'); e && a === `${f}/${e.main}` && (a = f)
            } else a.indexOf('./') === 0 && (a = a.substring(2));
          } if (b && n && (i || p)) {
            f = a.split('/'); for (e = f.length; e > 0; e -= 1) { c = f.slice(0, e).join('/'); if (i) for (m = i.length; m > 0; m -= 1) if (b = l(n, i.slice(0, m).join('/'))) if (b = l(b, c)) { g = b; d = e; break } if (g) break; !h && (p && l(p, c)) && (h = l(p, c), j = e) }!g &&
h && (g = h, d = j); g && (f.splice(0, d, g), a = f.join('/'))
          } return a
    } function d (a) { z && y(document.getElementsByTagName('script'), (f) => { if (f.getAttribute('data-requiremodule') === a && f.getAttribute('data-requirecontext') === i.contextName) return f.parentNode.removeChild(f), !0 }) } function h (a) { const f = l(k.paths, a); if (f && I(f) && f.length > 1) return d(a), f.shift(), i.require.undef(a), i.require([a]), !0 } function $ (a) {
      let f,
        b = a ? a.indexOf('!') : -1; b > -1 && (f = a.substring(0, b), a = a.substring(b + 1, a.length)); return [f, a]
    } function n (a,
      f, b, e) {
      let m,
        B,
        g = null,
        d = f ? f.name : null,
        h = a,
        j = !0,
        k = ''; a || (j = !1, a = `_@r${L += 1}`); a = $(a); g = a[0]; a = a[1]; g && (g = c(g, d, e), B = l(r, g)); a && (g ? k = B && B.normalize ? B.normalize(a, a => c(a, d, e)) : c(a, d, e) : (k = c(a, d, e), a = $(k), g = a[0], k = a[1], b = !0, m = i.nameToUrl(k))); b = g && !B && !b ? `_unnormalized${M += 1}` : ''; return { prefix: g, name: k, parentMap: f, unnormalized: !!b, url: m, originalName: h, isDefine: j, id: (g ? `${g}!${k}` : k) + b }
    } function q (a) {
      let f = a.id,
        b = l(p, f); b || (b = p[f] = new i.Module(a)); return b
    } function t (a, f, b) {
      let e = a.id,
       m = l(p,
e); if (s(r, e) && (!m || m.defineEmitComplete))f === 'defined' && b(r[e]); else if (m = q(a), m.error && f === 'error')b(m.error); else m.on(f, b)
    } function v (a, f) {
     let b = a.requireModules,
      e = !1; if (f)f(a); else if (y(b, (f) => { if (f = l(p, f))f.error = a, f.events.error && (e = !0, f.emit('error', a)) }), !e)j.onError(a)
   } function w () { R.length && (ia.apply(G, [G.length - 1, 0].concat(R)), R = []) } function x (a) { delete p[a]; delete T[a] } function E (a, f, b) {
    const e = a.map.id; a.error ? a.emit('error', a.error) : (f[e] = !0, y(a.depMaps, (e, c) => {
      let g = e.id,
      d = l(p, g); d && (!a.depMatched[c] && !b[g]) && (l(f, g) ? (a.defineDep(c, r[g]), a.check()) : E(d, f, b))
    }), b[e] = !0)
  } function C () {
    let a,
    f,
    b,
    e,
    m = (b = 1E3 * k.waitSeconds) && i.startTime + b < (new Date()).getTime(),
    c = [],
    g = [],
    j = !1,
    l = !0; if (!U) {
      U = !0; F(T, (b) => { a = b.map; f = a.id; if (b.enabled && (a.isDefine || g.push(b), !b.error)) if (!b.inited && m)h(f) ? j = e = !0 : (c.push(f), d(f)); else if (!b.inited && (b.fetched && a.isDefine) && (j = !0, !a.prefix)) return l = !1 }); if (m && c.length) {
        return b = A('timeout', `Load timeout for modules: ${c}`, null, c), b.contextName =
i.contextName, v(b);
      } l && y(g, (a) => { E(a, {}, {}) }); if ((!m || e) && j) if ((z || da) && !V)V = setTimeout(() => { V = 0; C() }, 50); U = !1
    }
  } function D (a) { s(r, a[0]) || q(n(a[0], null, !0)).init(a[1], a[2]) } function J (a) {
  var a = a.currentTarget || a.srcElement,
    b = i.onScriptLoad; a.detachEvent && !W ? a.detachEvent('onreadystatechange', b) : a.removeEventListener('load', b, !1); b = i.onScriptError; (!a.detachEvent || W) && a.removeEventListener('error', b, !1); return { node: a, id: a && a.getAttribute('data-requiremodule') }
} function K () {
  let a; for (w(); G.length;) {
    a =
G.shift(); if (a[0] === null) return v(A('mismatch', `Mismatched anonymous define() module: ${a[a.length - 1]}`)); D(a)
  }
} var U,
  X,
  i,
  N,
  V,
  k = { waitSeconds: 7, baseUrl: './', paths: {}, pkgs: {}, shim: {}, config: {} },
  p = {},
  T = {},
  Y = {},
  G = [],
  r = {},
  S = {},
  L = 1,
  M = 1; N = { require (a) { return a.require ? a.require : a.require = i.makeRequire(a.map) },
    exports (a) { a.usingExports = !0; if (a.map.isDefine) return a.exports ? a.exports : a.exports = r[a.map.id] = {} },
    module (a) {
      return a.module ? a.module : a.module = { id: a.map.id,
        uri: a.map.url,
        config () {
          const b =
l(k.pkgs, a.map.id); return (b ? l(k.config, `${a.map.id}/${b.main}`) : l(k.config, a.map.id)) || {}
        },
        exports: r[a.map.id] }
    } }; X = function (a) { this.events = l(Y, a.id) || {}; this.map = a; this.shim = l(k.shim, a.id); this.depExports = []; this.depMaps = []; this.depMatched = []; this.pluginMaps = {}; this.depCount = 0 }; X.prototype = { init (a, b, c, e) {
      e = e || {}; if (!this.inited) {
        this.factory = b; if (c) this.on('error', c); else this.events.error && (c = u(this, function (a) { this.emit('error', a) })); this.depMaps = a && a.slice(0); this.errback = c; this.inited = !0;
        this.ignore = e.ignore; e.enabled || this.enabled ? this.enable() : this.check()
      }
    },
      defineDep (a, b) { this.depMatched[a] || (this.depMatched[a] = !0, this.depCount -= 1, this.depExports[a] = b) },
      fetch () { if (!this.fetched) { this.fetched = !0; i.startTime = (new Date()).getTime(); const a = this.map; if (this.shim)i.makeRequire(this.map, { enableBuildCallback: !0 })(this.shim.deps || [], u(this, function () { return a.prefix ? this.callPlugin() : this.load() })); else return a.prefix ? this.callPlugin() : this.load() } },
      load () {
        const a =
this.map.url; S[a] || (S[a] = !0, i.load(this.map.id, a))
      },
      check () {
        if (this.enabled && !this.enabling) {
          let a,
            b,
            c = this.map.id; b = this.depExports; let e = this.exports,
              m = this.factory; if (this.inited) {
            if (this.error) this.emit('error', this.error); else if (!this.defining) {
              this.defining = !0; if (this.depCount < 1 && !this.defined) {
                if (H(m)) {
                if (this.events.error && this.map.isDefine || j.onError !== aa) try { e = i.execCb(c, m, b, e) } catch (d) { a = d } else e = i.execCb(c, m, b, e); this.map.isDefine && ((b = this.module) && void 0 !== b.exports && b.exports !==
this.exports ? e = b.exports : void 0 === e && this.usingExports && (e = this.exports)); if (a) return a.requireMap = this.map, a.requireModules = this.map.isDefine ? [this.map.id] : null, a.requireType = this.map.isDefine ? 'define' : 'require', v(this.error = a)
              } else e = m; this.exports = e; if (this.map.isDefine && !this.ignore && (r[c] = e, j.onResourceLoad))j.onResourceLoad(i, this.map, this.depMaps); x(c); this.defined = !0
              } this.defining = !1; this.defined && !this.defineEmitted && (this.defineEmitted = !0, this.emit('defined', this.exports), this.defineEmitComplete =
!0)
            } else this.fetch()
          }
        }
      },
      callPlugin () {
        let a = this.map,
          b = a.id,
          d = n(a.prefix); this.depMaps.push(d); t(d, 'defined', u(this, function (e) {
            let m,
              d; d = this.map.name; let g = this.map.parentMap ? this.map.parentMap.name : null,
            h = i.makeRequire(a.parentMap, { enableBuildCallback: !0 }); if (this.map.unnormalized) {
              if (e.normalize && (d = e.normalize(d, a => c(a, g, !0)) || ''), e = n(`${a.prefix}!${d}`, this.map.parentMap), t(e, 'defined', u(this, function (a) { this.init([], () => a, null, { enabled: !0, ignore: !0 }) })),
d = l(p, e.id)) { this.depMaps.push(e); if (this.events.error)d.on('error', u(this, function (a) { this.emit('error', a) })); d.enable() }
            } else {
              m = u(this, function (a) { this.init([], () => a, null, { enabled: !0 }) }), m.error = u(this, function (a) { this.inited = !0; this.error = a; a.requireModules = [b]; F(p, (a) => { a.map.id.indexOf(`${b}_unnormalized`) === 0 && x(a.map.id) }); v(a) }), m.fromText = u(this, function (e, c) {
                let d = a.name,
               g = n(d),
               B = O; c && (e = c); B && (O = !1); q(g); s(k.config, b) && (k.config[d] = k.config[b]); try { j.exec(e) } catch (ca) {
                return v(A('fromtexteval',
`fromText eval for ${b} failed: ${ca}`, ca, [b]))
              }B && (O = !0); this.depMaps.push(g); i.completeLoad(d); h([d], m)
              }), e.load(a.name, h, m, k)
            }
          })); i.enable(d, this); this.pluginMaps[d.id] = d
      },
      enable () {
        T[this.map.id] = this; this.enabling = this.enabled = !0; y(this.depMaps, u(this, function (a, b) {
          let c,
            e; if (typeof a === 'string') {
              a = n(a, this.map.isDefine ? this.map : this.map.parentMap, !1, !this.skipMap); this.depMaps[b] = a; if (c = l(N, a.id)) { this.depExports[b] = c(this); return } this.depCount += 1; t(a, 'defined', u(this, function (a) {
            this.defineDep(b,
a); this.check()
          })); this.errback && t(a, 'error', u(this, this.errback))
            }c = a.id; e = p[c]; !s(N, c) && (e && !e.enabled) && i.enable(a, this)
        })); F(this.pluginMaps, u(this, function (a) { const b = l(p, a.id); b && !b.enabled && i.enable(a, this) })); this.enabling = !1; this.check()
      },
      on (a, b) { let c = this.events[a]; c || (c = this.events[a] = []); c.push(b) },
      emit (a, b) { y(this.events[a], (a) => { a(b) }); a === 'error' && delete this.events[a] } }; i = { config: k,
        contextName: b,
        registry: p,
        defined: r,
        urlFetched: S,
        defQueue: G,
        Module: X,
        makeModuleMap: n,
        nextTick: j.nextTick,
        onError: v,
        configure (a) {
          a.baseUrl && a.baseUrl.charAt(a.baseUrl.length - 1) !== '/' && (a.baseUrl += '/'); let b = k.pkgs,
            c = k.shim,
            e = { paths: !0, config: !0, map: !0 }; F(a, (a, b) => { e[b] ? b === 'map' ? (k.map || (k.map = {}), Q(k[b], a, !0, !0)) : Q(k[b], a, !0) : k[b] = a }); a.shim && (F(a.shim, (a, b) => { I(a) && (a = { deps: a }); if ((a.exports || a.init) && !a.exportsFn)a.exportsFn = i.makeShimExports(a); c[b] = a }), k.shim = c); a.packages && (y(a.packages, (a) => {
              a = typeof a === 'string' ? { name: a } : a; b[a.name] = { name: a.name,
            location: a.location || a.name,
            main: (a.main || 'main').replace(ja, '').replace(ea, '') }
            }), k.pkgs = b); F(p, (a, b) => { !a.inited && !a.map.unnormalized && (a.map = n(b)) }); if (a.deps || a.callback)i.require(a.deps || [], a.callback)
        },
        makeShimExports (a) { return function () { let b; a.init && (b = a.init.apply(Z, arguments)); return b || a.exports && ba(a.exports) } },
        makeRequire (a, f) {
          function d (e, c, h) {
            let g,
              k; f.enableBuildCallback && (c && H(c)) && (c.__requireJsBuild = !0); if (typeof e === 'string') {
            if (H(c)) {
              return v(A('requireargs',
'Invalid require call'), h);
            } if (a && s(N, e)) return N[e](p[a.id]); if (j.get) return j.get(i, e, a, d); g = n(e, a, !1, !0); g = g.id; return !s(r, g) ? v(A('notloaded', `Module name "${g}" has not been loaded yet for context: ${b}${a ? '' : '. Use require([])'}`)) : r[g]
          }K(); i.nextTick(() => { K(); k = q(n(null, a)); k.skipMap = f.skipMap; k.init(e, c, h, { enabled: !0 }); C() }); return d
          }f = f || {}; Q(d, { isBrowser: z,
            toUrl (b) {
          let d,
            f = b.lastIndexOf('.'),
            g = b.split('/')[0]; if (f !== -1 && (!(g === '.' || g === '..') || f > 1)) {
              d = b.substring(f, b.length), b =
b.substring(0, f);
            } return i.nameToUrl(c(b, a && a.id, !0), d, !0)
        },
            defined (b) { return s(r, n(b, a, !1, !0).id) },
            specified (b) { b = n(b, a, !1, !0).id; return s(r, b) || s(p, b) } }); a || (d.undef = function (b) {
          w(); let c = n(b, a, !0),
            f = l(p, b); delete r[b]; delete S[c.url]; delete Y[b]; f && (f.events.defined && (Y[b] = f.events), x(b))
        }); return d
        },
        enable (a) { l(p, a.id) && q(a).enable() },
        completeLoad (a) {
          let b,
            c,
            e = l(k.shim, a) || {},
            d = e.exports; for (w(); G.length;) {
              c = G.shift(); if (c[0] === null) { c[0] = a; if (b) break; b = !0 } else {
            c[0] ===
a && (b = !0);
          } D(c)
            }c = l(p, a); if (!b && !s(r, a) && c && !c.inited) { if (k.enforceDefine && (!d || !ba(d))) return h(a) ? void 0 : v(A('nodefine', `No define call for ${a}`, null, [a])); D([a, e.deps || [], e.exportsFn]) }C()
        },
        nameToUrl (a, b, c) {
          let e,
            d,
            h,
            g,
            i,
            n; if (j.jsExtRegExp.test(a))g = a + (b || ''); else {
              e = k.paths; d = k.pkgs; g = a.split('/'); for (i = g.length; i > 0; i -= 1) if (n = g.slice(0, i).join('/'), h = l(d, n), n = l(e, n)) { I(n) && (n = n[0]); g.splice(0, i, n); break } else if (h) { a = a === h.name ? `${h.location}/${h.main}` : h.location; g.splice(0, i, a); break }g = g.join('/');
              g += b || (/\?/.test(g) || c ? '' : '.js'); g = (g.charAt(0) === '/' || g.match(/^[\w\+\.\-]+:/) ? '' : k.baseUrl) + g
            } return k.urlArgs ? g + ((g.indexOf('?') === -1 ? '?' : '&') + k.urlArgs) : g
        },
        load (a, b) { j.load(i, a, b) },
        execCb (a, b, c, e) { return b.apply(e, c) },
        onScriptLoad (a) { if (a.type === 'load' || ka.test((a.currentTarget || a.srcElement).readyState))P = null, a = J(a), i.completeLoad(a.id) },
        onScriptError (a) { const b = J(a); if (!h(b.id)) return v(A('scripterror', `Script error for: ${b.id}`, a, [b.id])) } }; i.require = i.makeRequire();
    return i
  } var j,
    w,
    x,
    C,
    J,
    D,
    P,
    K,
    q,
    fa,
    la = /(\/\*([\s\S]*?)\*\/|([^:]|^)\/\/(.*)$)/mg,
    ma = /[^.]\s*require\s*\(\s*["']([^'"\s]+)["']\s*\)/g,
    ea = /\.js$/,
    ja = /^\.\//; w = Object.prototype; var L = w.toString,
      ga = w.hasOwnProperty,
      ia = Array.prototype.splice,
      z = !!(typeof window !== 'undefined' && navigator && window.document),
      da = !z && typeof importScripts !== 'undefined',
      ka = z && navigator.platform === 'PLAYSTATION 3' ? /^complete$/ : /^(complete|loaded)$/,
      W = typeof opera !== 'undefined' && opera.toString() === '[object Opera]',
      E = {},
      t = {},
      R = [],
      O =
!1; if (typeof define === 'undefined') {
  if (typeof requirejs !== 'undefined') { if (H(requirejs)) return; t = requirejs; requirejs = void 0 } typeof require !== 'undefined' && !H(require) && (t = require, require = void 0); j = requirejs = function (b, c, d, h) {
    let q,
      n = '_'; !I(b) && typeof b !== 'string' && (q = b, I(c) ? (b = c, c = d, d = h) : b = []); q && q.context && (n = q.context); (h = l(E, n)) || (h = E[n] = j.s.newContext(n)); q && h.configure(q); return h.require(b, c, d)
  }; j.config = function (b) { return j(b) }; j.nextTick = typeof setTimeout !== 'undefined' ? function (b) {
    setTimeout(b,
4)
  } : function (b) { b() }; require || (require = j); j.version = '2.1.8'; j.jsExtRegExp = /^\/|:|\?|\.js$/; j.isBrowser = z; w = j.s = { contexts: E, newContext: ha }; j({}); y(['toUrl', 'undef', 'defined', 'specified'], (b) => { j[b] = function () { const c = E._; return c.require[b].apply(c, arguments) } }); if (z && (x = w.head = document.getElementsByTagName('head')[0], C = document.getElementsByTagName('base')[0]))x = w.head = C.parentNode; j.onError = aa; j.createNode = function (b) {
    const c = b.xhtml ? document.createElementNS('http://www.w3.org/1999/xhtml', 'html:script') :
document.createElement('script'); c.type = b.scriptType || 'text/javascript'; c.charset = 'utf-8'; c.async = !0; return c
  }; j.load = function (b, c, d) {
    let h = b && b.config || {}; if (z) {
      return h = j.createNode(h, c, d), h.setAttribute('data-requirecontext', b.contextName), h.setAttribute('data-requiremodule', c), h.attachEvent && !(h.attachEvent.toString && h.attachEvent.toString().indexOf('[native code') < 0) && !W ? (O = !0, h.attachEvent('onreadystatechange', b.onScriptLoad)) : (h.addEventListener('load', b.onScriptLoad, !1), h.addEventListener('error',
b.onScriptError, !1)), h.src = d, K = h, C ? x.insertBefore(h, C) : x.appendChild(h), K = null, h;
    } if (da) try { importScripts(d), b.completeLoad(c) } catch (l) { b.onError(A('importscripts', `importScripts failed for ${c} at ${d}`, l, [c])) }
  }; z && M(document.getElementsByTagName('script'), (b) => { x || (x = b.parentNode); if (J = b.getAttribute('data-main')) return q = J, t.baseUrl || (D = q.split('/'), q = D.pop(), fa = D.length ? `${D.join('/')}/` : './', t.baseUrl = fa), q = q.replace(ea, ''), j.jsExtRegExp.test(q) && (q = J), t.deps = t.deps ? t.deps.concat(q) : [q], !0 });
  define = function (b, c, d) {
    let h,
      j; typeof b !== 'string' && (d = c, c = b, b = null); I(c) || (d = c, c = null); !c && H(d) && (c = [], d.length && (d.toString().replace(la, '').replace(ma, (b, d) => { c.push(d) }), c = (d.length === 1 ? ['require'] : ['require', 'exports', 'module']).concat(c))); if (O) { if (!(h = K))P && P.readyState === 'interactive' || M(document.getElementsByTagName('script'), (b) => { if (b.readyState === 'interactive') return P = b }), h = P; h && (b || (b = h.getAttribute('data-requiremodule')), j = E[h.getAttribute('data-requirecontext')]) }(j ? j.defQueue :
R).push([b, c, d])
  }; define.amd = { jQuery: !0 }; j.exec = function (b) { return eval(b) }; j(t)
}
}(this));
