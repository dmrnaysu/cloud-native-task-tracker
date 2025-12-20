import axios from "axios";

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL
});

export function setAuthToken(token: string | null) {
  if (token) api.defaults.headers.common["Authorization"] = Bearer ;
  else delete api.defaults.headers.common["Authorization"];
}
