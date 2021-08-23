#! /bin/sh
# Copyright (C) 2019 - present Instructure, Inc.
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
#

# Figure out how to invoke the current user's browser.
# See: https://dwheeler.com/essays/open-files-urls.html
viewer=FAIL
for possibility in open start xdg-open gnome-open cygstart; do
  if command -v "$possibility" >/dev/null 2>&1 ; then
    viewer="$possibility"
    break
  fi
done
if [ "$viewer" = FAIL ] ; then
  echo 'No viewer found.' >&2
  exit 1
fi

DEMO_PATH="file:///$INIT_CWD/github-pages/index.html"

# Now $viewer is set, so we can use it.
"$viewer" $DEMO_PATH