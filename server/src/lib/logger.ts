import pino from 'pino';

const isDevelopment = process.env.NODE_ENV === 'development';

export const logger = pino({
  level: process.env.LOG_LEVEL || (isDevelopment ? 'debug' : 'info'),
  transport: isDevelopment
    ? {
        target: 'pino-pretty',
        options: {
          colorize: true,
          translateTime: 'HH:MM:ss Z',
          ignore: 'pid,hostname',
        },
      }
    : undefined,
  formatters: {
    level: (label) => {
      return { level: label };
    },
  },
  timestamp: pino.stdTimeFunctions.isoTime,
});

export interface LogContext {
  userId?: string;
  requestId?: string;
  endpoint?: string;
  method?: string;
  statusCode?: number;
  processingTime?: number;
  error?: Error | unknown;
  [key: string]: any;
}

export const logRequest = (context: LogContext) => {
  logger.info(context, 'API Request');
};

export const logError = (context: LogContext) => {
  const error = context.error;
  if (error instanceof Error) {
    logger.error(
      {
        ...context,
        error: {
          message: error.message,
          stack: error.stack,
          name: error.name,
        },
      },
      'Error occurred'
    );
  } else {
    logger.error(context, 'Error occurred');
  }
};

export const logInfo = (message: string, context?: LogContext) => {
  logger.info(context || {}, message);
};

export const logWarn = (message: string, context?: LogContext) => {
  logger.warn(context || {}, message);
};

export const logDebug = (message: string, context?: LogContext) => {
  logger.debug(context || {}, message);
};

export default logger;
