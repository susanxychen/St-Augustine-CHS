const https = require('follow-redirects').http;
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
var serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({ 
    credential: admin.credential.applicationDefault()
});

const {Storage} = require('@google-cloud/storage');
const storage = new Storage();

const settings = {timestampsInSnapshots: true};
admin.firestore().settings(settings);

// const gmailEmail = functions.config().gmail.email;
// const gmailPassword = functions.config().gmail.password;
// const mailTransport = nodemailer.createTransport({
//   service: 'gmail',
//   auth: {
//     user: gmailEmail,
//     pass: gmailPassword,
//   },
// });

exports.sendEmailToAdmins = functions.https.onCall((data, context) => {
    const adminIDArr = data.adminIDArr;
    const userEmail = data.userEmail;
    const clubName = data.clubName;
    const adminEmails = []

    //Convert ids to emails
    for (let i = 0; i < adminIDArr.length; i++){
        admin.firestore().doc('users/' + adminIDArr[i]).get()
        // eslint-disable-next-line no-loop-func
        .then(doc => {
            if (!doc.exists) {
                console.log('No such document!');
                return 'Error';
            } else {
                let theAdminEmail = '';
                theAdminEmail = doc.data().email;
                console.log(theAdminEmail);
                var transporter = nodemailer.createTransport({
                    service: 'gmail',
                    auth: {
                        user: 'sachsappteam@gmail.com',
                        pass: 'takecompsciyoun00bs'
                    }
                });
                    
                var mailOptions = {
                    from: '"St. Augustine App" <sachsappteam@gmail.com>',
                    to: theAdminEmail,
                    subject: clubName + ' Join Request',
                    text: userEmail + ' would like to join ' + clubName
                };
                    
                transporter.sendMail(mailOptions, (error, info) =>{
                    if (error) {
                        console.log(error);
                        response.send('Error!')
                    } else {
                        console.log('Email sent: ' + info.response);
                        response.send('Success!');
                    }
                });
                return theAdminEmail;
            }
        })
        // eslint-disable-next-line no-loop-func
        .catch(err => {
            console.log('Error getting document', err);
        });
    }
});

exports.deleteTopSongs = functions.https.onRequest((request, response) => {
    var songsRef = admin.firestore().collection('songs');
    var allSongs = songsRef.get()
    .then(snapshot => {
        var votes = []
        var ids = []
        var dates = []
        snapshot.forEach(doc => {
            console.log(doc.id, ' => ', doc.data())
            const songData = doc.data();
            let upvotes = songData.upvotes;
            if(!upvotes){
                upvotes = 0;
            }
            votes.push(upvotes);
            ids.push(doc.id);

            let timestamp = songData.date;
            const date = timestamp.toDate();
            dates.push(date);
        });

        if (ids.length >= 3) {
            var max = [0,0,0];
            var maxIDs = ['error','error','error'];

            //Loop through the max array
            for (let j = 0; j < max.length; j++){
                //Go through all the songs
                for (let i = 0; i < votes.length; i++){
                    //Get new max check if we already did that max
                    if (max[j] <= votes[i] && !maxIDs.includes(ids[i])) {
                        max[j] = votes[i];
                        maxIDs[j] = ids[i];
                    }
                }
            }

            //Delete the top songs
            for (let i = 0; i < maxIDs.length; i++){
                admin.firestore().collection('songs').doc(maxIDs[i]).delete();
            }

            //Delete songs older than 2 days
            var daysAgo = new Date().getTime() - (2*24*60*60*1000)
            var oldSongIds = []

            for (let i = 0; i < ids.length; i++){
                if (dates[i] < daysAgo /*&& votes[i] < 100*/){
                    oldSongIds.push(ids[i]);
                }
            }

            //Delete the old songs
            for (let i = 0; i < oldSongIds.length; i++){
                admin.firestore().collection('songs').doc(oldSongIds[i]).delete();
            }

            response.send(oldSongIds + ' ' + maxIDs);
            return oldSongIds;
        } else if (ids.length > 0) {
            //Just delete everything
            for (let i = 0; i < ids.length; i++){
                admin.firestore().collection('songs').doc(ids[i]).delete();
            }
            response.send('deleted last songs');
            return 'deleted last songs';
        } else {
            response.send('no songs at all');
            return 'no songs at all';
        }
    })
    .catch(error => {
        console.log(error);
        response.status(500).send(error);
    })
});

exports.deleteOldAnnouncements = functions.https.onRequest((request, response) => {
    var anncRef = admin.firestore().collection('announcements');
    anncRef.get()
    .then(snapshot => {
        var ids = []
        var imgs = []
        var dates = []
        snapshot.forEach(doc => {
            //console.log(doc.id, ' => ', doc.data())
            const anncData = doc.data();
            ids.push(doc.id);

            let imgID = anncData.img;
            if(!imgID){
                imgID = "";
            }
            imgs.push(imgID);

            let timestamp = anncData.date;
            const date = timestamp.toDate();
            dates.push(date);
        });

        //Delete announcements older than 30 days
        var daysAgo = new Date().getTime() - (30*24*60*60*1000)
        var oldAnncIds = []
        var oldImgIds = []

        for (let i = 0; i < ids.length; i++){
            if (dates[i] < daysAgo){
                oldAnncIds.push(ids[i]);
                oldImgIds.push(imgs[i]);
            }
        }

        console.log('annc ' + oldAnncIds + ' imgs ' + oldImgIds);

        //Delete the old announcements
        for (let i = 0; i < oldAnncIds.length; i++){
            admin.firestore().collection('announcements').doc(oldAnncIds[i]).delete();
        }

        // Creates a client
        for (let i = 0; i < oldImgIds.length; i++){
            if (oldImgIds[i] !== "") {
                console.log('delete ' + oldImgIds[i]);
                //const bucket = storage.bucket('staugustinechsapp.appspot.com/announcements');
                //bucket.file(oldImgIds[i]).delete()
                const myBucket = storage.bucket('staugustinechsapp.appspot.com');
                myBucket.file('announcements/' + oldImgIds[i]).delete()
                //storage.bucket('staugustinechsapp.appspot.com/announcements').file(oldImgIds[i]).delete();
                //admin.storage().bucket('staugustinechsapp.appspot.com/announcements').file(oldImgIds[i]).delete();
            }
        }

        response.send(oldAnncIds + ' img: ' + oldImgIds);
        return oldAnncIds;
    })
    .catch(error => {
        console.log(error);
        response.status(500).send(error);
    })
});

exports.getDayNumber = functions.https.onRequest((request, response) => {
    https.get({
        host: 'staugustinechs.netfirms.com',
        path: '/stadayonetwo',
    }, (resp) => {
    let data = '';

    // A chunk of data has been recieved.
    resp.on('data', (chunk) => {
        data += chunk;
    });

    // The whole response has been received
    resp.on('end', () => {
        //console.log(data);
        var index = data.lastIndexOf("Day ");
        var dayNum = data.substring(index+4, index + 5);
        //var dayNumAsInt = parseInt(dayNum, 10);

        admin.firestore().doc('info/dayNumber').get()
        .then(snapshot => {
            if (snapshot.exists) {
                console.log('Do i even get in here ' + dayNum);
                response.send(dayNum);
                return snapshot.ref.set({
                    dayNumber: dayNum
                }, {merge: true});
            } else {
                console.log('no day number')
                response.send('no day number')
                throw new Error('no day number')
            }
        })
        .catch(error => {
            //handle the error
            console.log(error);
            response.status(error.status >= 100 && error.status < 600 ? error.code : 500).send("Error accessing firestore: " + error.message);
        });
    });
    }).on("error", (err) => {
        response.send("Error getting day number " + err.message);
        console.log("Error: " + err.message);
    });
});

exports.sendToTopic = functions.https.onCall((data, response) => {
    const body = data.body;
    const title = data.title;
    const clubID = data.clubID;
    const clubName = data.clubName;

    console.log(clubID);

    // See the "Defining the message payload" section below for details
    var payload = {
    notification: {
        title: '(' + clubName + ')' + title,
        body: body
    }
    };

    // Send a message to devices subscribed to the provided topic.
    admin.messaging().sendToTopic(clubID, payload)
    .then((response) => {
        // See the MessagingTopicResponse reference documentation for the
        // contents of response.
        console.log('Successfully sent message:', response);
        return 'sucess';
    })
    .catch((error) => {
        console.log('Error sending message:', error);
        return 'error';
    });
});

exports.manageSubscriptions = functions.https.onCall((data, context) => {
    const registrationTokens = data.registrationTokens;
    const isSubscribing = data.isSubscribing;
    const clubID = data.clubID;
    
    if (isSubscribing) {
        // Subscribe the devices corresponding to the registration tokens from
        // the topic.
        admin.messaging().subscribeToTopic(registrationTokens, clubID)
        .then((response)=>  {
            // See the MessagingTopicManagementResponse reference documentation
            // for the contents of response.
            console.log('Successfully subscribed to topic:', response);
            return 'success';
        })
        .catch((error) => {
            console.log('Error subscribing from topic:', error);
            return error;
        });
    } else {
        // Unsubscribe the devices corresponding to the registration tokens from
        // the topic.
        admin.messaging().unsubscribeFromTopic(registrationTokens, clubID)
        .then((response)=>  {
            // See the MessagingTopicManagementResponse reference documentation
            // for the contents of response.
            console.log('Successfully unsubscribed from topic:', response);
            return 'success';
        })
        .catch((error) => {
            console.log('Error unsubscribing from topic:', error);
            return error;
        });
    }
});

// //The Edit Votes Function
// exports.changeVote = functions.https.onCall((data, context) => {
//     const id = data.id;
//     const uservote = data.uservote;
//     //console.log('Id: ' + id + ' Vote: ' + uservote);

//     admin.firestore().doc('songs/' + id).get()
//     .then(snapshot => {
//         if (snapshot.exists) {
//             const songData = snapshot.data();
            
//             //Attempt to update the database
//             let votes = songData.upvotes;
//             if (!votes) {
//                 votes = 0;
//             }
            
//             //Prevent vote from going below 0
//             if (votes === 0 && uservote < 0){
//                 return snapshot.ref.set({
//                     upvotes: 0
//                 }, {merge: true});
//             }

//             return snapshot.ref.set({
//                 upvotes: votes + uservote
//             }, {merge: true});
            
//         } else {
//             console.log('id doesnt exist')
//             response.send('Song Doesnt exist')
//             throw new Error('Song doesn\'t Exist')
//         }
//     })
//     .catch(error => {
//         //handle the error
//         console.log(error);
//         response.status(500).send(error);
//     });
// });