export type DocStatus = 'UPLOADED' | 'PROCESSING' | 'COMPLETED' | 'FAILED';
export type Permission = 'VIEW' | 'EDIT';
export type Role = 'USER' | 'ADMIN';

export interface DocumentDto {
  id: string;
  userId: string;
  title: string;
  fileKey: string;
  fileType: string;
  fileSize: number;
  status: DocStatus;
  classification: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface CreateDocumentResponse {
  document: DocumentDto;
  // S3 presigned URL — frontend uploads directly to S3, never through the backend
  uploadUrl: string;
}

export interface ProcessingStatus {
  status: DocStatus;
  progress: number;
  error?: string;
}
