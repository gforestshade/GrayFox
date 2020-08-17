
const dataObj = document.getElementById('data');
const writeObj = document.getElementById('write');
let writeBuffer = "";
let login_user = null;

function login(token)
{
    firebase.auth().setPersistence(firebase.auth.Auth.Persistence.NONE)
	.then(() => firebase.auth().signInWithCustomToken(token))
	.then(credential => {
	    login_user = credential.user;
            console.log("logged in as " + login_user.uid);
            firebase.database()
		.ref('/writes/' + login_user.uid)
		.once('value')
		.then(ss => {
                    writeBuffer = ss.val();
                    writeObj.value = writeBuffer;
		    writeObj.disabled = false;
		});
	})
	.catch(error => {
            var errorCode = error.code;
            var errorMessage = error.message;

            console.error(errorMessage);
	    alert("前の人の原稿を取得する処理に失敗しました。");
	    location.href = "/home";
	});
}


function save()
{
    return new Promise((resolve, reject) => {
	if (!login_user) reject("not logged in");
	if (writeBuffer == writeObj.value) resolve(false);
	
	firebase.database()
            .ref('/writes/' + login_user.uid)
            .set(writeObj.value, e => {
		if (e)
		{
		    reject("failed to save");
		}
		else
		{
                    writeBuffer = writeObj.value;
                    console.log("submit");
		    resolve(true);
		}
            });
    });
}

function goto(url)
{
    save()
	.then(result => {
	    location.href = url;
	})
	.catch(error => {
	    alert("保存処理に失敗しました。原稿を退避して、もう一度お試しください。");
	});
}

login(dataObj.dataset.customToken);

setInterval(save, 10000);

