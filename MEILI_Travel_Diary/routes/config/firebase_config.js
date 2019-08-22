var admin = require("firebase-admin");

var serviceAccount = {
  "type": "service_account",
  "project_id": "secret",
  "private_key_id": "secret",
  "private_key": "-----BEGIN PRIVATE KEY-----\nsecret\n-----END PRIVATE KEY-----\n",
  "client_email": "secret",
  "client_id": "secret",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "secret"
};

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: "secret"
});

module.exports = admin;