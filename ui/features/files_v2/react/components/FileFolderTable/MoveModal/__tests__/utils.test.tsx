/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {
  addNewFoldersToCollection,
  parseAllPagesResponse
} from "../utils";

describe("MoveModal utils", () => {
  describe("addNewFoldersToCollection", () => {
    it("should add new folders to the collection", () => {
      const collection = {
        "1": { id: "1", name: "Folder 1", collections: [] },
        "2": { id: "2", name: "Folder 2", collections: [] },
      };
      const targetId = "1";
      const newCollections = {
        "3": { id: "3", name: "Folder 3", collections: [] },
        "4": { id: "4", name: "Folder 4", collections: [] },
      };
      const result = addNewFoldersToCollection(collection, targetId, newCollections);
      expect(result).toEqual({
        ...collection,
        [targetId]: {
          ...collection[targetId],
          collections: ["3", "4"],
        },
        ...newCollections,
      });
    });
  });

  describe("parseAllPagesResponse", () => {
    it("should parse all pages response correctly", () => {
      const response = {
        pageParams: [
          { page: "1", per_page: "15" },
          { page: "2", per_page: "15" },
        ],
        pages: [
          {
            nextPage: '1',
            json: [
              { id: "1", name: "Folder 1" },
              { id: "2", name: "Folder 2" },
            ],
          },
          {
            nextPage: '2',
            json: [
              { id: "3", name: "Folder 3" },
              { id: "4", name: "Folder 4" },
            ],
          },
        ],
      };
      const result = parseAllPagesResponse(response);
      expect(result).toEqual({
        "1": { id: "1", name: "Folder 1" },
        "2": { id: "2", name: "Folder 2" },
        "3": { id: "3", name: "Folder 3" },
        "4": { id: "4", name: "Folder 4" },
      });
    });
  });
})