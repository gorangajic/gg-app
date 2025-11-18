import { prisma } from './prisma';
import { NextRequest } from 'next/server';

export interface RequestHistoryData {
  userId: string;
  endpoint: string;
  method: string;
  statusCode: number;
  processingTime: number;
  requestData?: any;
  responseData?: any;
  ipAddress?: string;
  userAgent?: string;
}

export async function logRequestHistory(data: RequestHistoryData): Promise<void> {
  try {
    await prisma.requestHistory.create({
      data: {
        userId: data.userId,
        endpoint: data.endpoint,
        method: data.method,
        statusCode: data.statusCode,
        processingTime: data.processingTime,
        requestData: data.requestData ? JSON.stringify(data.requestData) : null,
        responseData: data.responseData ? JSON.stringify(data.responseData) : null,
        ipAddress: data.ipAddress,
        userAgent: data.userAgent,
      },
    });
  } catch (error) {
    // Log error but don't throw - request history logging should not fail the request
    console.error('Failed to log request history:', error);
  }
}

export function getClientInfo(request: NextRequest): {
  ipAddress?: string;
  userAgent?: string;
} {
  const forwarded = request.headers.get('x-forwarded-for');
  const ipAddress = forwarded ? forwarded.split(',')[0] : request.ip;
  const userAgent = request.headers.get('user-agent') || undefined;

  return { ipAddress, userAgent };
}
