# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe EquationImagesController do
  describe "#show" do
    it "expects escaped latex" do
      latex = "44%5Cprod%5Cleft%283%5Ccdot3%5Cright%29%5Ctheta"
      get :show, params: { id: latex }
      expect(assigns(:latex)).to eq latex
    end

    it "handles unescaped latex" do
      latex = '44\prod\left(3\cdot3\right)\theta'
      escaped = "44%5Cprod%5Cleft(3%5Ccdot3%5Cright)%5Ctheta"
      get :show, params: { id: latex }
      expect(assigns(:latex)).to eq escaped
    end

    it "encodes `+` signs properly" do
      latex = "5%5E5%5C%3A+%5C%3A%5Csqrt%7B9%7D"
      get :show, params: { id: latex }
      expect(assigns(:latex)).to match(/%2B/)
    end

    it "redirects image requests to codecogs" do
      get "show", params: { id: "foo" }
      expect(response).to redirect_to("http://latex.codecogs.com/svg.latex?foo")
    end

    it "does not include scale param if present" do
      get "show", params: { id: "foo", scale: 2 }
      expect(response).to redirect_to("http://latex.codecogs.com/svg.latex?foo")
    end

    context "when using MathMan" do
      let(:service_url) { "http://get.mml.com" }

      before { allow(MathMan).to receive_messages(url_for: service_url, use_for_svg?: true) }

      it "redirects to service_url" do
        get :show, params: { id: "5" }
        expect(response).to redirect_to(/#{service_url}/)
      end

      it "includes the scale param if present" do
        get :show, params: { id: "5", scale: 2 }
        expect(MathMan).to have_received(:url_for).with(latex: "5", target: :svg, scale: "2")
      end
    end
  end
end
