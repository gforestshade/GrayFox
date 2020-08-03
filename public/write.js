
function login(token)
{
    firebase.auth().signInWithCustomToken(token)
    .catch(error => {
        // Handle Errors here.
        var errorCode = error.code;
        var errorMessage = error.message;
        // ...
        console.error(errorMessage);
    });
}

let login_user = null;
firebase.auth().onAuthStateChanged(user => {
    if (user)
    {
        login_user = user;
        console.log("logged in as " + user.uid);
        firebase.database()
            .ref('/writes/' + login_user.uid)
            .once('value')
            .then(ss => {
                writeBuffer = ss.val();
                writeObj.value = writeBuffer;
            });
    }
    else
    {
        // User is signed out.
	//location.assign('/home');
    }
    
});

function goto(url)
{
    location.href = url;
}

const dataObj = document.getElementById('data');
login(dataObj.dataset.customToken);

const writeObj = document.getElementById('write');
let writeBuffer = "";
setInterval(() => {
    if (!login_user) return;
    if (writeBuffer == writeObj.value) return;
    
    firebase.database()
        .ref('/writes/' + login_user.uid)
        .set(writeObj.value, e => {
            if (!e)
            {
                writeBuffer = writeObj.value;
                console.log("submit");
            }
        });
}, 10000);

