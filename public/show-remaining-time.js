
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
