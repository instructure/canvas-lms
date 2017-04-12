import React from 'react'
import { shallow } from 'enzyme'
import MasqueradeModal from 'jsx/masquerade/MasqueradeModal'
import MasqueradeMask from 'jsx/masquerade/MasqueradeMask'
import MasqueradePanda from 'jsx/masquerade/MasqueradePanda'
import Link from 'instructure-ui/lib/components/Link'
import Spinner from 'instructure-ui/lib/components/Spinner'

QUnit.module('Masquerade Modal', {
  setup () {
    this.props = {
      user: {
        short_name: 'test user',
        id: '5'
      }
    }
  }
})

test('it renders with panda svgs and masquerade link present', function () {
  const wrapper = shallow(<MasqueradeModal {...this.props} />)
  const mask = wrapper.find(MasqueradeMask)
  const panda = wrapper.find(MasqueradePanda)
  const link = wrapper.find(Link)

  ok(mask.exists())
  ok(panda.exists())
  ok(link.exists())
})

test('it should only display loading spinner if state is loading', function (assert) {
  const done = assert.async()
  const wrapper = shallow(<MasqueradeModal {...this.props} />)
  notOk(wrapper.find(Spinner).exists())

  wrapper.setState({isLoading: true}, () => {
    ok(wrapper.find(Spinner).exists())
    done()
  })
})
