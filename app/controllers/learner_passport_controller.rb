# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

# TODO: eliminate this controller in favor of the generic ReactContentController
# once the legacy grading_periods sub tab is reworked to not need the .scss
# bundles included below with css_bundle

class LearnerPassportController < ApplicationController
  before_action :require_context
  before_action :require_user
  before_action :require_learner_passport_feature_flag

  def self.merge_skills_from_achievements(achievements)
    skills = []
    achievements.each do |achievement|
      skills += achievement[:skills] if achievement[:skills].present?
    end
    skills.uniq! { |s| s[:name] }
    skills
  end

  @@current_achievements = [
    {
      id: "1",
      isNew: true,
      title: "Product Management Short Course",
      issuer: {
        name: "General Assembly",
        url: "https://generalassemb.ly/education/product-management/new-york-city",
        iconUrl:
          "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAxCAYAAACcXioiAAAAAXNSR0IArs4c6QAAAFBlWElmTU0AKgAAAAgAAgESAAMAAAABAAEAAIdpAAQAAAABAAAAJgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAMKADAAQAAAABAAAAMQAAAAD0imuiAAABWWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNi4wLjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YXRpb24+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgoZXuEHAAANI0lEQVRoBcVaC1RUdRr/3WFgROUhojzXBEkzFd+5ls+03bQsn0cr8xGbpa2ulnVszVJrNyuzo65UdnTXzKyzZaWF2WqYq5KGhpiyigIJCJooIO/Xf3/fHa5zZ2BkQs/pO+fOvfP/f/d7v+6d0XCTQGVfGoB1//ZFkOV+hAdHa1MnjHclrTZ/tg8ZObtgCTyAuDElWnhgsivOb/JdJewbqx5foNRdDygV3Uep0VPyyy6pCLMw6khWVzV87GUV01+poeOUivtLgfok8TYzTnOuLc25qcE9XX+Xh2OpxbhwDrBqQG5eiO/y5S9XVKgugqvyr3bH2nV/x8WLbeBVx/1M4OjRyzkThl1sQOtXLniugEq0qu0H7lbxH22Zlay8nfgkHr0fsPjDQnIaFSi7CuxPnGl75PEkNWza13hy3vc4mjQW1RW8jftyBLWLiUw8PN1MR12u7KG2fPWR+udXoeb1610LtSZBlauOWL/5CXz330VIOwlMnPIlnpr2t1R//5zYPfsnYPOHbyA5yRveVgctpYBaWtuHulZVAV5eduUMjOoa4K7h5fjTo3P3Den9zZDTFzpj6yeb8Pm2CLQNPYWxo9doc6fGG+juzp4p8MLaf+HbndORnwtdSO+WQExUHarKs1BSFY3cnxk6JuHdcXNdFyU6xQAtrGeheXdC2ikqyTXxUPtwoPuAqdo7L2xxvc383TOudZZNKK96mELSnCReXQYcT7VAs0RDo6WbI7xIIR7LPCtXnSAe0+kwDBU9B2sJBvY5iXdk2z14lgOL5hxH11vrUCPWEaASwsyLt1sYGjcCElpymI1QUwv06lYZP2pUelOkPVMgKTUU+Rc1PUmbongz9i00UE6edY5W5t8UuQYKqOSsMPXJnnhVqKKh0m2qoGwgvt7xGXLP+eiWMiiKy6urgfJyVh2GlBwVrDI1XHMHtfRgOXHMh6y5gnj19IkAvPfB5zllKlK2VXpeN7V977tKKT8zOlV1wCqV7btg/qYVSDo4D1GRxbhSvQ9B1vvx4zFSoFulRArUSYxS9z79gT8MAUKC9GVknQd27gXSiG+lEAa+7EpYxPa149fxWsCLYZiwBziR4hxCsid50KI1y23b/6HCOwUd/MYjO98Hkya9tGzB9BVLNY2lTQ9mOdlBrfzwHuza/g0y0kiAwnr70MqVPDN3DRDC3i2A5xYCDz9Ixi5OLCP+uk3AO+uJJzfVK13J9UXPA088ZFCyn1/fCLy9GrCRlyuIlwVE0Up6TgzSrRcwM66fNm7wEdly5v7D4YXIOkOhyFmv6SKsSXi5o4ounz4DmDauofCy39IGLJwFjLqXTHUjySqBwnQMtV+aP6PC7ElsXjOuRWA5xGMihyR71llgd+LTBoqzAnMfex8Dh1Sjtt7FBpZxFusHtqHlHzBW7OcartfVW0tWxOhTqKB4Sqwohxd7R9t2dnzzZxTrvSStJyCeiOlxEJPHxBvoTgpog2K3oGePWWgZyH2TQAa2dNaQDkBwW2MFKCwGZjOcnl4OlNLNBsREAaEh7MY0hijuz4LiH2DsOs7tqJS1lV1Jx2rDK51GUA2mjH9ZG9L7gIHgpIC++H3Od/AjMz1RDbT6s6yFCUO60oADqcCu3UzGHcCVK8aqfYTwrscT7wRT+GAxjAv40jNBNIgIeD0Q3gGBtchQSWY0ZwVUsjd6tY/DlUueN6gKJqeFrtWFNXlND516VsK8LYUPZFVxhQCuhQfb5ybXPfN3Ka15570RUPQY1NJrclvVmgQbakpIwReIPzMbB5MW66OCpx3WXCrNDM3Xopc/w6mxWLdR+VCWYQk114JhpiF8yost2L17lfId7YW392xFQQGs2JHQA16l+1FdClzIs6GyxHPrmxnItXkckCpmVq5DpCu243sglZOy3RRIFTp2CEhPewMhoa9A86UCo3s+j3+ss+mVQxA8tbyZmfCWkEk5ySQvkC9MbhpCar+hhFQbdxBO5cx55Q5P1kVGMXLmKRt8RIFzBeN1hl4u9f56RBrsUQOJ82cWccewJJWQsBCGUr2inZ4wnSmIcjIYegzkISWVk7AFl65eQmBYiW4pseKNgEyrMgvpB68FpLr4cHzRS7N9qcGnKCcCeQoip0aFA8KLLHjs4SjcM7E3uvZKcVjPU0oueBIu5kO2pYS2Y/OTKuQOWlFBG8tsU6XUuF/CPLbffjz4SHerNrwbAwpn1IqtT+HypQM4n9W8PGjMe6KMhFYQhWtDId1Ba/aCUPaXMxeZC02Ekkyv0bfV4b6H4rTpg3Mc2HEPVCFSOicZNgd8OAPZODoYh3wX0BVgmZQZSSD3F2DFOuB1TgPn8u1rrVjCw9jMPOEtU21UBHInD9LvdQTehu0+yLnwK5OJNCRtpIKsfZOhQiuKJ6Ten80Fliy1PyO04cAmIJPqc68Aid/YozWZXXzTarYgKicdXpRtCoRXZi4iPt6vY1pV4onW2JUUikPfrkNedjPCRxKKAneLsStgCCAekAokCnaKtK9eKgROpQGt6CmpVmdPs/dcBjpSwTZMZI34TYEk+7kMC77aukG99ulDVmz8MBMnj7RAaQF7unAj4eaACGsGcbWAPPTT5TqEMkx+3x/4Yju/cn0EryPb2/c6UAlPe4GM16nJg5CT/5MVwX7BKMzjzewDYsnmgMTuTg6IE+9lDpj7CYXU+KASxtwS8KH1Xl0M9O7HcKEQk/7oEFq8JPOU2LApEDmlYhWdD7CgQ9ttutX1Z1NP7nahLsSk7ktSSvc1gzDxY/lszenWAD9WnDg+Kzw+kcOdqTJJFbIw7BqrZsa9186UU+Tl+GFBwrFXcWvvStzSuRLywsp4Xr2G7OGFt6OgXbtDH6OpwPVKqIEsY3WgB4ks3d3GaI/qUonILpVWjBl9nNNoJ30atZXORsLXi3H6WDOS2ZDEdJbQas8mJiOzASVlwN4j9nAd3IdTKgUXaM1SKmN1fqY9+e2rzp8ifM8BoMzPoryVfRrV5o1mbQNrHkElL1OFA1mm0hejVpZvECQc2tCqxoONkDv7M5/g5tFAzI0P3gUG97IzkdwJJ+4PFLKxsVpo+frXYeTIhdr0o6uhLaV1SMZ+d/2n1q8aKRc3oA0t4S6UXBNd8l6fgRiTZhA8OULrS6ixl8de403eip4oZQk1QztWJF0s82L9tcgTFl6NooCNhvCy46yArAyLGYqSYu403NIblCSqueHEdgYG0K2T7uPIYErW8iq+kqFSrmO0vDsSEPI59Z1YX+BHCJU1P1MY63IWeYoKvRCtMUQc4CSl2p/6CA4fWY9SNpzG+oEQyTnHjmp6eJfyt+VtYDHDwhwquRS0uAjofIuDm1xlsWQzGnTvZNgj9xqC9ALzK/prG4JP3sWXrfho2xK178e7jC0nBbB24zQc3Outd1ADw3wWIoUXge8OmVcZmz7O30XAbWxWNiaof5DzXoF4gAgybnAkcALpyNLM3JVSKZ1njt+Jj3fMMe5zVqD/HSvRkSOB1HVxv/hZ3n8aIDEttf3Vt/gLTIqx6nyWeWfleuDb3UAEBWrH7muGoit26wvtYuaDGUL44kvGaqObiSJyyPgsckgV6siCOXL4KuM2tkYHvPXM4P0LsjPWoKjY/btRGRl+ybFXkiFDWUVYCv34XkfA6d0oBawl080fOzx0tRzIyHbE+QUq8Oa7nFRlNiKUMm+uCU9DNfZudNiwl5aNHXRcx+cHTeoM8naar++WYOTdK7WAM7nqckQfvLLqfSR8QdfQGgZIIkv1EasYLpcckRCQsURA1uW52LhNuNnYbY1K5m5fxJJknjrzh9z5s8ZHttRy5O00f8GZhzFDF2qadlWnz48GChgb5rPadaw7Xlt+hFOg8yt2M9LNvJZY7963CO+tuV1r10qSxi3QZB7AwNh8hLZXTuXTg9uajSIjSGRYTbxqyXp+ffBMgRXxPZCWbnHUaDLQw4dh5K7hXZ+vY1dCUEYOoWeAhGHKCducnTtvNZbcnT1TwFI3naXS286EwsvQ1yO2Dp07ZSCsgzNzd5waW5dnht9FsVfEnEW3HswViqM/2Etk17RG0tHbG7vNvEZVm4aluxJSUFlXgcraQShgGZww+Ussf35G6qNT14SERZ7DL4Uj2OC8nN7tSIKKZSUZpQQao4XBTsq0/E4858nZh16cvySy750JUNYRyMj0R2jHU5g47iXt5T9vNNDdnUm9adB8tSyoxCUqasZ/kJMd98Qdk2esD9WMBrFabfw0mD+MvIDCAgpKK0qFkjfcUTFXkFd+GGE+g5Ce3goVnH9kX8ImKpq/tExZrN09YEO9BDkqv2QUOnfku1nLfG3mfS5zRtNyNhtDZWYOUHeMKFIxvZTq3FepnkOVmrdso/m/EmrGs5+pbncq1YX7gtd7cHq2Ui5t+teLQHPcBEjLDkPPWH/9x48ahk5E2IXyF19c0qKFdkqoa6F+P2HuU39F+/ZXUEuWEYz7Pn2CIj/dy/HzxsCjPuAJi9/q/0L/B7CmkQQDgkqeAAAAAElFTkSuQmCC"
      },
      issuedOn: "2023-10-30",
      expiresOn: "2033-10-30",
      type: "Certificate of Completion",
      criteria:
        "To earn this badge, participants must complete 50 yours of study over 10 weeks, and complete a case study project.",
      skills: [
        { name: "Product Management", verified: true, url: "https://generalassemb.ly/education/product-management" },
        { name: "Product Strategy", verified: false },
        { name: "Market Research", verified: false },
        { name: "User Research", verified: false }
      ],
      imageUrl: nil,
      verifiedBy: "Open Badges"
    },
    {
      id: "2",
      isNew: false,
      title: "B.S. in Computer Science",
      issuer: {
        name: "The Ohio State University",
        url: "https://www.osu.edu/"
      },
      issuedOn: "2020-05-03",
      expiresOn: nil,
      type: "Bachelor of Science",
      skills: [
        { name: "JavaScript", verified: true },
        { name: "SQL", verified: true },
        { name: "React", verified: true },
        { name: "KPIs", verified: true },
      ],
      imageUrl: "https://www.osu.edu/images/osu-logo-blocko.svg",
      verifiedBy: "Open Badges"
    },
    {
      id: "3",
      isNew: false,
      title: "National Merit Scholar",
      issuer: {
        name: "NMSC",
        url: "https://www.nationalmerit.org/"
      },
      issuedOn: "2016-10-03",
      expiresOn: nil,
      imageUrl: "https://www.nationalmerit.org/s/1758/images/logo.png",
      verifiedBy: nil
    },
    {
      id: "4",
      isNew: false,
      title: "CPS High School Diploma",
      issuer: {
        name: "Walnut Hills High School",
        url: "http://www.walnuthillseagles.com/",
        iconUrl: "http://www.walnuthillseagles.com/images/walnut-hills-logo.png"
      },
      issuedOn: "2016-05-27",
      expiresOn: nil,
      imageUrl: "http://www.walnuthillseagles.com/images/walnut-hills-logo.png",
      verifiedBy: nil
    }
  ]

  @@portfolio_sample = {
    id: "1",
    title: "A portfolio of my work",
    blurb: "A generally groovy person you want to know",
    city: "Columbus",
    state: "OH",
    phone: "888-555-1212",
    email: "me@example.com",
    heroImageUrl:
      "https://images.unsplash.com/photo-1464802686167-b939a6910659?q=80&w=3500&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
    about: %(
    I am a recent computer science graduate from Ohio State University, and have also completed a General Assembly certification
   in Product Management. I bring a strong technical foundation from my computer science degree and have a deep passion for product
     management. My unique blend of technical skills and product management knowledge allows me to bridge the gap between
     technology and business strategy. I am eager to grow and contribute in my first role as a product manager and am committed to
     continuous learning.
),
    skills: merge_skills_from_achievements(@@current_achievements),
    links: %w[https://linkedin.com/in/eschiebel https://www.nspe.org https://eschiebel.github.io/],
    education: [
      {
        id: "1",
        title: "Product Management Certificate",
        city: "Raleigh",
        state: "NC",
        institution: "General Assembly",
        from_date: "2023-04",
        to_date: "2023-10",
        gpa: "3.8"
      },
      {
        id: "2",
        title: "Bachelor's in Computer Science",
        institution: "The Ohio State University",
        city: "Columbus",
        state: "OH",
        from_date: "2018-09",
        to_date: "2022-05",
        gpa: "3.8"
      },
      {
        id: "3",
        title: "High School Diploma",
        institution: "Walnut Hills High School",
        city: "Cincinnati",
        state: "OH",
        from_date: "2004-09",
        to_date: "2018-05",
        gpa: "3.7"
      }
    ],
    experience: [
      {
        id: "1",
        where: "Pendo",
        title: "Software Engineering Team",
        from_date: "2023-08",
        to_date: "2023-10",
        description: %(
          <div style="font-weight: bold">Feature Development</div>
          <ul>
          <li>
          Collaborate with the engineering team to create and maintain customer-facing features using technologies like Vue, Vuex, Highcharts, Jest, and Cypress.
          </li><li>
          Work on various aspects of Pendo's Guide product, including Guide Building, Guide Management, Guide Analytics, and Guide Display.
          </li>
          </ul>
          <div style="font-weight: bold">Technical Stack</div>
          <ul><li>
          Utilize technologies such as Vue2, Cypress, Jest, and JavaScript to develop and maintain features.
          </li><li>
          Focus on ensuring a high-quality product through unit testing and automation.
          </li></ul>
          <div style="font-weight: bold">Process Imaprovement</div>
          <ul><li>
          Contribute to enhancing the Continuous Integration/Continuous Delivery (CI/CD) processes, reducing manual effort for releases.
          </li></ul>
          <div style="font-weight: bold">Collaboration and Code Review</div>
          <ul><li>
          Collaborate closely with other team members through activities like pair programming and code reviews.
          </li><li>
          Provide technical guidance to teammates through code and design reviews.
          </li></ul>
          <div style="font-weight: bold">Problem Solving</div>
          <ul><li>
          Help diagnose and troubleshoot customer issues in real-time during customer calls.
          </li><li>
          Participate in cross-team initiatives aimed at improving technology and work culture.
          </li></ul>
        ).html_safe,
      },
      {
        id: "2",
        where: "Instructure",
        title: "Software Engineering Intern",
        from_date: "2022-08",
        to_date: "2023-08",
        description: %(
          <p>I did some cool stuff here.</p>
        ).html_safe,
      },
    ],
    projects: [],
    achievements: @@current_achievements.first(2).clone
  }

  @@portfolio_template = {
    id: "",
    title: "",
    blurb: "",
    city: "",
    state: "",
    phone: "",
    email: "",
    heroImageUrl: "",
    about: "",
    skills: merge_skills_from_achievements(@@current_achievements),
    links: [],
    education: @@portfolio_sample[:education].clone,
    experience: @@portfolio_sample[:experience].clone,
    projects: @@portfolio_sample[:projects].clone,
    achievements: [],
  }

  @@current_portfolios = [@@portfolio_sample.clone]

  @@project_template = {
    id: "",
    title: "",
    heroImageUrl: "",
    description: "",
    skills: [],
    attachments: [],
    links: [],
    achievements: [],
  }

  @@project_sample = {
    id: "1",
    title: "Project 1",
    heroImageUrl: "https://images.unsplash.com/photo-1464802686167-b939a6910659?q=80&w=3500&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
    description: %(
      Over the last four months, we had the opportunity to collaborate with 99P Labs for our graduate program’s
      (<a href="https;//wikipedia.com">Master of Science in Product Management</a>) semester-long capstone project. We were delighted to work on a
      really exciting problem that helped us hone some of the key concepts that we had learned as a part of our curriculum,
      such as analyzing KPIs, writing user stories, conducting user research, and prototyping. Our problem statement
      was to increase organic engagement for the developer portal of 99P Labs (<a href="https://developer.99plabs.io/home/">
      https://developer.99plabs.io/home/</a>).
    ).html_safe,
    skills: merge_skills_from_achievements(@@current_achievements),
    attachments: [
      {
        id: "1",
        filename: "99b White Paper.pdf",
        size: "1.2 MB",
        contentType: "application/pdf",
        url: "http://localhost:3000/courses/2/files/11",
      },
      {
        id: "2",
        filename: "plain text.txt",
        size: "5 KB",
        contentType: "text/plain",
        url: "https://filesamples.com/samples/document/txt/sample3.txt"
      }
    ],
    links: %w[https://linkedin.com/in/eschiebel https://www.nspe.org https://eschiebel.github.io/],
    achievements: @@current_achievements.first(1).clone,
  }

  @@current_projects = []

  def index
    js_env[:FEATURES][:learner_passport] = @domain_root_account.feature_enabled?(:learner_passport)

    # hide the breadcrumbs application.html.erb renders
    render html: "<style>.ic-app-nav-toggle-and-crumbs.no-print {display: none;}</style>".html_safe,
           layout: true
  end

  def skills_index
    render json: LearnerPassportController.merge_skills_from_achievements(@@current_achievements)
  end

  def achievements_index
    render json: @@current_achievements
  end

  ######## Portfolios ########

  def portfolios_index
    render json: @@current_portfolios.map { |p| p.slice(:id, :title, :heroImageUrl) }
  end

  def portfolio_create
    new_portfolio = @@portfolio_template.clone
    new_portfolio[:id] = (@@current_portfolios.length + 1).to_s
    new_portfolio[:title] = params[:title]
    new_portfolio[:phone] = @current_user.phone || ""
    new_portfolio[:email] = @current_user.email || ""
    @@current_portfolios << new_portfolio
    render json: new_portfolio
  end

  def portfolio_update
    portfolio = @@current_portfolios.find { |p| p[:id] == params[:portfolio_id] }
    return render json: { message: "Portfolio not found" }, status: :not_found if portfolio.nil?

    portfolio[:skills] = []
    portfolio.each do |key, _value|
      next if params[key].nil?

      case key
      when :skills
        params[key].each do |skill|
          portfolio[:skills] << JSON.parse(skill)
        end
      when :education
        portfolio[:education] = JSON.parse(params[:education])
      when :experience
        portfolio[:experience] = JSON.parse(params[:experience])
      when :achievements
        portfolio[:achievements] = @@current_achievements.select { |a| params[key].include?(a[:id]) }
      else
        portfolio[key] = params[key]
      end
    end

    render json: portfolio
  end

  def portfolio_show
    portfolio = @@current_portfolios.find { |p| p[:id] == params[:portfolio_id] }
    return render json: { message: "Portfolio not found" }, status: :not_found if portfolio.nil?

    render json: portfolio
  end

  def portfolio_duplicate
    portfolio = @@current_portfolios.find { |p| p[:id] == params[:portfolio_id] }
    new_portfolio = portfolio.clone
    new_portfolio[:id] = (@@current_portfolios.length + 1).to_s
    @@current_portfolios << new_portfolio
    render json: @@current_portfolios.last
  end

  def portfolio_edit
    portfolio = @@current_portfolios.find { |p| p[:id] == params[:portfolio_id] }
    return render json: { message: "Portfolio not found" }, status: :not_found if portfolio.nil?

    render json: portfolio
  end

  ###### Projects ######
  def projects_index
    render json: @@current_projects.map { |p| p.slice(:id, :title, :heroImageUrl) }
  end

  def project_create
    new_project = @@project_template.clone
    new_project[:id] = (@@current_projects.length + 1).to_s
    new_project[:title] = params[:title]
    @@current_projects << new_project
    render json: new_project
  end

  def project_update
    project = @@current_projects.find { |p| p[:id] == params[:project_id] }
    return render json: { message: "Project not found" }, status: :not_found if project.nil?

    render json: project
  end

  def project_show
    project = @@current_projects.find { |p| p[:id] == params[:project_id] }
    return render json: { message: "Project not found" }, status: :not_found if project.nil?

    render json: project
  end

  def project_duplicate
    project = @@projectfolios.find { |p| p[:id] == params[:project_id] }
    new_project = project.clone
    new_project[:id] = (@@current_projects.length + 1).to_s
    @@current_projects << new_project
    render json: @@current_projects.last
  end

  def project_edit
    project = @@current_projects.find { |p| p[:id] == params[:project_id] }
    return render json: { message: "Project not found" }, status: :not_found if project.nil?

    render json: project
  end

  def reset
    @@current_portfolios = [@@portfolio_sample.clone]
    @@current_projects = [@@project_sample.clone]

    render json: { message: "Portfolios reset" }, status: :accepted
  end

  private

  def require_learner_passport_feature_flag
    unless @domain_root_account.feature_enabled?(:learner_passport)
      render status: :not_found, template: "shared/errors/404_message"
    end
  end
end
