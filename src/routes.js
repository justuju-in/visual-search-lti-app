import express from 'express';
import path from 'path';
import { Provider as lti } from 'ltijs';
import { dirname } from 'path';
import { fileURLToPath } from 'url';
import logger from './logger.js';
import { randomUUID } from 'crypto';

const __dirname = dirname(fileURLToPath(import.meta.url));
const router = express.Router();

// Logging middleware to debug incoming requests
// Add a request ID to each request for traceability
router.use((req, res, next) => {
  req.requestId = randomUUID();
  next();
});

// Enhanced logging middleware
router.use((req, res, next) => {
  logger.info(`[${req.requestId}] ${req.method} ${req.originalUrl}`);
  logger.debug(`[${req.requestId}] Headers: ${JSON.stringify(req.headers)}`);
  if (req.body && Object.keys(req.body).length) {
    logger.debug(`[${req.requestId}] Body: ${JSON.stringify(req.body)}`);
  }
  next();
});

// Grading route
router.post('/grade', async (req, res) => {
try {
    const idtoken = res.locals.token; // IdToken
    // Accept grade and comment from request body
    const { grade, comment } = req.body;
    // Creating Grade object with timestamp and comment
    const gradeObj = {
      userId: idtoken.user,
      scoreGiven: Number(grade),
      scoreMaximum: 10000,
      activityProgress: "Completed",
      gradingProgress: "FullyGraded",
      comment: comment, // Optional feedback
      timestamp: new Date().toISOString()
    };
  logger.info(`[${req.requestId}] Submitting grade object: ${JSON.stringify(gradeObj)}`);

    // Defensive checks for platformContext and endpoint
    if (!idtoken.platformContext || !idtoken.platformContext.endpoint) {
  logger.error(`[${req.requestId}] platformContext or endpoint is undefined: ${JSON.stringify(idtoken.platformContext)}`);
      return res.status(400).send({ err: 'platformContext or endpoint is undefined' });
    }

    // Selecting linetItem ID
    let lineItemId = idtoken.platformContext.endpoint.lineitem; // Attempting to retrieve it from idtoken
    if (!lineItemId) {
      const response = await lti.Grade.getLineItems(idtoken, {
        resourceLinkId: true,
      });
      const lineItems = response.lineItems;
      if (lineItems.length === 0) {
        // Creating line item if there is none
        logger.info(`[${req.requestId}] Creating new line item`);
        if (!idtoken.platformContext.resource) {
          logger.error(`[${req.requestId}] platformContext.resource is undefined: ${JSON.stringify(idtoken.platformContext)}`);
          return res.status(400).send({ err: 'platformContext.resource is undefined' });
        }
        const newLineItem = {
          scoreMaximum: 10000,
          label: "Grade",
          tag: "grade",
          resourceLinkId: idtoken.platformContext.resource.id,
        };
        const lineItem = await lti.Grade.createLineItem(idtoken, newLineItem);
        lineItemId = lineItem.id;
      } else lineItemId = lineItems[0].id;
    }

    // Sending Grade
    const responseGrade = await lti.Grade.submitScore(
      idtoken,
      lineItemId,
      gradeObj
    );
  logger.info(`[${req.requestId}] Grade submitted successfully for user ${gradeObj.userId}`);
  return res.send(responseGrade);
  } catch (err) {
  logger.error(`[${req.requestId}] Grade submission error: ${err.message}\nStack: ${err.stack}`);
  return res.status(500).send({ err: err.message });
  }
});

// Wildcard route to deal with redirecting to React routes
// router.get('*', (req, res) => res.sendFile(path.join(__dirname, '../public/index.html')))

export default router;
