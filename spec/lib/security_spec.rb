#
# Copyright (C) 2014 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public
# License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with this program. If not, see
# <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe "security" do
  it "verify_hmac_sha1" do
    msg = "sign me"
    hmac = Canvas::Security.hmac_sha1(msg)

    expect(Canvas::Security.verify_hmac_sha1(hmac, msg)).to be_truthy
    expect(Canvas::Security.verify_hmac_sha1(hmac, msg + "haha")).not_to be_truthy
  end
end
