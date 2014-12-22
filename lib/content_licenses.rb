#
# Copyright (C) 2014 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module ContentLicenses
  def self.included(base)
    base.extend ContentLicenses::ClassMethods
  end

  module ClassMethods
    def licenses
      ActiveSupport::OrderedHash[
          'private',
          {
              :readable_license => t('#cc.private', 'Private (Copyrighted)'),
              :license_url => "http://en.wikipedia.org/wiki/Copyright"
          },
          'cc_by_nc_nd',
          {
              :readable_license => t('#cc.by_nc_nd', 'CC Attribution Non-Commercial No Derivatives'),
              :license_url => "http://creativecommons.org/licenses/by-nc-nd/4.0/"
          },
          'cc_by_nc_sa',
          {
              :readable_license => t('#cc.by_nc_sa', 'CC Attribution Non-Commercial Share Alike'),
              :license_url => "http://creativecommons.org/licenses/by-nc-sa/4.0"
          },
          'cc_by_nc',
          {
              :readable_license => t('#cc.by_nc', 'CC Attribution Non-Commercial'),
              :license_url => "http://creativecommons.org/licenses/by-nc/4.0"
          },
          'cc_by_nd',
          {
              :readable_license => t('#cc.by_nd', 'CC Attribution No Derivatives'),
              :license_url => "http://creativecommons.org/licenses/by-nd/4.0"
          },
          'cc_by_sa',
          {
              :readable_license => t('#cc.by_sa', 'CC Attribution Share Alike'),
              :license_url => "http://creativecommons.org/licenses/by-sa/4.0"
          },
          'cc_by',
          {
              :readable_license => t('#cc.by', 'CC Attribution'),
              :license_url => "http://creativecommons.org/licenses/by/4.0"
          },
          'public_domain',
          {
              :readable_license => t('#cc.public_domain', 'Public Domain'),
              :license_url => "http://en.wikipedia.org/wiki/Public_domain"
          },
      ]
    end

    def public_license?(license)
      license != 'private'
    end
  end
end