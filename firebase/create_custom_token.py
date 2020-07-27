import sys
import os
import firebase_admin
from firebase_admin import credentials
from firebase_admin import auth


# Fetch the service account key JSON file contents
credential_path = os.path.join(os.path.dirname(__file__),
    'credentials/grayfox-6701c-firebase-adminsdk-3deoc-b3cd8d0cd5.json')
cred = credentials.Certificate(credential_path)

# Initialize the app with a service account, granting admin privileges
firebase_admin.initialize_app(cred, {
        'databaseURL': 'https://grayfox-6701c.firebaseio.com/'
    })


F = sys.stdin
uid = F.readline()
additional_claims = {}

token = auth.create_custom_token(uid, additional_claims)

print(token.decode('ascii'))
