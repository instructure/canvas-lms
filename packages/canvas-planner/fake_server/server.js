const generateData = require('./db');
const jsonServer = require('json-server');
const server = jsonServer.create();
const router = jsonServer.router(generateData());
const rewriter = jsonServer.rewriter(require('./routes.json'));
const middlewares = jsonServer.defaults();
const pause = require('connect-pause');
const dateRewriter = require('./dateRewriter');
const plannerNoteRewriter = require('./plannerNoteRewriter');
const plannerOpportunityRewriter = require('./plannerOpportunityRewriter');

// Set default middlewares (logger, static, cors and no-cache)
server.use(middlewares);


// To handle POST, PUT and PATCH
server.use(jsonServer.bodyParser);

// Use the routes.json file for custom routes re-routing
server.use(rewriter);

// Slow things down
server.use(pause(1500));

// Custom middlewares
server.use(dateRewriter);
server.use(plannerNoteRewriter);
server.use(plannerOpportunityRewriter);



// Use default router
server.use(router);
server.listen(3004, () => {
  console.log('JSON Server is running');
});
