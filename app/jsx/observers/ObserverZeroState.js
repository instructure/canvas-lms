import React from 'react'
import styled from 'styled-components'

const Zero = styled.div`
    padding: 0.75rem;
    text-align: center;
    width: 100%;

    object {
        max-width: 13rem;
    }

    p {
        color: #676767;
        font-size: 12px;
        margin: 0;
    }

    .zero-state-emphasis {
        color: #444444;
        font-size: 14px;
        font-weight: bold;
        margin: 0.3rem 0;
    }
`

class ObserverZeroState extends React.Component {
    constructor(props) {
        super(props);
    }

    render() {
        return(
            <Zero>
                <object type="image/svg+xml" data="../images/svg_illustrations/sunny.svg"></object>
                <p className="zero-state-emphasis">It looks like you're not observing any students right now!</p>
                <p>If you feel this is an error, please contact an administrator.</p>
            </Zero>
        );
    }
}

export default ObserverZeroState