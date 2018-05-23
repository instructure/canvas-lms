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

const PAGES = {
  // page of announcements
  announcements: {
    links: [
      { href: "/courses/1/announcements", title: "Announcements List" },
      { href: "/courses/1/announcements/2", title: "Announcement 2" },
      { href: "/courses/1/announcements/1", title: "Announcement 1" }
    ],
    bookmark: null
  },

  // first page of assignments
  assignments: {
    links: [
      { href: "/courses/1/assignments", title: "Assignment List" },
      { href: "/courses/1/assignments/1", title: "Assignment 1" },
      { href: "/courses/1/assignments/2", title: "Assignment 2" },
      { href: "/courses/1/assignments/3", title: "Assignment 3" },
      { href: "/courses/1/assignments/4", title: "Quiz 1" }
    ],
    // refers to second page of assignments
    bookmark: "assignments2"
  },

  // second page of assignments
  assignments2: {
    links: [
      { href: "/courses/1/assignments/5", title: "Quiz 2" },
      { href: "/courses/1/assignments/6", title: "Quiz 3" }
    ],
    bookmark: null
  },

  // page of discussions
  discussions: {
    links: [
      { href: "/courses/1/discussion_topics", title: "Discussion Index" },
      { href: "/courses/1/discussion_topics/4", title: "Discussion 2" },
      { href: "/courses/1/discussion_topics/3", title: "Discussion 1" },
      { href: "/courses/1/discussion_topics/2", title: "Announcement 2" },
      { href: "/courses/1/discussion_topics/1", title: "Announcement 1" }
    ],
    // intentionally referring to page that doesn't exist to test failure mode
    bookmark: "discussions2"
  },

  // page of modules
  modules: {
    links: [
      { href: "/courses/1/modules", title: "Modules List" },
      { href: "/courses/1/modules/2", title: "Module 2" },
      { href: "/courses/1/modules/1", title: "Module 1" }
    ],
    bookmark: null
  },

  // page of quizzes
  quizzes: {
    links: [],
    bookmark: null
  },

  // page of wiki pages
  wikiPages: {
    links: [
      { href: "/courses/1/pages/wiki-page-1", title: "Wiki Page 1" },
      { href: "/courses/1/pages/wiki-page-2", title: "Wiki Page 2" }
    ],
    bookmark: null
  },

  // root files
  files: {
    files: [
      {
        id: 1,
        type: "text/plain",
        name: "File 1",
        url: "/files/1"
      },
      {
        id: 2,
        type: "text/plain",
        name: "File 2",
        url: "/files/2"
      }
    ],
    bookmark: "files2"
  },

  // root files page 2
  files2: {
    files: [
      {
        id: 3,
        type: "text/plain",
        name: "File 3",
        url: "/files/3"
      }
    ],
    bookmark: null
  },

  // files in folder 1
  folder1files: {
    files: [
      {
        id: 4,
        type: "text/plain",
        name: "File 4",
        url: "/files/4"
      },
      {
        id: 5,
        type: "text/plain",
        name: "File 5",
        url: "/files/5"
      }
    ],
    bookmark: null
  },

  // result for folder with no files
  emptyfiles: {
    files: [],
    bookmark: null
  },

  // root folders
  folders: {
    folders: [
      {
        id: 1,
        name: "Folder 1",
        parentId: 42,
        filesUrl: "folder1files",
        foldersUrl: "folder1folders"
      }
    ],
    bookmark: "folders2"
  },

  // root folders page 2
  folders2: {
    folders: [
      {
        id: 2,
        name: "Folder 2",
        parentId: 42,
        filesUrl: "emptyfiles",
        foldersUrl: "emptyfolders"
      }
    ],
    bookmark: null
  },

  // sub folders for folder 1
  folder1folders: {
    folders: [
      {
        id: 3,
        name: "Folder 1 Sub",
        parentId: 1,
        filesUrl: "emptyfiles",
        foldersUrl: "emptyfolders"
      }
    ],
    bookmark: null
  },

  // folders result for a folder with no sub folders
  emptyfolders: {
    folders: [],
    bookmark: null
  }
};

const FOLDERS = [
  { id: 1, name: "Folder 1", filesUrl: "filesurl", foldersUrl: "foldersurl" },
  { id: 2, name: "Folder 2", filesUrl: "filesurl", foldersUrl: "foldersurl" },
  { id: 3, name: "Folder 3", filesUrl: "filesurl", foldersUrl: "foldersurl" }
];

const serializedImage = {
  id: 12345,
  display_name: "test_image.jpeg",
  "content-type": "image/jpeg",
  preview_url: "http://preview-me.com",
  url:
    "http://api.ning.com/files/ZzR9cn0EG4o1Mz1V9B*gENYbkq9DHXt5bMKeFCgDhSzMnV8YhTmlB-yQZv4vgqL3bLno3dPh35L*Dv5gtCOfBrKwxM7DLBG*/412303325.jpeg?xgip=0%3A0%3A1021%3A1021%3B%3B&width=64&height=64&crop=1%3A1",
  thumbnail_url:
    "http://api.ning.com/files/ZzR9cn0EG4o1Mz1V9B*gENYbkq9DHXt5bMKeFCgDhSzMnV8YhTmlB-yQZv4vgqL3bLno3dPh35L*Dv5gtCOfBrKwxM7DLBG*/412303325.jpeg?xgip=0%3A0%3A1021%3A1021%3B%3B&width=64&height=64&crop=1%3A1"
};

const brokenImage = {
  id: 123456789,
  display_name: "broken_image.jpeg",
  "content-type": "image/jpeg",
  preview_url: "http://preview-me.com",
  url:
    "http://api.ning.com/files/ZzR9cn0EG4o1Mz1V9B*-yQZv4vgqL3bLno3dPh35L*Dv5gtCOfBrKwxM7DLBG*/412303325.jpeg?xgip=0%3A0%3A1021%3A1021%3B%3B&width=64&height=64&crop=1%3A1",
  thumbnail_url:
    "http://api.ning.com/files/ZzR9cn0EG4o1Mz1V9B*gENYbkq9gDhSzMnV8YhTmlB-yQZv4vgqL3bLno3dPh35L*Dv5gtCOfBrKwxM7DLBG*/412303325.jpeg?xgip=0%3A0%3A1021%3A1021%3B%3B&width=64&height=64&crop=1%3A1"
};

const IMAGES = [serializedImage, brokenImage];

const FLICKR_RESULTS = {
  go: [
    {
      id: "1",
      href: "https://farm9.static.flickr.com/8491/8297692520_4e7a43ffcf_s.jpg",
      title: "Game of Go in our club."
    },
    {
      id: "2",
      href: "https://farm1.static.flickr.com/5/7270219_6d3f41bc71_s.jpg",
      title: "Another game of Go"
    },
    {
      id: "3",
      href: "https://farm1.static.flickr.com/8/9686480_c726bf6c5d_s.jpg",
      title: "the fourth game"
    }
  ],
  chess: [
    {
      id: "4",
      href: "https://farm5.static.flickr.com/4051/4627936161_39df5d616a_s.jpg",
      title: "Chess."
    },
    {
      id: "5",
      href: "https://farm8.static.flickr.com/7428/9646564428_0e359a1092_s.jpg",
      title: "chess"
    },
    {
      id: "6",
      href: "https://farm9.static.flickr.com/8309/7961751980_66333f83cf_s.jpg",
      title: "champion chess"
    }
  ]
};

export function getSession() {
  return Promise.resolve({
    contextType: "course",
    contextId: 47,
    canUploadFiles: true,
    usageRightsRequired: true
  });
}

export function initializeFolders() {
  return {};
}

export function initializeImages() {
  return {
    records: [],
    bookmark: undefined,
    hasMore: false,
    isLoading: false,
    requested: false
  };
}

export function initializeUpload() {
  return {
    uploading: false,
    folders: {},
    formExpanded: false
  };
}

export function initializeFlickr() {
  return {
    searchResults: [],
    searching: false,
    formExpanded: false
  };
}

export function initializeCollection(endpoint) {
  return {
    links: [],
    bookmark: endpoint,
    loading: false
  };
}

export function fetchFolders() {
  return new Promise(function(resolve) {
    setTimeout(() => {
      resolve({ folders: FOLDERS });
    }, 1000);
  });
}

export function fetchFiles(uri = "files") {
  return Promise.resolve(PAGES[uri]);
}

export function fetchImages() {
  return new Promise(function(resolve) {
    resolve({ images: IMAGES });
  });
}

export function preflightUpload() {
  return new Promise(function(resolve) {
    setTimeout(() => {
      resolve({});
    }, 500);
  });
}

export function uploadFRD() {
  return new Promise(function(resolve) {
    setTimeout(() => {
      resolve(serializedImage);
    }, 250);
  });
}

export function fetchRootFolder(props) {
  return Promise.resolve({
    folders: [
      {
        id: 0,
        name: `${props.contextType} files`,
        filesUrl: "files",
        foldersUrl: "folders"
      }
    ]
  });
}

export function fetchPage(uri) {
  return new Promise(function(resolve, reject) {
    setTimeout(() => {
      if (PAGES[uri]) {
        resolve(PAGES[uri]);
      } else {
        reject("bad page!");
      }
    }, 1000);
  });
}

export function searchFlickr(term) {
  return new Promise(function(resolve, reject) {
    setTimeout(() => {
      if (FLICKR_RESULTS[term]) {
        resolve(FLICKR_RESULTS[term]);
      } else {
        reject("No search results!");
      }
    }, 1000);
  });
}

export function setUsageRights(id, usageRights) {
  const msg = "Setting the following usage rights for file (id: %s):";
  console.log(msg, id, usageRights); // eslint-disable-line no-console
}

export function getFile(id) {
  return Promise.resolve({
    id: id,
    type: "text/plain",
    name: "Test File",
    url: "test.txt",
    embed: { type: "file" }
  });
}
