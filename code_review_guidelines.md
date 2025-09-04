# Code Review Guidelines - Visual Search LTI App

## Overview

This document provides comprehensive code review guidelines for the Visual Search LTI App, a Node.js-based LTI 1.3 tool built with the ltijs library. These guidelines ensure code quality, security, maintainability, and compliance with LTI standards.

## General Principles

### 1. Security First
- **Authentication & Authorization**: All LTI endpoints must properly validate tokens and user permissions
- **Input Validation**: Sanitize and validate all user inputs, especially in grade submission endpoints
- **Secrets Management**: Never commit secrets to version control; use environment variables
- **SQL/NoSQL Injection**: Use parameterized queries and validate all database inputs
- **XSS Prevention**: Escape output and validate HTML content in comments/feedback

### 2. LTI 1.3 Compliance
- **Token Validation**: Always validate LTI tokens using `res.locals.token`
- **Platform Context**: Check for required platformContext properties before use
- **Grade Passback**: Follow LTI AGS (Assignment and Grade Services) specifications
- **Deep Linking**: Implement proper deep linking workflows when applicable
- **Privacy**: Respect user privacy and data minimization principles

### 3. Error Handling
- **Comprehensive Logging**: Use structured logging with request IDs for traceability
- **Graceful Degradation**: Handle missing LTI context gracefully
- **User-Friendly Messages**: Return meaningful error messages without exposing internals
- **Stack Traces**: Log full stack traces for debugging while sanitizing client responses

## Code Style and Structure

### File Organization
```
src/
├── routes.js          # Express routes with LTI middleware
├── logger.js          # Winston logging configuration
├── middleware/        # Custom middleware (if added)
├── services/          # Business logic services (if added)
└── utils/             # Utility functions (if added)
```

### Naming Conventions
- **Variables**: Use camelCase (`lineItemId`, `gradeObj`)
- **Functions**: Use descriptive names (`submitGradeWithComment`, `validateLtiToken`)
- **Constants**: Use UPPER_SNAKE_CASE (`MAX_GRADE_VALUE`, `DEFAULT_TIMEOUT`)
- **Files**: Use kebab-case for new files (`grade-service.js`, `lti-middleware.js`)

### Import/Export Standards
```javascript
// ✅ Good: Use ES6 imports consistently
import express from 'express';
import { Provider as lti } from 'ltijs';
import logger from './logger.js';

// ✅ Good: Use default exports for single-purpose modules
export default router;

// ✅ Good: Use named exports for utilities
export { validateGrade, formatComment };
```

## API Design

### Route Structure
```javascript
// ✅ Good: Consistent error handling pattern
router.post('/grade', async (req, res) => {
  try {
    const idtoken = res.locals.token;
    // ... implementation
    logger.info(`[${req.requestId}] Grade submitted successfully`);
    return res.send(response);
  } catch (err) {
    logger.error(`[${req.requestId}] Error: ${err.message}\nStack: ${err.stack}`);
    return res.status(500).send({ err: err.message });
  }
});
```

### Request/Response Format
- **Request Validation**: Validate required fields and data types
- **Response Consistency**: Use consistent response formats
- **HTTP Status Codes**: Use appropriate status codes (200, 400, 401, 500)
- **Content-Type**: Set proper content-type headers

## Database Interactions

### MongoDB Best Practices
```javascript
// ✅ Good: Use connection string with proper authentication
const mongoUrl = `mongodb://${user}:${pass}@${host}:${port}/${db}?authSource=admin`;

// ✅ Good: Handle connection errors gracefully
try {
  await lti.setup(ltiKey, { url: mongoUrl }, options);
} catch (err) {
  logger.error(`Database connection failed: ${err.message}`);
  process.exit(1);
}
```

### Data Validation
- Validate all database inputs
- Use proper data types for grades (Number, not string)
- Include timestamps for audit trails
- Validate user IDs and resource IDs

## Logging Standards

### Log Levels
- **error**: System errors, failed operations, exceptions
- **warn**: Recoverable errors, deprecation warnings
- **info**: Successful operations, user actions, startup events
- **debug**: Detailed debugging information, request/response details

### Log Format
```javascript
// ✅ Good: Include request ID for traceability
logger.info(`[${req.requestId}] ${action} successful for user ${userId}`);
logger.error(`[${req.requestId}] ${operation} failed: ${err.message}\nStack: ${err.stack}`);

// ✅ Good: Log important business events
logger.info(`[${req.requestId}] Grade ${grade} submitted for user ${userId}`);
```

### Sensitive Data
- **Never log**: Passwords, tokens, personal identifiable information
- **Redact**: Email addresses, user names in production logs
- **Sanitize**: Request bodies containing sensitive data

## Testing Requirements

### Unit Tests
```javascript
// Required test coverage for new features
describe('Grade Submission', () => {
  it('should validate grade range', () => {
    // Test grade validation logic
  });
  
  it('should handle missing platformContext', () => {
    // Test error handling
  });
});
```

### Integration Tests
- Test LTI token validation
- Test database connections
- Test grade submission workflow
- Test error scenarios

### Test Data
- Use mock LTI tokens for testing
- Create test users and contexts
- Use separate test database
- Clean up test data after runs

## Environment Configuration

### Required Environment Variables
```bash
# Database
DB_USER=
DB_PASS=
DB_NAME=
DB_HOST=

# LTI Configuration
LTI_KEY=
PLATFORM_URL=
PLATFORM_CLIENT_ID=

# Tool Provider
TOOL_PROVIDER_URL=
TOOL_PROVIDER_NAME=
```

### Configuration Validation
```javascript
// ✅ Good: Validate required environment variables
const requiredEnvVars = ['LTI_KEY', 'DB_NAME', 'PLATFORM_URL'];
for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    logger.error(`Missing required environment variable: ${envVar}`);
    process.exit(1);
  }
}
```

## Performance Considerations

### Response Times
- LTI launches should complete within 10 seconds
- Grade submissions should complete within 5 seconds
- Database queries should be optimized and indexed

### Resource Usage
- Monitor memory usage with large user bases
- Implement connection pooling for database
- Use appropriate timeout values
- Cache static resources properly

## Security Checklist

### Before Merge
- [ ] All secrets moved to environment variables
- [ ] Input validation implemented for all endpoints
- [ ] LTI token validation in place
- [ ] Error messages don't expose sensitive information
- [ ] Logging doesn't include sensitive data
- [ ] Database queries use proper parameterization
- [ ] HTTPS enforced in production configuration

### LTI-Specific Security
- [ ] Proper OIDC flow implementation
- [ ] JWT signature verification
- [ ] Nonce validation to prevent replay attacks
- [ ] Platform validation against registered platforms
- [ ] Proper scope validation for API calls

## Deployment and DevOps

### Docker Guidelines
- Use specific version tags, not `latest`
- Multi-stage builds for smaller images
- Non-root user in containers
- Health checks implemented
- Proper secret handling in containers

### Production Readiness
- Environment-specific configurations
- Proper logging levels for production
- Health check endpoints
- Graceful shutdown handling
- Resource limits configured

## Code Review Process

### Reviewer Checklist
1. **Functionality**: Does the code meet requirements?
2. **Security**: Are security guidelines followed?
3. **Performance**: Are there any performance concerns?
4. **Maintainability**: Is the code readable and well-documented?
5. **Testing**: Are tests adequate and passing?
6. **LTI Compliance**: Does it follow LTI 1.3 standards?

### Required Approvals
- All code must be reviewed by at least one other developer
- Security-sensitive changes require security team review
- LTI-related changes require LTI expertise review
- Database schema changes require DBA review

## Documentation Requirements

### Code Documentation
```javascript
/**
 * Submits a grade for a user through LTI AGS
 * @param {Object} idtoken - LTI ID token containing user and context
 * @param {number} grade - Numeric grade value (0-10000)
 * @param {string} comment - Optional feedback comment
 * @returns {Promise<Object>} Grade submission response
 */
async function submitGrade(idtoken, grade, comment) {
  // Implementation
}
```

### API Documentation
- Document all endpoints with request/response examples
- Include authentication requirements
- Specify rate limits and error codes
- Provide integration examples

### Configuration Documentation
- Document all environment variables
- Include deployment instructions
- Provide troubleshooting guides
- Maintain change logs

## Common Anti-Patterns to Avoid

### ❌ Bad Practices
```javascript
// Don't hardcode secrets
const ltiKey = "supersecret";

// Don't ignore errors
router.post('/grade', async (req, res) => {
  await lti.Grade.submitScore(token, lineItemId, grade);
  res.send('OK');
});

// Don't log sensitive data
logger.info(`User password: ${password}`);

// Don't use console.log in production
console.log('Debug info');
```

### ✅ Good Practices
```javascript
// Use environment variables
const ltiKey = process.env.LTI_KEY;

// Proper error handling
try {
  const response = await lti.Grade.submitScore(token, lineItemId, grade);
  return res.send(response);
} catch (err) {
  logger.error(`Grade submission failed: ${err.message}`);
  return res.status(500).send({ err: 'Grade submission failed' });
}

// Use structured logging
logger.info(`[${requestId}] Grade submitted for user ${userId}`);
```

## Tools and Automation

### Recommended Tools
- **Linting**: ESLint with security plugins
- **Formatting**: Prettier for consistent code style
- **Testing**: Jest or Mocha for unit tests
- **Security**: npm audit, Snyk for vulnerability scanning
- **Documentation**: JSDoc for code documentation

### CI/CD Pipeline
- Automated testing on all pull requests
- Security scanning before deployment
- Code quality checks (coverage, complexity)
- Automated deployment to staging
- Manual approval for production deployment

## Questions for Code Review

### Functionality Questions
- Does this code handle all LTI launch scenarios?
- Are all required LTI parameters validated?
- Does the grade submission follow AGS specifications?
- Are error cases properly handled?

### Security Questions
- Are user inputs properly validated and sanitized?
- Is the LTI token properly verified?
- Are secrets properly managed?
- Could this code lead to data exposure?

### Performance Questions
- Are database queries optimized?
- Could this code cause memory leaks?
- Are there any blocking operations?
- Is caching used appropriately?

---

## Updates and Maintenance

This document should be updated when:
- New LTI standards are adopted
- Security vulnerabilities are discovered
- Development practices change
- New tools are introduced
- Compliance requirements change

Last updated: [Current Date]
Version: 1.0