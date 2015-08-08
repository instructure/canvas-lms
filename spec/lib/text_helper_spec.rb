# encoding: UTF-8
#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe TextHelper do

  class TestClassForMixins
    extend TextHelper
    def self.t(*args)
      I18n.t(*args)
    end
  end

  def th
    TestClassForMixins
  end

  context "datetime_string" do
    it "formats datetimes" do
      datetime = Time.zone.parse("#{Time.zone.now.year}-01-01 12:00:00")
      expect(th.datetime_string(datetime)).to eq "Jan 1 at 12pm"
    end
  end

  context "time_string" do
    before { Timecop.freeze(Time.utc(2010, 8, 18, 12, 21)) }
    after { Timecop.return }

    it "should be formatted properly" do
      time = Time.zone.now
      time += 1.minutes if time.min == 0
      expect(th.time_string(time)).to eq I18n.l(time, :format => :tiny)
    end

    it "should omit the minutes if it's on the hour" do
      time = Time.zone.now
      time -= time.min.minutes
      expect(th.time_string(time)).to eq I18n.l(time, :format => :tiny_on_the_hour)
    end

    it "accepts a timezone override" do
      time = Time.zone.now
      mountain = th.time_string(time, nil, ActiveSupport::TimeZone["America/Denver"])
      central = th.time_string(time, nil, ActiveSupport::TimeZone["America/Chicago"])
      expect(mountain).to eq " 6:21am"
      expect(central).to eq " 7:21am"
    end

  end

  context "date_string" do

    it "should return correct date before the year 1000" do
      old_date = Time.zone.parse("0900-01-01")
      expect(th.date_string(old_date)).to eq "Jan 1, 0900"
    end

    it "should include the year if the current year isn't the same" do
      today = Time.zone.now
      # cause we don't want to deal with day-of-the-week stuff, offset 8 days
      if today.year == (today + 8.days).year
        today += 8.days
      else
        today -= 8.days
      end
      nextyear = today.advance(:years => 1)
      datestring = th.date_string nextyear
      expect(datestring.split[2].to_i).to eq nextyear.year
      expect(th.date_string(today).split.size).to eq(datestring.split.size - 1)
    end

    it "should say the Yesterday/Today/Tomorrow if it's yesterday/today/tomorrow" do
      today = Time.zone.now
      tommorrow = today + 1.day
      yesterday = today - 1.day
      expect(th.date_string(today)).to eq "Today"
      expect(th.date_string(tommorrow)).to eq "Tomorrow"
      expect(th.date_string(yesterday)).to eq "Yesterday"
    end

    it "should not say the day of the week if it's exactly a few years away" do
      aday = Time.zone.now + 2.days
      nextyear = aday.advance(:years => 1)
      expect(th.date_string(aday)).to eq aday.strftime("%A")
      expect(th.date_string(nextyear)).not_to eq nextyear.strftime("%A")
      # in fact,
      expect(th.date_string(nextyear).split[2].to_i).to eq nextyear.year
    end

    it "should ignore the end date if it matches the start date" do
      start_date = Time.parse("2012-01-01 12:00:00")
      end_date = Time.parse("2012-01-01 13:00:00")
      expect(th.date_string(start_date, end_date)).to eq th.date_string(start_date)
    end

    it "should do date ranges if the end date differs from the start date" do
      start_date = Time.parse("2012-01-01 12:00:00")
      end_date = Time.parse("2012-01-08 12:00:00")
      expect(th.date_string(start_date, end_date)).to eq "#{th.date_string(start_date)} to #{th.date_string(end_date)}"
    end
  end

  context "truncate_html" do
    it "should truncate in the middle of an element" do
      str = "<div>a b c d e</div>"
      expect(th.truncate_html(str, :num_words => 3)).to eq "<div>a b c<span>...</span>\n</div>"
    end

    it "should truncate at the end of an element" do
      str = "<div><div>a b c</div>d e</div>"
      expect(th.truncate_html(str, :num_words => 3)).to eq "<div><div>a b c<span>...</span>\n</div></div>"
    end

    it "should truncate at the beginning of an element" do
      str = "<div>a b c<div>d e</div></div>"
      expect(th.truncate_html(str, :num_words => 3)).to eq "<div>a b c<span>...</span>\n</div>"
    end
  end

  it "should insert reply to into subject" do
    expect(TextHelper.make_subject_reply_to('ohai')).to eq 'Re: ohai'
    expect(TextHelper.make_subject_reply_to('Re: ohai')).to eq 'Re: ohai'
  end

  context "markdown" do
    context "safety" do
      it "should escape Strings correctly" do
        str = "`a` **b** _c_ ![d](e)\n# f\n + g\n - h"
        expected = "\\`a\\` \\*\\*b\\*\\* \\_c\\_ \\!\\[d\\]\\(e\\)\n\\# f\n \\+ g\n \\- h"
        expect(escaped = th.markdown_escape(str)).to eq expected
        expect(th.markdown_escape(escaped)).to eq expected
      end
    end
    context "i18n" do
      it "should automatically escape Strings" do
        expect(th.mt(:foo, "We **do not** trust the following input: %{input}", :input => "`a` **b** _c_ ![d](e)\n# f\n + g\n - h")).
          to eq "We <strong>do not</strong> trust the following input: `a` **b** _c_ ![d](e) # f + g - h"
      end

      it "should not escape MarkdownSafeBuffers" do
        expect(th.mt(:foo, "We **do** trust the following input: %{input}", :input => th.markdown_safe("`a` **b** _c_ ![d](e)\n# f\n + g\n - h"))).
          to eq <<-HTML.strip
<p>We <strong>do</strong> trust the following input: <code>a</code> <strong>b</strong> <em>c</em> <img src="e" alt="d" /></p>

<h1>f</h1>

<ul>
<li>g</li>
<li>h</li>
</ul>
        HTML
      end

      it "should inlinify single paragraphs by default" do
        expect(th.mt(:foo, "**this** is a test")).
          to eq "<strong>this</strong> is a test"

        expect(th.mt(:foo, "**this** is another test\n\nwhat will happen?")).
          to eq "<p><strong>this</strong> is another test</p>\n\n<p>what will happen?</p>"
      end

      it "should not inlinify single paragraphs if :inlinify => :never" do
        expect(th.mt(:foo, "**one** more test", :inlinify => :never)).
          to eq "<p><strong>one</strong> more test</p>"
      end

      it "should allow wrapper with markdown" do
        expect(th.mt(:foo, %{Dolore jerky bacon officia t-bone aute magna. Officia corned beef et ut bacon.

Commodo in ham, *short ribs %{name} pastrami* sausage elit sunt dolore eiusmod ut ea proident ribeye.

Ad dolore andouille meatball irure, ham hock tail exercitation minim ribeye sint quis **eu short loin pancetta**.},
        :name => '<b>test</b>'.html_safe,
        :wrapper => {
          '*' => '<span>\1</span>',
          '**' => '<a>\1</a>',
        })).to eq "<p>Dolore jerky bacon officia t-bone aute magna. Officia corned beef et ut bacon.</p>\n\n<p>Commodo in ham, <span>short ribs <b>test</b> pastrami</span> sausage elit sunt dolore eiusmod ut ea proident ribeye.</p>\n\n<p>Ad dolore andouille meatball irure, ham hock tail exercitation minim ribeye sint quis <a>eu short loin pancetta</a>.</p>"
      end

      it "should inlinify complex single paragraphs" do
        expect(th.mt(:foo, "**this** is a *test*")).
          to eq "<strong>this</strong> is a <em>test</em>"

        expect(th.mt(:foo, "*%{button}*", :button => '<button type="submit" />'.html_safe, :wrapper => '<span>\1</span>')).
          to eq '<span><button type="submit" /></span>'
      end

      it "should not inlinify multiple paragraphs" do
        expect(th.mt(:foo, "para1\n\npara2")).
          to eq "<p>para1</p>\n\n<p>para2</p>"
      end
    end
  end
end
