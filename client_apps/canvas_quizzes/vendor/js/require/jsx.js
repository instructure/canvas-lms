/**
 * @license The MIT License (MIT)
 *
 * Copyright (c) 2014 Felipe O. Carvalho
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
define(['JSXTransformer', 'text'], (JSXTransformer, text) => {
  const buildMap = {};
  const jsx = {
    version: '0.2.1',

    load (name, req, onLoadNative, config) {
      let fileExtension = config.jsx && config.jsx.fileExtension || '.js';
      let fileName = name;
      let moduleId;

      const onLoad = function (content) {
        if (config.isBuild) {
          buildMap[name] = content;
          onLoadNative.fromText(name, content);
        } else {
          try {
            if (content.indexOf('@jsx React.DOM') === -1) {
              content = `/** @jsx React.DOM */\n${content}`;
            }
            content = JSXTransformer.transform(content).code;
          } catch (err) {
            onLoadNative.error(err);
          }

          content += `\n//# sourceURL=${location.protocol}//${location.hostname
            }${config.baseUrl}${name}${fileExtension}`;

          onLoadNative.fromText(content);
        }
      };

      if (config.isBuild) {
        moduleId = '';
        fileExtension = '.js';

        if (config.jsx) {
          moduleId = config.jsx.moduleId || '';
        }

        if (moduleId.length) {
          fileName = `${moduleId}/${
            fileName
              .replace(moduleId, '')
              .replace(/^\//, '')}`;
        }
      }

      fileName += fileExtension;

      // console.log('Loading JSX file "' + fileName + '" (relative to: "' + config.baseUrl + '")');

      text.load(fileName, req, onLoad, config);
    },

    write (pluginName, moduleName, write) {
      if (buildMap.hasOwnProperty(moduleName)) {
        const content = buildMap[moduleName];
        write.asModule(moduleName, content);
      }
    }
  };

  return jsx;
});
