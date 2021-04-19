# Canvas Engines

Welcome to the modular monolith.

## Recommended Reading

https://kellysutton.com/2020/03/12/how-to-break-apart-a-rails-monolith.html
https://medium.com/@dan_manges/the-modular-monolith-rails-architecture-fb1023826fc4

These are not gospel.  They are reasonable-sounding ideas we're trying out.
The theory is that they have a lower lift then fully extracting a service,
but are a good step down that road because of the way pulling out packages
forces you to reckon with your dependency graph.

As a side benefit, this can be done pretty incrementally, moving over a class
or a module at a time.

## What's in here?

Sets of functionality that are part of canvas, but that we want to be able to work
on without breaking other things.

In theory, each vertical component of canvas could be pulled out into an engine
so that it gets it's own test suite, and so that it's interactions with other
engines can be restricted in some way, forcing shared behavior into more modular packages.

It also over time may make dependencies between areas within the canvas code base
explicit and acyclic.  Time will tell whether we reap these benefits...

## Why isn't this stuff in gems/plugins?

Although the separation may not be perfect yet, thematically the idea would be that things
living in "gems/plugins" may actually override behavior inside canvas, of rails or of
other classes within the domain like reports or database access.

The engines living in this portion of the repo are intended to be chunks of functionality that
we're trying to dis-entangle from the app, and so should not
have things like a "spec_canvas" directory for tests that have to be run within the canvas context.