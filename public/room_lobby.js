

function deleteAllChildren(node)
{
    while (node.firstChild)
    {
        node.removeChild(node.lastChild);
    }
}

function updateRoom()
{
    const objH1 = document.getElementById('h1-title');    
    const objListUsers = document.getElementById('list-users');
    console.log(objH1)
    console.log(objListUsers)
    
    const hash = objH1.dataset.hash;
    
    const req = '/rooms/0/'+ hash + '/info';
    const p = {credentials: 'same-origin'};
    fetch(req, p)
        .then(res => {
            if (!res.ok) throw new Error(`Fetch: ${res.status} ${res.statusText}`);
            return res.json();
        })
        .then(json => {
	    if (json.phase >= 0) location.replace('/writes/' + json.writes[json.current_write_index]);
	    
            let fr = document.createDocumentFragment();

            for (const n of json.users)
            {
                const li = document.createElement('li');
                text = '';
                if (json.host_name == n)
                    text = "(Host)";
                if (json.my_name == n)
                    li.class = "name-me";

                text += n;
                li.innerText = text;
                fr.appendChild(li);
            }

            deleteAllChildren(objListUsers)
            objListUsers.appendChild(fr);
        })
        .catch(e => console.error(e))
}

let updateTickId = setInterval(updateRoom, 5000);
setTimeout(updateRoom, 10);
