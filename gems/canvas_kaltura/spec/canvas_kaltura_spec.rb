# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe CanvasKaltura do
  describe ".timeout_protector" do
    subject(:run_with_timeout_protector) { CanvasKaltura.with_timeout_protector { 2 } }

    around do |example|
      CanvasKaltura.timeout_protector_proc = timeout_protector_proc
      example.run
      CanvasKaltura.timeout_protector_proc = nil
    end

    context "when call block if not set" do
      let(:timeout_protector_proc) { nil }

      it { expect(run_with_timeout_protector).to be 2 }
    end

    context "when call timeout protector if set" do
      let(:timeout_protector_proc) { proc { 27 } }

      it { expect(run_with_timeout_protector).to be 27 }
    end
  end
end
