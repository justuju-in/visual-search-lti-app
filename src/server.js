
import path from "path";
import { fileURLToPath } from "url";
import { Provider } from "ltijs";
import routes from "./src/routes.js";
import dotenv from "dotenv";
import logger from "./src/logger.js";
dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const lti = Provider;

// 1. Setup the LTI provider (with local MongoDB container)
await lti.setup(
  process.env.LTI_KEY || "supersecret", // JWT secret
  {
    url: `mongodb://${process.env.DB_USER || "root"}:${process.env.DB_PASS || "secret123"}@${process.env.DB_HOST || "localhost"}:27017/${process.env.DB_NAME || "visualsearchdb"}?authSource=admin`,
    options: {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    },
  },
  {
    appRoute: "/",
    loginRoute: "/login",
    //keysetRoute: '/keys',
    cookies: {
      secure: false,
      sameSites: "None",
    },
    staticPath: path.join(__dirname, "./public"),
    devMode: true,
    dynRegRoute: "/register", // Setting up dynamic registration route. Defaults to '/register'
    dynReg: {
  url: process.env.TOOL_PROVIDER_URL, // Tool Provider URL. Required field.
  name: process.env.TOOL_PROVIDER_NAME, // Tool Provider name. Required field.
  logo: process.env.TOOL_PROVIDER_LOGO, // Tool Provider logo URL.
  description: process.env.TOOL_PROVIDER_DESCRIPTION, // Tool Provider description.
  redirectUris: process.env.TOOL_PROVIDER_REDIRECT_URIS ? process.env.TOOL_PROVIDER_REDIRECT_URIS.split(",") : [], // Comma-separated list in .env
  //customParameters: { key: 'value' }, // Custom parameters.
  autoActivate: process.env.TOOL_PROVIDER_AUTO_ACTIVATE === "true", // Defaults to false
    },
  }
);

// 2. Define behavior when the tool is launched
lti.onConnect((token, req, res) => {
  res.sendFile(path.join(__dirname, "./public/index.html"));
});
// Use the routes defined in routes.js
lti.app.use(routes);

const setup = async () => {
  // 3. Deploy the provider first — this must come before registering platforms!
  try {
    await lti.deploy({ port: 3000 });
    logger.info("[startup] LTI provider deployed on port 3000");

    // Register LMS platform using environment variables
    await lti.registerPlatform({
      url: process.env.PLATFORM_URL,
      name: process.env.PLATFORM_NAME,
      clientId: process.env.PLATFORM_CLIENT_ID,
      authenticationEndpoint: process.env.PLATFORM_AUTH_ENDPOINT,
      accesstokenEndpoint: process.env.PLATFORM_TOKEN_ENDPOINT,
      authConfig: {
        method: "JWK_SET",
        key: process.env.PLATFORM_KEYSET_ENDPOINT,
      },
    });
    logger.info(`[startup] Platform registered: ${process.env.PLATFORM_NAME}`);
  } catch (err) {
    logger.error(`[startup] Fatal error: ${err.message}\nStack: ${err.stack}`);
    process.exit(1);
  }
};

setup();
// Log uncaught exceptions and shutdown events
process.on('uncaughtException', (err) => {
  logger.error(`[uncaughtException] ${err.message}\nStack: ${err.stack}`);
  process.exit(1);
});
process.on('SIGTERM', () => {
  logger.info('[shutdown] Received SIGTERM, shutting down.');
  process.exit(0);
});
process.on('SIGINT', () => {
  logger.info('[shutdown] Received SIGINT, shutting down.');
  process.exit(0);
});
