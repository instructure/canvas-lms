/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

(function() {
  function answeredConsent() {
    return (
      typeof localStorage !== 'undefined' &&
      ( localStorage.getItem('canvas_api_doc_consent_accepted') === 'true' ||
        localStorage.getItem('canvas_api_doc_consent_accepted') === 'false' )
    )
  }

  function acceptConsent() {
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem('canvas_api_doc_consent_accepted', 'true');
    }
    hideBanner();
  }

  function rejectConsent() {
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem('canvas_api_doc_consent_accepted', 'false');
    }
    hideBanner();
  }

  function hideBanner() {
    const banner = document.getElementById('cookie-consent-banner');
    if (banner) {
      banner.style.display = 'none';
    }
  }

  function showBanner() {
    const banner = document.createElement('div');
    banner.id = 'cookie-consent-banner';
    banner.innerHTML = `
      <div class="cookie-consent-content">
        <p>This documentation uses cookies to enhance your browsing experience.
          By clicking "Accept", you consent to the use of cookies in accordance with our
          <a href="https://www.instructure.com/policies/marketing-privacy">privacy policy</a>.
        </p>
        <button id="accept-cookies">Accept</button>
        <button id="reject-cookies">Reject</button>
      </div>
    `;
    document.body.appendChild(banner);

    document.getElementById('accept-cookies').addEventListener('click', acceptConsent);
    document.getElementById('reject-cookies').addEventListener('click', rejectConsent);
  }

  document.addEventListener('DOMContentLoaded', function() {
    if (!answeredConsent()) {
      showBanner();
    }
  });
})();