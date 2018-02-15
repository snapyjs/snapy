{test} = require "../src/snapy-client.coffee"
console.log "stdout outside of tests"
test (snap) =>
  ###
    in snapy2
  ###
  snap(obj: 
    unchanged:
      block: true
      block2: true
    date: Date.now()
  ).then =>
    ###
      still in snapy2
    ###
    snap obj: 
      position: "sibling"
      date: Date.now()
test (snap) =>
  # next test in snapy2
  console.log "test in test"
  snap obj: true
  