import React from "react"

export default function Pointer() {
  const styles = {
    width: "10px",
    height: "10px",
    border: "1px solid rgba(0, 0, 0, 0.6)",
    borderRadius: "6px",
    transform: "translate(-6px, -1px)",
    backgroundColor: "rgb(248, 248, 248)",
    boxShadow: "0 1px 4px 0 rgba(0, 0, 0, 0.37)"
  }

  return <div style={styles} />
}
