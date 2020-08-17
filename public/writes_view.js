
const dataObj = document.getElementById('data');
const writeObj = document.getElementById('write-view');


function login(token)
{
    firebase.auth().setPersistence(firebase.auth.Auth.Persistence.NONE)
	.then(() => firebase.auth().signInWithCustomToken(token))
	.then(credential => {
	    const login_user = credential.user;
            console.log("logged in as " + login_user.uid);
	    
            firebase.database()
		.ref('/writes/' + login_user.uid)
		.on('value', ss => {
		    console.log(ss.val());
                    writeObj.innerHTML = ss.val().replace(/\n/g, '<br>');
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


login(dataObj.dataset.customToken);


