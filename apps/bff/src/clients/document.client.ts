import { HttpClient } from './http.client';
import {
  CreateDocumentResponse,
  DocumentDto,
  PaginatedResponse,
  ProcessingStatus,
} from '@docuvault/shared-types';

interface CreateDocumentBody {
  title: string;
  fileType: string;
  fileSize: number;
}

interface UpdateDocumentBody {
  title?: string;
  tags?: string[];
}

interface ShareDocumentBody {
  email: string;
  permission: 'VIEW' | 'EDIT';
}

export class DocumentClient extends HttpClient {
  constructor(baseUrl: string) {
    super(baseUrl, 'document-service');
  }

  createDocument(body: CreateDocumentBody, token: string, requestId: string) {
    return this.post<CreateDocumentResponse>('/documents', body, {
      headers: this.headers(requestId, token),
    });
  }

  listDocuments(query: Record<string, string>, token: string, requestId: string) {
    return this.get<PaginatedResponse<DocumentDto>>('/documents', {
      headers: this.headers(requestId, token),
      params: query,
    });
  }

  getDocument(id: string, token: string, requestId: string) {
    return this.get<DocumentDto>(`/documents/${id}`, {
      headers: this.headers(requestId, token),
    });
  }

  updateDocument(id: string, body: UpdateDocumentBody, token: string, requestId: string) {
    return this.put<DocumentDto>(`/documents/${id}`, body, {
      headers: this.headers(requestId, token),
    });
  }

  deleteDocument(id: string, token: string, requestId: string) {
    return this.delete<void>(`/documents/${id}`, {
      headers: this.headers(requestId, token),
    });
  }

  shareDocument(id: string, body: ShareDocumentBody, token: string, requestId: string) {
    return this.post<void>(`/documents/${id}/share`, body, {
      headers: this.headers(requestId, token),
    });
  }

  getDocumentStatus(id: string, token: string, requestId: string) {
    return this.get<ProcessingStatus>(`/documents/${id}/status`, {
      headers: this.headers(requestId, token),
    });
  }
}
