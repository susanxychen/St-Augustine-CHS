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

//const passField = document.getElementById("passField");
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

var cafItems = document.getElementById("cafItems");
var cafItemsRegular = document.getElementById("cafItemsRegular");

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
    var email = document.getElementById("emailField").value;
    const password = passField.value;
    
    if(email.length > 0 && password.length > 0){
        if(!email.indexOf('@') > -1){
           email += "@stachs.com";
        }
        
        firebase.auth().signInWithEmailAndPassword(email, password)
            .then(function(){
                //LOGIN SUCCESSFUL, SHOW CAF MENU AND HIDE LOG IN
                const loginDiv = document.getElementById("loginDiv");
                loginDiv.style.display = 'none';
                const cafMenuDiv = document.getElementById("cafMenuDiv");
                cafMenuDiv.style.display = '';
            
                fetchCafMenu();
            }).catch(function(error){
                alert(error.message);
            });
    }else{
        alert("Enter an email and password!");
    }
}

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