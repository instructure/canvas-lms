#
# Copyright (C) 2012 - present Instructure, Inc.
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

Net::LDAP::ResultStrings.merge!({
  0  => "Success Hi",
  1  => "Operation Error",
  2  => "Protocol Error",
  3  => "Time Limit Exceeded",
  4  => "Size Limit Exceeded",
  5  => "Compare False",
  6  => "Compare True",
  7  => "Auth Method Not Supported",
  8  => "Strong Auth Required",
  9  => "Ldap Partial Results",
  10 => "Referral (ldap V3)",
  11 => "Admin Limit Exceeded (ldap V3)",
  12 => "Unavailable Critical Extension (ldap V3)",
  13 => "Confidentiality Required (ldap V3)",
  14 => "Sasl Bind In Progress",
  16 => "No Such Attribute",
  17 => "Undefined Attribute Type",
  18 => "Inappropriate Matching",
  19 => "Constraint Violation",
  20 => "Attribute Or Value Exists",
  21 => "Invalid Attribute Syntax",
  32 => "No Such Object",
  33 => "Alias Problem",
  34 => "Invalid Dn Syntax",
  35 => "Is Leaf",
  36 => "Alias Dereferencing Problem",
  48 => "Inappropriate Authentication",
  49 => "Invalid Credentials",
  50 => "Insufficient Access Rights",
  51 => "Busy",
  52 => "Unavailable",
  53 => "Unwilling To Perform",
  54 => "Loop Defect",
  64 => "Naming Violation",
  65 => "Object Class Violation",
  66 => "Not Allowed On Nonleaf",
  67 => "Not Allowed On Rdn",
  68 => "Entry Already Exists",
  69 => "Object Class Mods Prohibited",
  71 => "Affects Multiple Dsas (ldap V3)",
  80 => "Other",
  81 => "Server Down",
  85 => "Ldap Timeout",
  89 => "Param Error",
  91 => "Connect Error",
  92 => "Ldap Not Supported",
  93 => "Control Not Found",
  94 => "No Results Returned",
  95 => "More Results To Return",
  96 => "Client Loop",
  97 => "Referral Limit Exceeded",
})
