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

// TODO - actually install query-string
import queryString from 'query-string'
import getCookie from '@instructure/get-cookie'
import type {Product} from '../model/Product'
import type {FilterItem} from '../model/Filter'
import {isEmpty} from 'lodash'

const accountId = window.location.pathname.split('/')[2]

// TODO: add actual type
type Params = any
type ProductResponse = {
  tools: Array<Product>
  meta: {
    count: number
    total_count: number
    current_page: number
    num_pages: number
    per_page: number
  }
}
type ToolsByDisplayGroupResponse = Array<{
  display_name: string
  description: string
  tag: FilterItem
  tools: Array<Product>
}>

// TODO: remove when backend hooked up
const mockProducts: Array<Product> = [
  {
    id: 'powernotes',
    global_product_id: 'powernotes',
    name: 'Powernotes',
    tagline: 'Stay organized, save time, and improve your writing & research.',
    description:
      'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam voluptatem.',
    company: {
      id: 'powernotes',
      name: 'Powernotes',
      company_url: 'https://google.com',
    },
    logo_url:
      'https://learn-trials-qa.s3.amazonaws.com/attachments/9/assets/e43a04ca22cb1b83752fdda119e50ba5.png',
    updated_at: '2024-01-01',
    tool_integration_configurations: {
      lti_13: [
        {
          id: 271,
          integration_type: 'lti_13_dynamic_registration',
          url: 'https://studio.code.org/lti/v1/dynamic_registration',
          unified_tool_id: '271',
        },
      ],
    },
    tags: [
      {
        id: 86,
        name: 'Classroom Management',
      },
      {
        id: 529,
        name: 'LTI v1.3',
      },
      {
        id: 558,
        name: 'Homework Submission',
      },
      {
        id: 530,
        name: 'LTI v1.1',
      },
    ],
    badges: [
      {
        name: 'ISTE Seal',
        image_url: 'https://binarylogic.net/img/int-standards/ISTE-badge.jpg',
        link: 'https://iste.org/iste-seal',
      },
      {
        name: 'Digital Promise',
        image_url: 'https://api.badgr.io/public/badges/X4bcdw10TL6nEKSAuIS3aA/image',
        link: 'https://digitalpromise.org/initiative/educator-micro-credentials/',
      },
      {
        name: '1EdTech TrustEd App',
        image_url:
          'https://www.1edtech.org/sites/default/files/resize/content/TrustEd%20Apps%20Badge%201EdTech%20brand%20color-321x328.png',
        link: 'https://www.1edtech.org/program/trustedapps',
      },
      {
        name: 'UDL Certification',
        image_url: 'https://index.edsurge.com/images/udlProductCertification-badge_updated.png',
        link: 'https://www.cast.org/learn/credentials-certifications',
      },
    ],
    screenshots: [
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Student-Teacher-View.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-Duplicate-1.png',
    ],
  },
  {
    id: '3ff',
    global_product_id: '3ff',
    name: 'New Product',
    tagline: 'New product who this',
    description:
      'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam voluptatem.',
    company: {
      id: '19a',
      name: 'Vendor Test Company',
      company_url: 'https://google.com',
    },
    logo_url:
      'data:image/png;base64,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',
    updated_at: '2024-01-01',
    tool_integration_configurations: {
      lti_13: [
        {
          id: 274,
          integration_type: 'lti_13_dynamic_registration',
          url: 'https://studio.code.org/lti/v1/dynamic_registration',
          unified_tool_id: '274',
        },
      ],
    },
    tags: [
      {
        id: 86,
        name: 'Classroom Management',
      },
      {
        id: 529,
        name: 'LTI v1.3',
      },
      {
        id: 558,
        name: 'Homework Submission',
      },
      {
        id: 530,
        name: 'LTI v1.1',
      },
    ],
    badges: [
      {
        name: 'ISTE Seal',
        image_url: 'https://binarylogic.net/img/int-standards/ISTE-badge.jpg',
        link: 'https://iste.org/iste-seal',
      },
      {
        name: 'Digital Promise',
        image_url: 'https://api.badgr.io/public/badges/X4bcdw10TL6nEKSAuIS3aA/image',
        link: 'https://digitalpromise.org/initiative/educator-micro-credentials/',
      },
      {
        name: 'UDL Certification',
        image_url: 'https://index.edsurge.com/images/udlProductCertification-badge_updated.png',
        link: 'https://www.cast.org/learn/credentials-certifications',
      },
    ],
    screenshots: ['https://nearpod.com/blog/wp-content/uploads/2017/11/Student-Teacher-View.png'],
  },
  {
    id: '5a',
    global_product_id: '5a',
    name: 'Blendspace',
    tagline:
      'Platform where teachers and students can collect, annotate and share digital resources ',
    description:
      'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam voluptatem.',
    company: {
      id: '9a',
      name: 'Smart Sparrow',
      company_url: 'https://google.com',
    },
    logo_url:
      'https://learn-trials-qa.s3.amazonaws.com/attachments/15/assets/e213c9f60d94a8f3ff62220e201d724d.png',
    updated_at: '2024-01-01',
    tool_integration_configurations: {
      lti_13: [
        {
          id: 371,
          integration_type: 'lti_13_dynamic_registration',
          url: 'https://studio.code.org/lti/v1/dynamic_registration',
          unified_tool_id: '371',
        },
      ],
    },
    tags: [
      {
        id: 86,
        name: 'Classroom Management',
      },
      {
        id: 529,
        name: 'LTI v1.3',
      },
      {
        id: 558,
        name: 'Homework Submission',
      },
      {
        id: 530,
        name: 'LTI v1.1',
      },
    ],
    badges: [
      {
        name: 'ISTE Seal',
        image_url: 'https://binarylogic.net/img/int-standards/ISTE-badge.jpg',
        link: 'https://iste.org/iste-seal',
      },
      {
        name: 'Digital Promise',
        image_url: 'https://api.badgr.io/public/badges/X4bcdw10TL6nEKSAuIS3aA/image',
        link: 'https://digitalpromise.org/initiative/educator-micro-credentials/',
      },
    ],
    screenshots: [
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Student-Teacher-View.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-Duplicate-1.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-2nd.jpg',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Student-Teacher-View.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-Duplicate-1.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-2nd.jpg',
    ],
  },
  {
    id: '45a',
    global_product_id: '45a',
    name: '1000 Sight Words Superhero HD Free',
    tagline: "This product needs a tagline so this is what we'll use",
    description:
      'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam voluptatem.',
    company: {
      id: '1a',
      name: 'Khan11',
      company_url: 'https://google.com',
    },
    logo_url:
      'https://learn-trials-qa.s3.amazonaws.com/attachments/17091/assets/Springfeld_Logo.png',
    updated_at: '2024-01-01',
    tool_integration_configurations: {
      lti_13: [
        {
          id: 2071,
          integration_type: 'lti_13_dynamic_registration',
          url: 'https://studio.code.org/lti/v1/dynamic_registration',
          unified_tool_id: '2071',
        },
      ],
    },
    tags: [
      {
        id: 86,
        name: 'Classroom Management',
      },
      {
        id: 529,
        name: 'LTI v1.3',
      },
      {
        id: 558,
        name: 'Homework Submission',
      },
      {
        id: 530,
        name: 'LTI v1.1',
      },
    ],
    badges: [
      {
        name: 'ISTE Seal',
        image_url: 'https://binarylogic.net/img/int-standards/ISTE-badge.jpg',
        link: 'https://iste.org/iste-seal',
      },
      {
        name: 'Digital Promise',
        image_url: 'https://api.badgr.io/public/badges/X4bcdw10TL6nEKSAuIS3aA/image',
        link: 'https://digitalpromise.org/initiative/educator-micro-credentials/',
      },
      {
        name: 'UDL Certification',
        image_url: 'https://index.edsurge.com/images/udlProductCertification-badge_updated.png',
        link: 'https://www.cast.org/learn/credentials-certifications',
      },
    ],
    screenshots: [
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Student-Teacher-View.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-Duplicate-1.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-2nd.jpg',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Student-Teacher-View.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-Duplicate-1.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-2nd.jpg',
    ],
  },
  {
    id: '83a',
    global_product_id: '83a',
    name: '8notes.com',
    tagline: 'Solid mix of free and paid music ed resources, plus sheet music',
    description:
      'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam voluptatem.',
    company: {
      id: '6a',
      name: 'Test',
      company_url: 'https://google.com',
    },
    logo_url:
      'https://learn-trials-qa.s3.amazonaws.com/attachments/345/assets/9da15d28d2ca333399624545c995ff33.png',
    updated_at: '2024-01-01',
    tool_integration_configurations: {
      lti_13: [
        {
          id: 271,
          integration_type: 'lti_13_dynamic_registration',
          url: 'https://studio.code.org/lti/v1/dynamic_registration',
          unified_tool_id: '271',
        },
      ],
    },
    tags: [
      {
        id: 86,
        name: 'Classroom Management',
      },
      {
        id: 529,
        name: 'LTI v1.3',
      },
      {
        id: 558,
        name: 'Homework Submission',
      },
      {
        id: 530,
        name: 'LTI v1.1',
      },
    ],
    badges: [
      {
        name: 'ISTE Seal',
        image_url: 'https://binarylogic.net/img/int-standards/ISTE-badge.jpg',
        link: 'https://iste.org/iste-seal',
      },
      {
        name: 'Digital Promise',
        image_url: 'https://api.badgr.io/public/badges/X4bcdw10TL6nEKSAuIS3aA/image',
        link: 'https://digitalpromise.org/initiative/educator-micro-credentials/',
      },
      {
        name: '1EdTech TrustEd App',
        image_url:
          'https://www.1edtech.org/sites/default/files/resize/content/TrustEd%20Apps%20Badge%201EdTech%20brand%20color-321x328.png',
        link: 'https://www.1edtech.org/program/trustedapps',
      },
      {
        name: 'UDL Certification',
        image_url: 'https://index.edsurge.com/images/udlProductCertification-badge_updated.png',
        link: 'https://www.cast.org/learn/credentials-certifications',
      },
    ],
    screenshots: [
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Student-Teacher-View.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-Duplicate-1.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-2nd.jpg',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Student-Teacher-View.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-Duplicate-1.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-2nd.jpg',
    ],
  },
  {
    id: '118a',
    global_product_id: '118a',
    name: 'ABCya!',
    tagline: 'Tons of options, though pesky ads can annoy',
    description:
      'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam voluptatem.',
    company: {
      id: '17a',
      name: 'NEW COMPANY',
      company_url: 'https://google.com',
    },
    logo_url:
      'https://learn-trials-qa.s3.amazonaws.com/attachments/512/assets/4b0a4845542a18261c8fc19197a79803.png',
    updated_at: '2024-01-01',
    tool_integration_configurations: {
      lti_13: [
        {
          id: 271,
          integration_type: 'lti_13_dynamic_registration',
          url: 'https://studio.code.org/lti/v1/dynamic_registration',
          unified_tool_id: '271',
        },
      ],
    },
    tags: [
      {
        id: 86,
        name: 'Classroom Management',
      },
      {
        id: 529,
        name: 'LTI v1.3',
      },
      {
        id: 558,
        name: 'Homework Submission',
      },
      {
        id: 530,
        name: 'LTI v1.1',
      },
    ],
    badges: [
      {
        name: '1EdTech TrustEd App',
        image_url:
          'https://www.1edtech.org/sites/default/files/resize/content/TrustEd%20Apps%20Badge%201EdTech%20brand%20color-321x328.png',
        link: 'https://www.1edtech.org/program/trustedapps',
      },
      {
        name: 'UDL Certification',
        image_url: 'https://index.edsurge.com/images/udlProductCertification-badge_updated.png',
        link: 'https://www.cast.org/learn/credentials-certifications',
      },
    ],
    screenshots: [
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Student-Teacher-View.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-Duplicate-1.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-2nd.jpg',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Student-Teacher-View.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-Duplicate-1.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-2nd.jpg',
    ],
  },
  {
    id: '3642a',
    global_product_id: '3642a',
    name: 'AdditionalLinkTest123',
    tagline: 'adding addition links from Sysadmin side',
    description:
      'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam voluptatem.',
    company: {
      id: '17a',
      name: 'NEW COMPANY',
      company_url: 'https://google.com',
    },
    logo_url: 'https://learn-trials-qa.s3.amazonaws.com/attachments/19788/assets/logo.png',
    updated_at: '2024-01-01',
    tool_integration_configurations: {
      lti_13: [
        {
          id: 971,
          integration_type: 'lti_13_dynamic_registration',
          url: 'https://studio.code.org/lti/v1/dynamic_registration',
          unified_tool_id: '971',
        },
      ],
    },
    tags: [
      {
        id: 86,
        name: 'Classroom Management',
      },
      {
        id: 529,
        name: 'LTI v1.3',
      },
      {
        id: 558,
        name: 'Homework Submission',
      },
      {
        id: 530,
        name: 'LTI v1.1',
      },
    ],
    badges: [
      {
        name: 'Digital Promise',
        image_url: 'https://api.badgr.io/public/badges/X4bcdw10TL6nEKSAuIS3aA/image',
        link: 'https://digitalpromise.org/initiative/educator-micro-credentials/',
      },
      {
        name: '1EdTech TrustEd App',
        image_url:
          'https://www.1edtech.org/sites/default/files/resize/content/TrustEd%20Apps%20Badge%201EdTech%20brand%20color-321x328.png',
        link: 'https://www.1edtech.org/program/trustedapps',
      },
      {
        name: 'UDL Certification',
        image_url: 'https://index.edsurge.com/images/udlProductCertification-badge_updated.png',
        link: 'https://www.cast.org/learn/credentials-certifications',
      },
    ],
    screenshots: [
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Student-Teacher-View.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-Duplicate-1.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-2nd.jpg',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Student-Teacher-View.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-Duplicate-1.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-2nd.jpg',
    ],
  },
  {
    id: '3676a',
    global_product_id: '3676a',
    name: 'Rake',
    tagline: 'Rake is great for gardening',
    description:
      'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam voluptatem.',
    company: {
      id: '101a',
      name: "Tom's Education Company",
      company_url: 'https://google.com',
    },
    logo_url: 'https://learn-trials-qa.s3.amazonaws.com/attachments/20770/assets/rake.png',
    updated_at: '2024-01-01',
    tool_integration_configurations: {
      lti_13: [
        {
          id: 1171,
          integration_type: 'lti_13_dynamic_registration',
          url: 'https://studio.code.org/lti/v1/dynamic_registration',
          unified_tool_id: '1171',
        },
      ],
    },
    tags: [
      {
        id: 86,
        name: 'Classroom Management',
      },
      {
        id: 529,
        name: 'LTI v1.3',
      },
      {
        id: 558,
        name: 'Homework Submission',
      },
      {
        id: 530,
        name: 'LTI v1.1',
      },
    ],
    badges: [
      {
        name: 'ISTE Seal',
        image_url: 'https://binarylogic.net/img/int-standards/ISTE-badge.jpg',
        link: 'https://iste.org/iste-seal',
      },
      {
        name: 'Digital Promise',
        image_url: 'https://api.badgr.io/public/badges/X4bcdw10TL6nEKSAuIS3aA/image',
        link: 'https://digitalpromise.org/initiative/educator-micro-credentials/',
      },
      {
        name: '1EdTech TrustEd App',
        image_url:
          'https://www.1edtech.org/sites/default/files/resize/content/TrustEd%20Apps%20Badge%201EdTech%20brand%20color-321x328.png',
        link: 'https://www.1edtech.org/program/trustedapps',
      },
      {
        name: 'UDL Certification',
        image_url: 'https://index.edsurge.com/images/udlProductCertification-badge_updated.png',
        link: 'https://www.cast.org/learn/credentials-certifications',
      },
    ],
    screenshots: [
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Student-Teacher-View.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-Duplicate-1.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-2nd.jpg',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Student-Teacher-View.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-Duplicate-1.png',
      'https://nearpod.com/blog/wp-content/uploads/2017/11/Project-a-2nd.jpg',
    ],
  },
]

export const mockTags: Array<FilterItem> = [
  {
    id: '1',
    name: '1EdTEch Trusted App Certified',
  },
  {
    id: '2',
    name: 'LTI 1.3 Supported',
  },
]

export const fetchProducts = async (params: Params): Promise<ProductResponse> => {
  let tools = [...mockProducts]
  if (!isEmpty(params.filters.companies)) {
    tools = tools.filter(product =>
      params.filters.companies.map((c: {id: any}) => c.id).includes(product.company.id)
    )
  }

  if (params.name_cont) {
    tools = tools.filter(
      e => e.name.includes(params.name_cont) || e.company.name.includes(params.name_cont)
    )
  }

  if (params.page) {
    const start = (params.page - 1) * (params.per_page || 3)
    const end = start + (params.per_page || 3)
    tools = tools.slice(start, end)
  }

  const meta = {
    count: tools.length,
    total_count: mockProducts.length,
    current_page: params.page || 1,
    num_pages: 3,
    per_page: 3,
  }
  return {tools, meta}

  // TODO: uncomment when backend hooked up and remove mock data

  // const url = `api/v1/products?${queryString(params)}`

  // const response = await fetch(url, {
  //   method: 'get',
  //   headers: {
  //     'X-CSRF-Token': getCookie('_csrf_token'),
  //     'content-Type': 'application/json',
  //   }
  // })

  // if (!response.ok) {
  //   throw new Error(`Failed to fetch products`)
  // }
  // const {products} = await response.json()

  // return products
}

export const fetchProductDetails = async (global_product_id: String): Promise<Product | null> => {
  if (!global_product_id) return null
  const url = `/api/v1/accounts/${accountId}/learn_platform/products/${global_product_id}`

  const response = fetch(url, {
    method: 'get',
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
      'content-Type': 'application/json',
    },
  })
    .then(resp => resp.json())
    .then(product => {
      return product
    })

  const getProduct = async () => {
    const product = await response
    return product
  }

  if (!response) {
    throw new Error(`Failed to fetch product with id ${global_product_id}`)
  }

  return getProduct()
}

export const fetchToolsByDisplayGroups = async (): Promise<ToolsByDisplayGroupResponse> => {
  const url = `/api/v1/accounts/${accountId}/learn_platform/products_categories`

  const response = fetch(url, {
    method: 'get',
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
      'content-Type': 'application/json',
    },
  })
    .then(resp => resp.json())
    .then(resp => {
      // temporarily restructuring the response data to work with the existing front end code
      return resp.tools_by_display_group.map((group: any) => {
        return {
          display_name: group.tag_group.name,
          description: group.tag_group.description,
          tag: {...group.tag_group},
          tools: group.tools.slice(0, 3),
        }
      })
    })
    .catch(() => {
      throw new Error(`Failed to fetch products categories`)
    })

  return response
}
