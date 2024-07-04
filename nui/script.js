window.addEventListener('load', function () {
    var resourceName = GetParentResourceName();
    var beepAudio = new Audio('pager_beeps.mp3');
    var grabAudio = new Audio('grabPager.mp3');
    var textElement = document.getElementById("text");
    var pagerElement = document.getElementById("pager");
    var reminderElement = document.getElementById('reminder');
    var saveContactElement = document.getElementById('saveContact');
    var saveMessage = "save";
    var deleteMessage = "delete";
    let currentInteraction = null;
    beepAudio.volume=0.3;
    grabAudio.volume=1.0;
    var t=null;

    /* Eventlisteners lua->js communication */
    window.addEventListener('message', (event) => {
        let data = event.data
        if (data.action === 'pagerShowMessageSimple'){
            pagerShowMessageSimple(data.text);
        } else if(data.action === 'pagerReceived') {
            pagerReceived(data.text);
        } else if(data.action === 'pagerElapssed'){
            pagerElapssed();
        } else if (data.action === 'pagerShowMessage') {
            pagerShowMessage(data.text, data.showReminder);
        } else if (data.action == 'pagerShowContact') {
            pagerShowContact(data.text, data.showReminder);
        }
    })

    /* Shows the given text */
    function pagerShowMessageSimple(text){
        textElement.innerHTML = text;
        pagerElement.style.display = "block";
        // t=setTimeout(()=>{
        //     grabAudio.play();
        // }, 300);
    }

    /* Shows the given text, plays an audio and closes the pager */
    function pagerReceived(text){
        pagerShowMessageSimple(text)
        beepAudio.play();

        t=setTimeout(()=>{
            pagerElapssed();
        }, 3000);

    }

    /* Closes the pager */
    function pagerElapssed(){
        pagerElement.style.display = "none";
        beepAudio.pause();
        beepAudio.load();
        // grabAudio.pause();
        // grabAudio.load();

        saveContactElement.style.display = "none";
        reminderElement.style.display = "none";
        currentInteraction = null;

        if(t !== null) clearTimeout(t);        
        
        fetch(`https://${resourceName}/dismissPager`, {
            method: 'POST'
        });
    }

    /* */
    function pagerShowMessage(text, showReminder) {
        pagerShowMessageSimple(text)
        currentInteraction = null;
        if (showReminder) {
            reminderElement.style.display = "block";
            reminderElement.innerHTML = saveMessage;
            currentInteraction = 'save';
        }
        else {
            reminderElement.style.display = "none";
        }
    }

    function pagerShowContact(text, showReminder) {
        pagerShowMessageSimple(text);
        currentInteraction = null;
        if (showReminder) {
            reminderElement.style.display = "block";
            reminderElement.innerHTML = deleteMessage;
            currentInteraction = 'delete';
        }
        else {
            reminderElement.style.display = "none";
        }
    }

    /* Buttons functions js->lua communication */
    document.getElementById("button-close").onclick = function(){
        pagerElapssed()
    }
    document.getElementById("button-interact").onclick = function(){
        let value = null;
        let sendPost = true;
        if (reminderElement.style.display == "block") {
            if (currentInteraction == "save") {
                if (saveContactElement.style.display == "none") {
                    saveContactElement.style.display = "block";
                    sendPost = false;
                }
                else {
                    value = saveContactElement.value;
                    saveContactElement.style.display = "none";
                }
            }
        }
        else {
            sendPost = false;
        }
        if (sendPost) {
            fetch(`https://${resourceName}/interactWithContact`, {
                method: 'POST',
                body: JSON.stringify({
                    interaction: currentInteraction,
                    value: value
                })
            })
            reminderElement.style.display = "none";
            reminderElement.innerHTML = "";
            saveContactElement.value = "";
        }
    }
    document.getElementById("button-up").onclick = function(){
        fetch(`https://${resourceName}/showMessageUp`, {
            method: 'POST',
        });
    }
    document.getElementById("button-left").onclick = function(){
        fetch(`https://${resourceName}/showContactLeft`, {
            method: 'POST',
        });
    }
    document.getElementById("button-right").onclick = function(){
        fetch(`https://${resourceName}/showContactRight`, {
            method: 'POST',
        });
    }
    document.getElementById("button-down").onclick = function(){
        fetch(`https://${resourceName}/showMessageDown`, {
            method: 'POST',
        });
    }
});