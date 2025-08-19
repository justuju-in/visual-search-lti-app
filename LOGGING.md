# Beginner-Friendly Log Capturing

## How Logging Works
- All important events and errors are logged using the `winston` logger.
- Logs are written to both the console (for easy viewing during development) and to a file at `logs/app.log` (for production and troubleshooting).

## Viewing Logs
- **Development:**
  - Just run your app as usual. Logs will appear in your terminal.
- **Production:**
  - Check the file `logs/app.log` for all logs.
  - You can use commands like `tail -f logs/app.log` to watch logs live.

## Changing Log Level
- Set the environment variable `LOG_LEVEL` to control verbosity (e.g., `info`, `debug`, `error`).
- Example: `LOG_LEVEL=debug npm start`

## Example Log Output
```
[2025-08-19T12:00:00.000Z] info: LTI provider deployed on port 3000
[2025-08-19T12:00:01.000Z] info: Moodle platform registered
[2025-08-19T12:00:02.000Z] error: platformContext or endpoint is undefined: {...}
```

## Troubleshooting
- If you don’t see logs, make sure the `logs` directory exists and is writable.
- For more details, set `LOG_LEVEL=debug`.
