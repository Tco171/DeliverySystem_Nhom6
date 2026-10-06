import { api as realApi } from './api.real';
import { mockApi } from './api.mock';
export * from './api.real';
export const MOCK_MODE = import.meta.env.VITE_USE_MOCK === 'true';
export const api: typeof realApi = MOCK_MODE ? mockApi : realApi;
