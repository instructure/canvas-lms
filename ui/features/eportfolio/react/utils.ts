/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import doFetchApi from '@canvas/do-fetch-api-effect'

export const createEntry = async (
  type: string,
  portfolioId: number,
  name: string,
  sectionId?: number,
) => {
  let params
  if (type === 'categories') {
    params = {
      eportfolio_category: {
        name,
      },
    }
  } else {
    params = {
      eportfolio_entry: {
        name,
        eportfolio_category_id: sectionId,
      },
    }
  }
  const {json} = await doFetchApi({
    path: `/eportfolios/${portfolioId}/${type}`,
    method: 'POST',
    params,
  })
  return json
}

export const deleteEntry = async (type: string, portfolioId: number, id: number) => {
  const {json} = await doFetchApi({
    path: `/eportfolios/${portfolioId}/${type}/${id}`,
    method: 'DELETE',
  })
  return json
}

export const moveEntry = async (
  type: string,
  portfolioId: number,
  order: number[],
  sectionId?: number,
) => {
  const params = {
    order: order.toString(),
  }
  const path =
    type === 'categories'
      ? `/eportfolios/${portfolioId}/reorder_${type}`
      : `/eportfolios/${portfolioId}/${sectionId}/reorder_${type}`
  const {json} = await doFetchApi({
    path,
    method: 'POST',
    params,
  })
  return json
}

export const updateEntry = async (
  type: string,
  portfolioId: number,
  name: string,
  id: number,
  sectionId?: number,
) => {
  let params
  if (type === 'categories') {
    params = {
      eportfolio_category: {
        name,
      },
    }
  } else {
    params = {
      eportfolio_entry: {
        name,
        eportfolio_category_id: sectionId,
      },
    }
  }
  const {json} = await doFetchApi({
    path: `/eportfolios/${portfolioId}/${type}/${id}`,
    method: 'PUT',
    params,
  })
  return json
}

export const generatePageListKey = (sectionId: number, portfolioId: number) => {
  return ['portfolioPageList', portfolioId, sectionId]
}
