/*
 * Copyright (C) 2018 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

const FAKE_TIMEOUT = process.env.NODE_ENV === 'test' ? 0 : 500

const PAGES = {
  // page of announcements
  announcements: {
    links: [
      {
        href: '/courses/1/announcements',
        title: 'Announcements List',
        date: '2018-04-22T13:00:00Z',
        date_type: 'posted',
      },
      {
        href: '/courses/1/announcements/2',
        title: 'Announcement 2',
        date: '2018-04-22T13:00:00Z',
        date_type: 'delayed_post',
      },
      {href: '/courses/1/announcements/1', title: 'Announcement 1'},
    ],
    bookmark: null,
  },

  // first page of assignments
  assignments: {
    links: [
      {
        href: '/courses/1/assignments',
        title: 'Assignment List',
        published: true,
        date: '2018-04-22T13:00:00Z',
        date_type: 'due',
      },
      {
        href: '/courses/1/assignments/1',
        title: 'Assignment 1',
        published: false,
        date: '2018-04-22T13:00:00Z',
        date_type: 'due',
      },
      {
        href: '/courses/1/assignments/2',
        title: 'Assignment 2',
        published: false,
        date: null,
        date_type: null,
      },
      {
        href: '/courses/1/assignments/3',
        title: 'Assignment 3',
        published: true,
        date: '2018-04-22T13:00:00Z',
        date_type: 'due',
      },
      {href: '/courses/1/assignments/4', title: 'Quiz 1', published: true},
    ],
    // refers to second page of assignments
    bookmark: 'assignments2',
  },

  // second page of assignments
  assignments2: {
    links: [
      {
        href: '/courses/1/assignments/5',
        title: 'Quiz 2',
        published: false,
        date: '2018-04-22T13:00:00Z',
        date_type: 'due',
      },
      {
        href: '/courses/1/assignments/6',
        title: 'Quiz 3',
        published: true,
        date: '2018-04-22T13:00:00Z',
        date_type: 'due',
      },
    ],
    bookmark: null,
  },

  // page of discussions
  discussions: {
    links: [
      {
        href: '/courses/1/discussion_topics',
        title: 'Discussion Index',
        published: false,
        date: '2018-04-22T13:00:00Z',
        date_type: 'due',
      },
      {
        href: '/courses/1/discussion_topics/4',
        title: 'Discussion 2',
        published: true,
        date: '2018-04-22T13:00:00Z',
        date_type: 'todo',
      },
      {
        href: '/courses/1/discussion_topics/3',
        title: 'Discussion 1',
        published: true,
        date: '2018-04-22T13:00:00Z',
        date_type: 'todo',
      },
      {
        href: '/courses/1/discussion_topics/2',
        title: 'Announcement 2',
        published: false,
        date: null,
        date_type: null,
      },
      {
        href: '/courses/1/discussion_topics/1',
        title: 'Announcement 1',
        published: true,
        date: '2018-04-22T13:00:00Z',
        date_type: 'due',
      },
    ],
    // intentionally referring to page that doesn't exist to test failure mode
    bookmark: 'discussions2',
  },

  // page of modules
  modules: {
    links: [
      {
        href: '/courses/1/modules',
        title: 'Modules List',
        published: true,
        date: '2018-04-22T13:00:00Z',
        date_type: 'published',
      },
      {
        href: '/courses/1/modules/2',
        title: 'Module 2',
        published: false,
        date: null,
        date_type: 'published',
      },
      {
        href: '/courses/1/modules/1',
        title: 'Module 1',
        published: true,
        date: '2018-04-22T13:00:00Z',
        date_type: 'published',
      },
    ],
    bookmark: null,
  },

  // page of quizzes
  quizzes: {
    links: [],
    bookmark: null,
  },

  // page of wiki pages
  wikiPages: {
    links: [
      {
        href: '/courses/1/pages/wiki-page-1',
        title: 'Wiki Page 1',
        published: true,
        date: '2018-04-22T13:00:00Z',
        date_type: 'todo',
      },
      {
        href: '/courses/1/pages/wiki-page-2',
        title: 'Wiki Page 2',
        published: false,
        date: null,
        date_type: 'todo',
      },
    ],
    bookmark: null,
  },

  // root files
  files: {
    files: [
      {
        id: 1,
        type: 'text/plain',
        name: 'File 1',
        url: '/files/1',
      },
      {
        id: 2,
        type: 'text/plain',
        name: 'File 2',
        url: '/files/2',
      },
    ],
    bookmark: 'files2',
  },

  // root files page 2
  files2: {
    files: [
      {
        id: 3,
        type: 'text/plain',
        name: 'File 3',
        url: '/files/3',
      },
    ],
    bookmark: null,
  },

  // files in folder 1
  folder1files: {
    files: [
      {
        id: 4,
        type: 'text/plain',
        name: 'File 4',
        url: '/files/4',
      },
      {
        id: 5,
        type: 'text/plain',
        name: 'File 5',
        url: '/files/5',
      },
    ],
    bookmark: null,
  },

  // result for folder with no files
  emptyfiles: {
    files: [],
    bookmark: null,
  },

  // root folders
  folders: {
    folders: [
      {
        id: 1,
        name: 'Folder 1',
        parentId: 42,
        filesUrl: 'folder1files',
        foldersUrl: 'folder1folders',
      },
    ],
    bookmark: 'folders2',
  },

  // root folders page 2
  folders2: {
    folders: [
      {
        id: 2,
        name: 'Folder 2',
        parentId: 42,
        filesUrl: 'emptyfiles',
        foldersUrl: 'emptyfolders',
      },
    ],
    bookmark: null,
  },

  // sub folders for folder 1
  folder1folders: {
    folders: [
      {
        id: 3,
        name: 'Folder 1 Sub',
        parentId: 1,
        filesUrl: 'emptyfiles',
        foldersUrl: 'emptyfolders',
      },
    ],
    bookmark: null,
  },

  // folders result for a folder with no sub folders
  emptyfolders: {
    folders: [],
    bookmark: null,
  },
}

const FOLDERS = [
  {id: 1, name: 'Folder 1', filesUrl: 'filesurl', foldersUrl: 'foldersurl'},
  {id: 2, name: 'Folder 2', filesUrl: 'filesurl', foldersUrl: 'foldersurl'},
  {id: 3, name: 'Folder 3', filesUrl: 'filesurl', foldersUrl: 'foldersurl'},
]

export function buildImage(index, name, height, width) {
  const id = 123000001 + index
  const url = `https://www.fillmurray.com/${height}/${width}`

  return {
    display_name: name,
    href: url,
    id,
    preview_url: url,
    thumbnail_url: url,
    content_type: 'image/png',
    date: '2023-05-23T20:05:17Z',
    filename: name,
  }
}

const imageNames = ['bill_murray', 'bill_is_the_best', 'bill_who?', 'love_this_guy!!11!']
const images = []
for (let i = 0; i < 30; i++) {
  const name = imageNames[i % imageNames.length] + i + '.jpeg'

  /*
   * This is just to get some variety to the example images.
   * We get some Bills, each with unique dimensions following this pattern:
   * 100x200, 201x101, 302x202, 203x303, 304x404, 405x305,
   * 100x206, 201x107, 302x208, 203x309, 304x410, 405x311, etc.
   */
  const height = [100, 200, 200, 300, 300, 400][i % 6] + i
  const width = [200, 100, 300, 200, 400, 300][i % 6] + Math.round(i / 6)
  images.push(buildImage(i, name, height, width))
}

const brokenImage = {
  id: 123000000,
  display_name: 'broken_image.jpeg',
  filename: 'broken_image.jpeg',
  href: 'http://canvas/files/123000000/download',
  preview_url: 'http://canvas/files/123000000/download',
  thumbnail_url: 'http://does.not/exist.png',
}

const IMAGE_RESPONSES = [
  {
    bookmark: 'http://canvas/images/2',
    files: [images[0], brokenImage, ...images.slice(1, 10)],
  },

  {
    bookmark: 'http://canvas/images/3',
    bookmarkForThis: 'http://canvas/images/2',
    files: images.slice(10, 20),
  },

  {
    bookmark: null,
    bookmarkForThis: 'http://canvas/images/3',
    files: images.slice(20),
  },
]

const FLICKR_RESULTS = {
  go: [
    {
      id: '1',
      href: 'https://farm9.static.flickr.com/8491/8297692520_4e7a43ffcf_s.jpg',
      title: 'Game of Go in our club.',
    },
    {
      id: '2',
      href: 'https://farm1.static.flickr.com/5/7270219_6d3f41bc71_s.jpg',
      title: 'Another game of Go',
    },
    {
      id: '3',
      href: 'https://farm1.static.flickr.com/8/9686480_c726bf6c5d_s.jpg',
      title: 'the fourth game',
    },
  ],
  chess: [
    {
      id: '4',
      href: 'https://farm5.static.flickr.com/4051/4627936161_39df5d616a_s.jpg',
      title: 'Chess.',
    },
    {
      id: '5',
      href: 'https://farm8.static.flickr.com/7428/9646564428_0e359a1092_s.jpg',
      title: 'chess',
    },
    {
      id: '6',
      href: 'https://farm9.static.flickr.com/8309/7961751980_66333f83cf_s.jpg',
      title: 'champion chess',
    },
  ],
}

function makeFiles(bookmark_base, extension, content_type) {
  return {
    [`${bookmark_base}1`]: {
      files: [1, 2, 3].map(i => {
        return {
          id: i,
          filename: `file${i}.${extension}`,
          content_type,
          display_name: `file${i}`,
          href: `http://the.net/${i}`,
          date: `2019-05-25T13:0${i}:00Z`,
        }
      }),
      bookmark: `${bookmark_base}2`,
      hasMore: true,
    },
    [`${bookmark_base}2`]: {
      files: [4, 5, 6].map(i => {
        return {
          id: i,
          filename: `file${i}.${extension}`,
          content_type,
          display_name: `file${i}`,
          href: `http://the.net/${i}`,
          date: `2019-05-25T13:0${i}:00Z`,
        }
      }),
      bookmark: null,
      hasMore: false,
    },
  }
}
const DOCUMENTS = makeFiles('documents', 'txt', 'text/plain')
const MEDIA = makeFiles('media', 'mp3', 'audio/mp3')

export function getSession() {
  return Promise.resolve({
    contextType: 'course',
    contextId: 47,
    canUploadFiles: true,
    usageRightsRequired: true,
  })
}

export function initializeFolders() {
  return {}
}

export function initializeImages(props) {
  return {
    [props.contextType]: {
      files: [],
      bookmark: undefined,
      hasMore: true,
      isLoading: false,
    },
  }
}

export function initializeUpload() {
  return {
    uploading: false,
    folders: {},
    formExpanded: false,
  }
}

export function initializeFlickr() {
  return {
    searchResults: [],
    searching: false,
    formExpanded: false,
  }
}

export function initializeCollection(endpoint) {
  return {
    links: [],
    bookmark: endpoint,
    loading: false,
  }
}

export function initializeDocuments(_props) {
  return {
    course: {
      files: [],
      bookmark: 'documents1',
      isLoading: false,
      hasMore: true,
    },
    user: {
      files: [],
      bookmark: 'documents1',
      isLoading: false,
      hasMore: true,
    },
  }
}

export function initializeMedia(_props) {
  return {
    course: {
      files: [],
      bookmark: 'media1',
      isLoading: false,
      hasMore: true,
    },
    user: {
      files: [],
      bookmark: 'media1',
      isLoading: false,
      hasMore: true,
    },
  }
}

export function fetchFolders() {
  return new Promise(resolve => {
    setTimeout(() => {
      resolve({folders: FOLDERS})
    }, 1000)
  })
}

export function fetchFiles(uri = 'files') {
  return Promise.resolve(PAGES[uri])
}

export function fetchImages(props) {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      let response
      const bookmark = props.images[props.contextType] && props.images[props.contextType].bookmark
      if (bookmark) {
        response = IMAGE_RESPONSES.find(response => response.bookmarkForThis === props.bookmark)
      } else {
        response = IMAGE_RESPONSES[0]
      }

      if (response) {
        resolve(response)
      } else {
        reject(new Error('Invalid bookmark'))
      }
    }, FAKE_TIMEOUT)
  })
}

export function fetchMediaFolder() {
  return Promise.resolve(PAGES.folders)
}

export function preflightUpload() {
  return new Promise(resolve => {
    setTimeout(() => {
      resolve({})
    }, FAKE_TIMEOUT)
  })
}

export function uploadFRD() {
  return new Promise(resolve => {
    setTimeout(() => {
      resolve(images[0])
    }, 250)
  })
}

export function fetchRootFolder(props) {
  return Promise.resolve({
    folders: [
      {
        id: 0,
        name: `${props.contextType} files`,
        filesUrl: 'files',
        foldersUrl: 'folders',
      },
    ],
  })
}

export function fetchPage(uri) {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      if (PAGES[uri]) {
        resolve(PAGES[uri])
      } else {
        reject(new Error('bad page!'))
      }
    }, 1000)
  })
}

export function searchFlickr(term) {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      if (FLICKR_RESULTS[term]) {
        resolve(FLICKR_RESULTS[term])
      } else {
        reject(new Error('No search results!'))
      }
    }, 1000)
  })
}

export function setUsageRights(id, usageRights) {
  const msg = 'Setting the following usage rights for file (id: %s):'
  console.log(msg, id, usageRights) // eslint-disable-line no-console
}

export function getFile(id) {
  return Promise.resolve({
    id,
    type: 'text/plain',
    name: 'Test File',
    url: 'test.txt',
    embed: {type: 'file'},
  })
}

export function fetchDocs(state) {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      const bookmark =
        (state.documents[state.contextType] && state.documents[state.contextType].bookmark) ||
        'documents1'

      const response = DOCUMENTS[bookmark]

      if (response) {
        resolve(response)
      } else {
        reject(new Error('Invalid bookmark'))
      }
    }, FAKE_TIMEOUT)
  })
}

export function fetchMedia(state) {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      let response
      const bookmark =
        (state.media[state.contextType] && state.media[state.contextType].bookmark) || 'media1'
      if (bookmark) {
        response = MEDIA[bookmark]
      }

      if (response) {
        resolve(response)
      } else {
        reject(new Error('Invalid bookmark'))
      }
    }, FAKE_TIMEOUT)
  })
}

export function updateMediaObject(state, {media_object_id, title}) {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      resolve({
        id: media_object_id,
        title,
        media_type: 'video',
        date: '2019-10-29T13:08:36Z',
        published: true,
      })
    }, FAKE_TIMEOUT)
  })
}

export function updateMediaObjectFailure() {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      reject()
    }, FAKE_TIMEOUT)
  })
}

export function updateClosedCaptions(/* apiProps, {media_object_id, subtitles} */) {
  return new Promise(resolve => {
    setTimeout(() => {
      resolve([])
    }, FAKE_TIMEOUT)
  })
}
