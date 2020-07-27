
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


const dataObj = document.getElementById('data');
login(dataObj.dataset.customToken);

function zeroPadding(n, l){
    return (Array(l).join('0') + n).slice(-l);
}

const remainingTimeObj = document.getElementById('remaining-time');
setInterval(() => {
    let diff = remainingTimeObj.dataset.expire - Math.floor(Date.now() / 1000);
    let op = '';
    if (diff < 0)
    {
	op = '-';
	diff = -diff;
    }
    const seconds = diff % 60;
    const minites = Math.floor(diff / 60);
    remainingTimeObj.innerText = sprintf('%s%02d:%02d', op, minites, seconds);
}, 200);

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

