import firebase_admin
from firebase_admin import credentials
from firebase_admin import db

# Fetch the service account key JSON file contents
cred = credentials.Certificate('credentials/grayfox-6701c-firebase-adminsdk-3deoc-b3cd8d0cd5.json')

# Initialize the app with a service account, granting admin privileges
firebase_admin.initialize_app(cred, {
        'databaseURL': 'https://grayfox-6701c.firebaseio.com/'
    })

# As an admin, the app has access to read and write all data, regradless of Security Rules
ref = db.reference('writes/writetest')
ref.set("てすとやで")
