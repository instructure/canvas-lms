# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

# it's standard practice to ignore parts of the project
# that intentionally don't follow the zeitwerk pattern
# because they do something like monkeypatch a constant
# defined elsewhere https://github.com/fxn/zeitwerk#use-case-files-that-do-not-follow-the-conventions.
#
# these extensions are required explicitly by the gem engine when it's ready to patch,
# so that they can modify constants defined in a third party gem,
# and so don't need to be autoloaded
Rails.autoloaders.main.ignore("#{__dir__}/../../lib/academic_benchmark/ab_gem_extensions")
