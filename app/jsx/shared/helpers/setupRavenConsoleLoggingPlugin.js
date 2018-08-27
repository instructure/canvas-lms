/*
 * Copyright (C) 2018 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

/**
 *
 * @param {RavenClient} client This should be the Raven client
 * @param {Object} options Options for the plugin
 * @param {string} options.loggerName Name for the logger
 */
export default function setupRavenConsoleLoggingPlugin(client, options) {
  const CONSOLE_LEVELS = ['debug', 'info', 'warn', 'error'];
  CONSOLE_LEVELS.forEach(level => {
    window.console[level] = (...args) => {
      const msg = args.join(' ');
      if (msg.includes('deprecated')) {
        const data = {
          level: level === 'warn' ? 'warning' : level,
          logger: options.loggerName || 'console',
          stacktrace: true,
          extra: {
            arguments: args,
          }
        };

        client.captureMessage(msg, data);
      }
    }
  });
};
