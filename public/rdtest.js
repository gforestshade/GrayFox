

function login(token)
{
    firebase.auth().signInWithCustomToken(token)
    .catch( error => {
        // Handle Errors here.
        var errorCode = error.code;
        var errorMessage = error.message;
        // ...
        console.error(errorMessage);
    });
}

let login_user = null;
firebase.auth().onAuthStateChanged(user => {
    if (user) {
        login_user = user;
        console.log("logged in as " + user.uid);
        firebase.database()
            .ref('/write/' + login_user.uid)
            .once('value')
            .then(ss => {
                writeBuffer = ss.val();
                writeObj.value = writeBuffer
            });
    } else {
        // User is signed out.
    }
    
});

fetch('/auth/firebase', {credentials: 'same-origin'})
    .then(responce => responce.text())
    .then(login);


const writeObj = document.getElementById('write');
let writeBuffer = "";
setInterval(() => {
    if (!login_user) return;
    if (writeBuffer == writeObj.value) return;
    
    firebase.database()
        .ref('/write/' + login_user.uid)
        .set(writeObj.value, e => {
            if (!e)
            {
                writeBuffer = writeObj.value;
                console.log("submit");
            }
        });
}, 10000);

