import express from 'express';
import path from 'path';
import { Provider as lti } from 'ltijs';
import { dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const router = express.Router();

// Logging middleware to debug incoming requests
router.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl}`);
  console.log('Headers:', req.headers);
  if (req.body && Object.keys(req.body).length) {
    console.log('Body:', req.body);
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
    console.log('Submitting grade object:', gradeObj);

    // Defensive checks for platformContext and endpoint
    if (!idtoken.platformContext || !idtoken.platformContext.endpoint) {
      console.error('platformContext or endpoint is undefined:', idtoken.platformContext);
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
        console.log("Creating new line item");
        if (!idtoken.platformContext.resource) {
          console.error('platformContext.resource is undefined:', idtoken.platformContext);
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
    return res.send(responseGrade);
  } catch (err) {
    return res.status(500).send({ err: err.message });
  }
});

// Wildcard route to deal with redirecting to React routes
// router.get('*', (req, res) => res.sendFile(path.join(__dirname, '../public/index.html')))

export default router;
