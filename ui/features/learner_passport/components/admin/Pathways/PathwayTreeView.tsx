/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {
  useCallback,
  useContext,
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
} from 'react'
import dagre from 'dagre'
import type {Node} from 'dagre'
import bspline from 'b-spline'
import {Flex} from '@instructure/ui-flex'
import {IconBulletListLine, IconGroupLine} from '@instructure/ui-icons'
import {Pill} from '@instructure/ui-pill'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import {isPathwayBadgeType, type MilestoneData, type PathwayDetailData} from '../../types'
import {pluralize, findSubtreeMilestones} from '../../shared/utils'
import {DataContext} from './PathwayEditDataContext'

const BOX_WIDTH = 322

type PathwayNode = Node<PathwayDetailData | MilestoneData>
type GraphNode = PathwayDetailData | MilestoneData | PathwayNode
type NodeType = 'pathway' | 'milestone'

type PathwayTreeViewProps = {
  pathway: PathwayDetailData
  selectedStep: string | null
  onSelected?: (selectedStep: MilestoneData | null) => void
  layout?: 'TB' | 'BT' | 'LR' | 'RL'
  version: string
  zoomLevel?: number
  renderTreeControls?: () => JSX.Element | null
}

type BoxHeights = {
  height: number
  milestones: Array<{id: string; height: number}>
}

interface NamespacedDiv
  extends React.DetailedHTMLProps<React.HTMLAttributes<HTMLDivElement>, HTMLDivElement> {
  elementRef?: (node: HTMLDivElement) => void
  xmlns?: string
}

const DivInSVG: React.FC<NamespacedDiv> = props => {
  const {elementRef, ...divprops} = props

  return (
    <div xmlns="http://www.w3.org/1999/xhtml" {...divprops} ref={elementRef}>
      {props.children}
    </div>
  )
}

const PathwayTreeView = ({
  pathway,
  selectedStep,
  onSelected,
  layout = 'TB',
  version,
  zoomLevel = 1,
  renderTreeControls,
}: PathwayTreeViewProps) => {
  const {allBadges} = useContext(DataContext)
  const [g] = useState(new dagre.graphlib.Graph())
  const [dagNodes, setDagNodes] = useState<JSX.Element[]>([])
  const [dagEdges, setDagEdges] = useState<JSX.Element[]>([])
  const [rootNodeRef, setRootNodeRef] = useState(null)
  const [viewBox, setViewBox] = useState([0, 0, 0, 0])

  const [preRendered, setPreRendered] = useState(false)
  const [graphBoxHeights, setGraphBoxHeights] = useState<BoxHeights>({
    height: 0,
    milestones: [],
  })
  const [boxToScrollTo, setBoxToScrollTo] = useState<string | null>(null)
  const [selectedSubtree, setSelectedSubtree] = useState<string[]>(() => {
    return selectedStep ? findSubtreeMilestones(pathway.milestones, selectedStep, []) : []
  })
  const [scrollOffset, setScrollOffset] = useState({top: 0, left: 0})

  const preRenderNodeRef = useRef<HTMLDivElement | null>(null)
  const svgRef = useRef<SVGSVGElement | null>(null)

  useEffect(() => {
    const subtree = selectedStep ? findSubtreeMilestones(pathway.milestones, selectedStep, []) : []
    setSelectedSubtree(subtree)
  }, [pathway.milestones, selectedStep])

  useEffect(() => {
    if (preRendered && boxToScrollTo) {
      const boxId = boxToScrollTo.replace(/blank-/, '')
      const elem = document.getElementById(boxId)
      elem?.scrollIntoView({behavior: 'smooth', block: 'center', inline: 'center'})
    }
  }, [boxToScrollTo, preRendered])

  const resetGraph = useCallback(() => {
    g.nodes().forEach(n => g.removeNode(n))
    g.edges().forEach(e => g.removeEdge(e.v, e.w))
    setDagNodes([])
    setDagEdges([])
    setRootNodeRef(null)
    if (svgRef.current) {
      setPreRendered(false)
    }
    preRenderNodeRef.current = null
    svgRef.current = null

    const treeRoot = document.getElementById('pathway-tree-view')
    if (treeRoot) {
      setScrollOffset({top: treeRoot.scrollTop, left: treeRoot.scrollLeft})
    }
  }, [g])

  useEffect(() => {
    resetGraph()
  }, [resetGraph, version])

  const handleSelectBox = useCallback(
    (id: string) => {
      if (!onSelected) return
      if (id === '0') {
        onSelected(null)
      } else {
        const milestone = pathway.milestones.find(m => m.id === id)
        if (!milestone) return
        onSelected(milestone)
      }
    },
    [onSelected, pathway.milestones]
  )

  const handleBoxClick = useCallback(
    (e: React.MouseEvent<HTMLDivElement>) => {
      handleSelectBox(e.currentTarget.id)
      setBoxToScrollTo(e.currentTarget.id)
    },
    [handleSelectBox]
  )

  const handleBoxKey = useCallback(
    (e: React.KeyboardEvent<HTMLDivElement>) => {
      if (e.key === 'Enter') {
        handleSelectBox(e.currentTarget.id)
      }
    },
    [handleSelectBox]
  )

  const boxProps = useMemo(() => {
    return onSelected
      ? {
          role: 'button',
          tabIndex: 0,
          onClick: handleBoxClick,
          onKeyDown: handleBoxKey,
        }
      : {}
  }, [handleBoxClick, handleBoxKey, onSelected])

  const handleRootNodeRef = useCallback(
    node => {
      setRootNodeRef(node)
    },
    [setRootNodeRef]
  )

  const renderPathwayBoxContent = useCallback(
    (node: GraphNode, type: NodeType, selected: boolean, width: number, height?: number) => {
      if (node.id === 'blank') {
        return (
          <View
            as="div"
            padding="small"
            background="secondary"
            borderRadius="large"
            borderWidth="medium"
            width={`${width}px`}
            height={height ? `${height}px` : 'auto'}
            style={{cursor: 'default'}}
          />
        )
      }

      const req_count: number = 'requirement_count' in node ? (node.requirement_count as number) : 0
      let img_url
      if (type === 'pathway') {
        img_url = (node as PathwayDetailData).image_url
      } else if (node.completion_award) {
        if (typeof node.completion_award === 'string') {
          const badge = allBadges.find(b => b.id === (node as MilestoneData).completion_award)
          img_url = badge?.image
        } else if (isPathwayBadgeType(node.completion_award)) {
          img_url = node.completion_award?.image
        }
      }

      return (
        <View
          as="div"
          padding="small"
          background={type === 'pathway' ? 'primary-inverse' : 'primary'}
          borderRadius="large"
          borderWidth="medium"
          width={`${width}px`}
          height={height ? `${height}px` : 'auto'}
          minHeight="100%"
          borderColor={selected ? 'brand' : undefined}
        >
          <Flex as="div" direction="column" justifyItems="start" height="100%" gap="small">
            {img_url ? (
              <Flex as="div" gap="small" data-bar="has_image">
                <Flex.Item shouldShrink={false} shouldGrow={false}>
                  <img src={img_url} alt="" style={{height: '40px'}} data-foo="msimg" />
                </Flex.Item>
                <Flex.Item shouldShrink={true}>
                  {type === 'pathway' && (
                    <Text as="div" fontStyle="italic" size="x-small">
                      End of pathway
                    </Text>
                  )}
                  <Text as="div" weight="bold" size="medium">
                    {node.title}
                  </Text>
                </Flex.Item>
              </Flex>
            ) : (
              <Flex.Item shouldShrink={false} shouldGrow={false}>
                {type === 'pathway' && (
                  <Text as="div" fontStyle="italic" size="x-small">
                    End of pathway
                  </Text>
                )}
                <Text as="div" weight="bold" size="medium">
                  {node.title}
                </Text>
              </Flex.Item>
            )}
            <Flex.Item shouldGrow={true}>
              {node.description && (
                <Text as="div" size="x-small">
                  <TruncateText maxLines={2} truncate="character">
                    {node.description}
                  </TruncateText>
                </Text>
              )}
              {!('required' in node) || node.required ? null : (
                <div style={{padding: '.5rem 0'}}>
                  <Pill>Optional</Pill>
                </div>
              )}
            </Flex.Item>
            {type === 'pathway' ? (
              <Flex.Item>
                <IconGroupLine size="x-small" />
                <View display="inline-block" margin="0 0 0 x-small">
                  <Text size="small">
                    {pluralize(
                      (node as PathwayDetailData).learner_groups.length,
                      '1 learner group',
                      `${(node as PathwayDetailData).learner_groups.length} learner groups`
                    )}
                  </Text>
                </View>
              </Flex.Item>
            ) : (
              <Flex.Item>
                <IconBulletListLine size="x-small" />
                <View display="inline-block" margin="0 0 0 x-small">
                  <Text size="small">
                    {pluralize(req_count, '1 requirement', `${req_count} requirements`)}
                  </Text>
                </View>
              </Flex.Item>
            )}
          </Flex>
        </View>
      )
    },
    [allBadges]
  )

  const renderPathwayBox = useCallback(
    (data: PathwayDetailData | MilestoneData, type: NodeType, key: string) => {
      return (
        <div id={data.id} key={key} role="button">
          {renderPathwayBoxContent(data, type, false, BOX_WIDTH, undefined)}
        </div>
      )
    },
    [renderPathwayBoxContent]
  )

  const preRenderPathwayBoxes = useCallback(() => {
    const boxes = pathway.milestones.map((m: MilestoneData) => {
      return renderPathwayBox(m, 'milestone', `milestone-${m.id}`)
    })
    boxes.unshift(renderPathwayBox(pathway, 'pathway', `pathway-${pathway.id}`))

    return <div ref={preRenderNodeRef}>{boxes}</div>
  }, [pathway, renderPathwayBox])

  const renderDAG = useCallback(() => {
    if (!preRendered) return
    // Set an object for the graph label
    g.setGraph({rankdir: layout, marginy: 50})

    // Default to assigning a new object as a label for each new edge.
    g.setDefaultEdgeLabel(function () {
      return {}
    })

    g.setNode('0', {
      title: pathway.title,
      description: pathway.description,
      image_url: pathway.image_url,
      width: 320,
      height: graphBoxHeights.height,
      learner_groups: pathway.learner_groups,
    })
    pathway.milestones.forEach((m: MilestoneData) => {
      const ht = graphBoxHeights.milestones.find(n => n.id === m.id)?.height
      g.setNode(m.id, {
        id: m.id,
        title: m.title,
        description: m.description,
        completion_award: m.completion_award,
        required: m.required,
        requirement_count: m.requirements.length,
        width: 320,
        height: ht || 132,
      })
      m.next_milestones.forEach((n: string) => {
        if (n === 'blank') {
          // this is a bit of a hack to get the scrollIntoView
          // effect to run, but still have it scroll the blank
          // node's parent into view.
          setBoxToScrollTo(`blank-${m.id}`)
          g.setNode('blank', {
            id: 'blank',
            width: 320,
            height: 102,
          })
        }
        g.setEdge(m.id, n)
      })
    })
    pathway.first_milestones.forEach((m: string) => {
      g.setEdge('0', m)
    })

    dagre.layout(g)

    const maxX = g.graph().width as number
    const maxY = g.graph().height as number
    setViewBox([0, 0, maxX, maxY])

    const nodes = g.nodes().map((n, i) => {
      const node = g.node(n)
      const type = i === 0 ? 'pathway' : 'milestone'
      return (
        <foreignObject
          key={n}
          x={`${node.x - node.width / 2}`}
          y={`${node.y - node.height / 2}`}
          width={node.width}
          height={node.height}
          style={{
            boxShadow:
              selectedStep === n
                ? 'rgba(0, 0, 0, 0.1) 0px 0.375rem 0.4375rem, rgba(0, 0, 0, 0.25) 0px 0.625rem 1.75rem'
                : undefined,
            borderRadius: '0.5rem',
          }}
        >
          <DivInSVG
            xmlns="http://www.w3.org/1999/xhtml"
            className={i === 0 ? 'pathway' : 'milestone'}
            elementRef={i === 0 ? handleRootNodeRef : undefined}
            id={n}
            style={{
              display: 'relative',
              left: 0,
              top: 0,
              cursor: onSelected && n !== 'blank' ? 'pointer' : 'default',
            }}
            {...boxProps}
          >
            {selectedStep && n !== 'blank' && !selectedSubtree.includes(n) && (
              <div
                style={{
                  position: 'absolute',
                  top: 0,
                  left: 0,
                  width: '100%',
                  height: '100%',
                  background: '#fff',
                  opacity: 0.7,
                  borderRadius: '0.5rem',
                  zIndex: 1,
                }}
              />
            )}
            {renderPathwayBoxContent(
              node as PathwayNode,
              type,
              selectedStep === n,
              node.width,
              node.height
            )}
          </DivInSVG>
        </foreignObject>
      )
    })

    setDagNodes(nodes)
  }, [
    boxProps,
    g,
    graphBoxHeights.height,
    graphBoxHeights.milestones,
    handleRootNodeRef,
    layout,
    onSelected,
    pathway.description,
    pathway.first_milestones,
    pathway.image_url,
    pathway.learner_groups,
    pathway.milestones,
    pathway.title,
    preRendered,
    renderPathwayBoxContent,
    selectedStep,
    selectedSubtree,
  ])

  const renderDAGEdges = useCallback(() => {
    if (rootNodeRef === null) return

    const edges = g.edges().map(edg => {
      const points = g.edge(edg).points
      const pts = points.map(p => Object.values(p))
      const commands = [`M${points[0].x} ${points[0].y}`]
      for (let t = 0; t <= 1; t += 0.1) {
        const p = bspline(t, pts.length - 1, pts)
        commands.push(`L${p[0]} ${p[1]}`)
      }
      commands.push(`L${points[points.length - 1].x} ${points[points.length - 1].y}`)
      return (
        <g fill="none" stroke="#C7CDD1" key={`edge-${edg.v}-${edg.w}`}>
          <circle cx={points[0].x} cy={points[0].y} r="2" strokeWidth="2" />
          <path d={commands.join(' ')} fill="none" strokeWidth={2} />
          <circle
            cx={points[points.length - 1].x}
            cy={points[points.length - 1].y}
            r="2"
            strokeWidth="2"
          />
        </g>
      )
    })
    setDagEdges(edges)
  }, [g, rootNodeRef])

  useEffect(() => {
    const sty = document.createElement('style')
    sty.innerText = `
    .dag {
        overflow: visible!important;
        font-size: 16px;
    }
    `
    document.head.appendChild(sty)
    return () => {
      sty.remove()
    }
  }, [])

  useLayoutEffect(() => {
    if (preRenderNodeRef?.current) {
      const boxes = Array.from(preRenderNodeRef.current.children)
      const boxHeights: BoxHeights = boxes.reduce(
        // we're reducing and accumulating a value that's not the same type as the array
        // that's not how reduce is typed.
        // @ts-expect-error
        (acc: BoxHeights, n: HTMLDivElement, index: number) => {
          const {height} = n.getBoundingClientRect()
          if (index === 0) {
            acc.height = height
          } else {
            acc.milestones.push({id: n.id, height})
          }
          return acc
        },
        {height: 0, milestones: []}
      ) as unknown as BoxHeights
      setPreRendered(true)
      setGraphBoxHeights(boxHeights)
    }
  }, [pathway.id, version, preRendered])

  useLayoutEffect(() => {
    if (preRendered) {
      const treeRoot = document.getElementById('pathway-tree-view')
      if (treeRoot) {
        treeRoot.scrollTo(scrollOffset.left, scrollOffset.top)
      }
    }
  }, [preRendered, scrollOffset.left, scrollOffset.top])

  useEffect(() => {
    if (preRendered && graphBoxHeights.height > 0) {
      renderDAG()
    }
  }, [graphBoxHeights.height, preRendered, renderDAG])

  useEffect(() => {
    renderDAGEdges()
  }, [dagNodes, renderDAGEdges])

  const probablyRenderTreeControls = useCallback(() => {
    const treeRoot = document.getElementById('pathway-tree-view')
    if (treeRoot === null) return null
    if (!renderTreeControls) return null

    const box = treeRoot.getBoundingClientRect()

    return (
      <div
        style={{
          position: 'fixed',
          top: `${box.top + window.scrollY + 8}px`,
          left: `${box.left + window.scrollX + 8}px`,
          right: '8px',
          height: 'auto',
          zIndex: 1,
        }}
      >
        {renderTreeControls()}
      </div>
    )
  }, [renderTreeControls])

  const graphWidth = g.graph()?.width ? `${g.graph().width * zoomLevel}px` : 'auto'
  const graphHeight = g.graph()?.height ? `${g.graph().height * zoomLevel}px` : 'auto'

  return preRendered ? (
    <>
      {probablyRenderTreeControls()}
      <View
        id="pathway-tree-view"
        as="div"
        height="100%"
        margin="0"
        position="relative"
        overflowY="auto"
      >
        <div
          style={{
            minWidth: graphWidth,
            minHeight: graphHeight,
            height: '100%',
            backgroundSize: '24px 24px',
            backgroundImage: `linear-gradient(to right, rgba(245, 245, 245, 1.0) 1px, transparent 1px),
                  linear-gradient(to bottom, rgba(245, 245, 245, 1.0) 1px, transparent 1px)`,
          }}
        >
          <View as="div" width="fit-content">
            <div
              style={{
                position: 'relative',
                padding: '.5rem',
                transform: `scale(${zoomLevel})`,
                transformOrigin: '0 0',
                minHeight: graphHeight,
              }}
            >
              <svg
                ref={svgRef}
                className="dag"
                viewBox={`${viewBox[0]} ${viewBox[1]} ${viewBox[2]} ${viewBox[3]}`}
                x={viewBox[0]}
                y={viewBox[1]}
                width={viewBox[2]}
                height={viewBox[3]}
              >
                {dagNodes}
                <g fill="none" stroke="#C7CDD1">
                  {dagEdges}
                </g>
              </svg>
            </div>
          </View>
        </div>
      </View>
    </>
  ) : (
    preRenderPathwayBoxes()
  )
}

export default PathwayTreeView
