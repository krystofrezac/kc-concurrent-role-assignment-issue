import http from 'k6/http';
import { check } from 'k6';

export const options = {
  scenarios: {
    concurrent_assignment: {
      executor: 'shared-iterations',
      vus: 20,
      iterations: 20,
      maxDuration: '30s',
    },
  },
};

export default function () {
  const keycloakUrl = __ENV.KEYCLOAK_URL;
  const realm = __ENV.REALM;
  const userId = __ENV.USER_ID;
  const accessToken = __ENV.ACCESS_TOKEN;
  const roleResponse = __ENV.ROLE_RESPONSE;

  const url = `${keycloakUrl}/admin/realms/${realm}/users/${userId}/role-mappings/realm`;
  const payload = `[${roleResponse}]`;
  const headers = {
    'Authorization': `Bearer ${accessToken}`,
    'Content-Type': 'application/json',
  };

  const response = http.post(url, payload, { headers });

  console.log(`VU ${__VU} - Status: ${response.status} - Body: ${response.body || '(empty)'}`);

  check(response, {
    'status is 204 or 409': (r) => r.status === 204 || r.status === 409,
  });
}
