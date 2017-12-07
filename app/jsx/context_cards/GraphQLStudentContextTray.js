import $ from 'jquery'
import _ from 'underscore'
import React from 'react'
import {ApolloProvider, ApolloClient, createNetworkInterface, gql, graphql} from 'react-apollo'
import StudentContextTray from 'jsx/context_cards/StudentContextTray'

const client = new ApolloClient({
  networkInterface: createNetworkInterface({
    uri: '/api/graphql',
    opts: {
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': $.cookie('_csrf_token') // TODO: probably need to move this io a middleware (http://dev.apollodata.com/core/network.html)
      },
      credentials: 'same-origin'
    }
  })
})

/*
 * TODO: is loading grades or enrollments slowing this query way down?
 */
const GraphQLStudentContextCard = graphql(
  gql`
    query StudentContextCard($courseId: ID!, $studentId: ID!) {
      course: legacyNode(type: Course, _id: $courseId) {
        ... on Course {
          _id
          name
          permissions {
            become_user: becomeUser
            manage_grades: manageGrades
            send_messages: sendMessages
            view_all_grades: viewAllGrades
            view_analytics: viewAnalytics
          }
          usersConnection(userIds: [$studentId]) {
            edges {
              node {
                _id
                short_name: shortName
                avatar_url: avatarUrl
                enrollments(courseId: $courseId) {
                  last_activity_at: lastActivityAt
                  section {
                    name
                  }
                  grades {
                    current_grade: currentGrade
                    current_score: currentScore
                  }
                }
                analytics: summaryAnalytics(courseId: $courseId) {
                  page_views: pageViews {
                    total
                    max
                    level
                  }
                  participations {
                    total
                    max
                    level
                  }
                  tardiness_breakdown: tardinessBreakdown {
                    late
                    missing
                    on_time: onTime
                  }
                }
              }
            }
          }
          submissionsConnection(
            first: 10
            orderBy: [{field: gradedAt, direction: descending}]
            studentIds: [$studentId]
          ) {
            edges {
              submission: node {
                id
                score
                grade
                excused
                user {
                  _id
                }
                assignment {
                  name
                  html_url: htmlUrl
                  points_possible: pointsPossible
                }
              }
            }
          }
        }
      }
    }
  `,
  {
    options: props => ({
      variables: {
        courseId: props.courseId,
        studentId: props.studentId
      }
    }),

    // move user to top-level
    props: props => {
      const {course} = props.data
      let edge, user
      if (course && (edge = course.usersConnection.edges[0])) {
        user = edge.node
        return {
          ...props,
          data: {
            ...props.data,
            course: _.omit(course, 'usersConnection'),
            user
          }
        }
      } else {
        return props
      }
    }
  }
)(StudentContextTray)

export default props => {
  return (
    <ApolloProvider client={client}>
      <GraphQLStudentContextCard {...props} />
    </ApolloProvider>
  )
}
