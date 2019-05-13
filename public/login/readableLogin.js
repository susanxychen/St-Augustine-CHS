var config = {
    apiKey: "AIzaSyBllofITGBhdkIlSIspxhOHDXhCOomoKeE",
    authDomain: "staugustinechsapp.firebaseapp.com",
    databaseURL: "https://staugustinechsapp.firebaseio.com",
    projectId: "staugustinechsapp",
    storageBucket: "staugustinechsapp.appspot.com",
    messagingSenderId: "448336593725"
};
firebase.initializeApp(config);

var firestore = firebase.firestore();

var functions = firebase.functions();

var send = functions.httpsCallable('sendToTopic');

const emailField = document.getElementById("emailField");
emailField.addEventListener("keypress", function(event){
    if(event.keyCode === 13){
        attemptLogin();
    } 
});

const passField = document.getElementById("passField");
passField.addEventListener("keypress", function(event){
    if(event.keyCode === 13){
        attemptLogin();
    } 
});

const loginBtn = document.getElementById("loginBtn");
loginBtn.addEventListener("click", attemptLogin);

const updateBtn = document.getElementById("cafUpdateBtn");
updateBtn.addEventListener("click", updateMenus);

const cafMenuRef = firestore.collection("info").doc("cafMenu");
const cafMenuRegularRef = firestore.collection("info").doc("cafMenuRegular");

const og = document.getElementById("cafItem");
const ogRegular = document.getElementById("cafItemRegular");

let cafItems = document.getElementById("cafItems");
let cafItemsRegular = document.getElementById("cafItemsRegular");

const messageSendBtn = document.getElementById("sendMessageBtn");
messageSendBtn.addEventListener("click", sendMessage);

let message = document.getElementById("tucciMessage");



const addCafItem = document.getElementById("addCafItem");
addCafItem.addEventListener("click", function(){
    var clone = og.cloneNode(true);
    clone.id = "cafItem" + cafItems.children.length;
    clone.children[0].children[2].addEventListener("click", function(){
                cafItems.removeChild(this.parentNode.parentNode);
            });
    cafItems.appendChild(clone);
});

const addCafItemRegular = document.getElementById("addCafItemRegular");
addCafItemRegular.addEventListener("click", function(){
    var clone = ogRegular.cloneNode(true);
    clone.id = "cafItemRegular" + cafItems.children.length;
    clone.children[0].children[2].addEventListener("click", function(){
                cafItemsRegular.removeChild(this.parentNode.parentNode);
            });
    cafItemsRegular.appendChild(clone);
});

function attemptLogin() {
    //GET USERNAME AND PASSWORD IN TEXT FIELD
    var email = emailField.value;
    const password = passField.value;
    
    if(email.length > 0 && password.length > 0){
        if(email.indexOf('@') == -1){
           email += "@stachs.com";
        }
        
        firebase.auth().signInWithEmailAndPassword(email, password)
            .then(() => {
                //If the login is Mr. Tucci
                if(email == 'testtest123@wow.com' || email == 'administration@stachs.com'){
                    // console.log('This is inside the test')
                    //Successful Login. Shows Message Menu and Hide Log In
                    const loginDiv = document.getElementById('loginDiv');
                    loginDiv.style.display = 'none';
                    const tucciLogin = document.getElementById('tucciLogin');
                    tucciLogin.style.display = '';

                } else {  
                    // console.log(email);
                    // console.log(typeof email);
                    
                    //LOGIN SUCCESSFUL, SHOW CAF MENU AND HIDE LOG IN
                    const loginDiv = document.getElementById("loginDiv");
                    loginDiv.style.display = 'none';
                    const cafMenuDiv = document.getElementById("cafMenuDiv");
                    cafMenuDiv.style.display = '';
                
                    fetchCafMenu();
                
                }
            }).catch(function(error){
                alert('Invalid email or password');
            });
    }else{
        alert('Invalid email or password');
    }
}
//For the caf menu
function fetchCafMenu() {
    cafMenuRef.get().then(function(doc){
        const data = doc.data();
        var count = 0;
        for(const key in data){
            var clone = og.cloneNode(true);
            clone.id = "cafItem" + count;
            
            const form = clone.children[0];
            form.children[0].value = key;
            form.children[1].value = data[key];
            form.children[2].addEventListener("click", function(){
                cafItems.removeChild(this.parentNode.parentNode);
            });
            
            cafItems.appendChild(clone);
        }
        cafItems.removeChild(og);
    });
    
    cafMenuRegularRef.get().then(function(doc){
        const data = doc.data();
        var count = 0;
        for(const key in data){
            var clone = ogRegular.cloneNode(true);
            clone.id = "cafItemRegular" + count;
            
            const form = clone.children[0];
            form.children[0].value = key;
            form.children[1].value = data[key];
            form.children[2].addEventListener("click", function(){
                cafItemsRegular.removeChild(this.parentNode.parentNode);
            });
            
            cafItemsRegular.appendChild(clone);
        }
        cafItemsRegular.removeChild(ogRegular);
    });
}

function updateMenus(){
    var items = {};
    for(var i = 0; i < cafItems.children.length; i++){
        const form = cafItems.children[i].children[0];
        const key = form.children[0].value;
        const value = form.children[1].value;
        if(key.length > 0 && value.length > 0){
            items[key + ""] = parseFloat(value);
        }
    }
    
    cafMenuRef.set(items).then(function(){
        var items2 = {};
        for(var a = 0; a < cafItemsRegular.children.length; a++){
            const form2 = cafItemsRegular.children[a].children[0];
            const key2 = form2.children[0].value;
            const value2 = form2.children[1].value;
            if(key2.length > 0 && value2.length > 0){
                items2[key2 + ""] = parseFloat(value2);
            }
        }
        
        cafMenuRegularRef.set(items2).then(function(){
            alert("Successfully updated caf menu!");
        }).catch(function(error){
            alert(error.message);
        });
    }).catch(function(error){
        alert(error.message);
    });
}
//For the tucci message

function sendMessage() {

    //First make sure that the message is not empty
    //!NOTE: There is currently a bug that causes messages to be sent twice.
    if(message.value === ""){
        alert("You cannot submit an empty message");
        return false;
    } else {
        // alert("Message Sent");
        send(
            {
                "clubID": 'alert', 
                "title": 'IMPORTANT MESSAGE', 
                "body": message.value,
                "clubName": "Administration"
            }
        )
        .then(() => {
            //...
        })

        .catch(err => {
            //Will alert the user that a message could not be sent throught the db
            alert("Could not send message");
            
        });
        return true;
    }
    
}