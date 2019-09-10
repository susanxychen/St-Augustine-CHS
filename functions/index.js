const https = require('follow-redirects').http;
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const FeildValue = require('firebase-admin').firestore.FieldValue;
// const nodemailer = require('nodemailer');
// const cors = require('cors')();

// var serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({ 
    credential: admin.credential.applicationDefault()
});

const {Storage} = require('@google-cloud/storage');
const storage = new Storage();

const settings = {timestampsInSnapshots: true};
admin.firestore().settings(settings);

// const validateFirebaseIdToken = (req, res, next) => {
//     cors(req, res, () => {
//       const idToken = String(req.headers.authorization).split('Bearer ')[1];
//       admin.auth().verifyIdToken(idToken).then(decodedIdToken => {
//         console.log('ID Token correctly decoded', decodedIdToken);
//         req.user = decodedIdToken;
//         next();
//         return '';
//       }).catch(error => {
//         console.error('Error while verifying Firebase ID token:', error);
//         res.status(403).send('Unauthorized');
//       });
//     });
// };
  

// exports.testauth = functions.https.onRequest((req, res) => {
//     validateFirebaseIdToken(req, res, () => {
//         //now you know they're authorized and `req.user` has info about them
//         res.send('auth passed');
//     });
// });

exports.sendEmailToAdmins = functions.https.onCall((data, response) => {
    const adminIDArr = data.adminIDArr;
    const userEmail = data.userEmail;
    const clubName = data.clubName;

    //Convert ids to emails
    for (let i = 0; i < adminIDArr.length; i++){
        admin.firestore().doc('users/' + adminIDArr[i] + '/info/vital').get()
        // eslint-disable-next-line no-loop-func
        .then(doc => {
            if (!doc.exists) {
                console.log('No such document!');
                return 'Error';
            } else {
                let theAdminEmail = '';
                theAdminEmail = doc.data().email;
                console.log(theAdminEmail);

                let theAdminToken = '';
                theAdminToken = doc.data().msgToken;

                var message = {
                    token: theAdminToken,
                    notification: {
                        title: clubName + ' Join Request',
                        body: userEmail + ' would like to join ' + clubName,
                    },
                    android: {
                        notification: {
                            color: '#d8af1c',
                        },
                    },
                    apns: {
                        payload: {
                        aps: {
                            "content-available": 1,
                        },
                        },
                    }
                };

                // eslint-disable-next-line promise/no-nesting
                admin.messaging().send(message)
                .then((response2) => {
                    console.log('Successfully sent message:', response2);
                    return 'sucess';
                })
                .catch((error) => {
                    console.log('Error sending message:', error);
                    return 'error';
                });

                // var transporter = nodemailer.createTransport({
                //     service: 'gmail',
                //     auth: {
                //         user: 'sachsappteam@gmail.com',
                //         pass: 'takecompsciyoun00bs'
                //     }
                // });
                
                // var mailOptions = {
                //     from: '"St. Augustine App" <sachsappteam@gmail.com>',
                //     to: theAdminEmail,
                //     subject: clubName + ' Join Request',
                //     text: userEmail + ' would like to join ' + clubName
                // };
                    
                // transporter.sendMail(mailOptions, (error, info) =>{
                //     if (error) {
                //         console.log(error);
                //     } else {
                //         console.log('Email sent: ' + info.response);
                //     }
                // });
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
    //validateFirebaseIdToken(request, response, () => {
        var songsRef = admin.firestore().collection('songs');
        var allSongs = songsRef.get()
        .then(snapshot => {
            var votes = []
            var ids = []
            var dates = []
            snapshot.forEach(doc => {
                // console.log(doc.id, ' => ', doc.data())
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
    //});
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
                console.log('Day:' + dayNum);
                response.send(dayNum);
                return snapshot.ref.set({
                    dayNumber: dayNum,
                    snowDay: false
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
    var message = {
        topic: clubID,
        notification: {
            title: '(' + clubName +') '+ title,
            body: body,
        },

        //android not really needed
        android: {
            notification: {
                color: '#d8af1c',
            },
        },

        //apple
        apns: {
            payload: {
            aps: {
                "content-available": 1,
            },
            },
        }
    };

    // Send a message to devices subscribed to the provided topic.
    admin.messaging().send(message)
    .then((response2) => {
        // See the MessagingTopicResponse reference documentation for the
        // contents of response.
        console.log('Successfully sent message:', response2);
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

exports.checkSnowDay = functions.https.onRequest((request, response) => {
    https.get({
        host: 'net.schoolbuscity.com',
    }, (resp) => {
    let data = '';
    
    // A chunk of data has been recieved.
    resp.on('data', (chunk) => {
        data += chunk;
    });
    
    // The whole response has been received
    resp.on('end', () => {
        data = data.replace('&nbsp;','');
        data = data.toLowerCase();

        admin.firestore().doc('info/dayNumber').get()
            .then(snapshot => {
                var isSnowDay = snapshot.data().snowDay
                if (!isSnowDay) {
                    console.log('not a snow day yet');
                    if (data.includes("all school buses, vans and taxis") && data.includes("are cancelled for today")) {
                        console.log('snow day');
            
                        var payload = {
                        notification: {
                            title: 'Buses are cancelled today',
                            body: 'School bus city states: All school buses, vans and taxis servicing the YORK CATHOLIC and YORK REGION DISTRICT SCHOOL BOARD are cancelled for today'
                        }
                        };
                        
                        // Send a message to devices subscribed to the provided topic.
                        // eslint-disable-next-line promise/no-nesting
                        admin.messaging().sendToTopic('alerts', payload)
                        .then((response2) => {
                            // See the MessagingTopicResponse reference documentation for the
                            // contents of response.
                            console.log('Successfully sent message:', response2);
                            response.send('snow day');
                            return 'snow day';
                        })
                        .catch((error) => {
                            console.log('Error sending message:', error);
                            response.send(error);
                            return 'error sending';
                        });
            
                        // eslint-disable-next-line promise/no-nesting
                        admin.firestore().doc('info/dayNumber').get()
                        .then(snapshot => {
                            if (snapshot.exists) {
                                return snapshot.ref.set({
                                    snowDay: true
                                }, {merge: true});
                            } else {
                                console.log('no log snow day')
                                throw new Error('no write snow day')
                            }
                        })
                        .catch(error => {
                            //handle the error
                            console.log(error);
                            //response.status(error.status >= 100 && error.status < 600 ? error.code : 500).send("Error accessing firestore: " + error.message);
                        });
            
                        return 'done';
                    } else {
                        console.log('not snow day');
                        // eslint-disable-next-line promise/no-nesting
                        admin.firestore().doc('info/dayNumber').get()
                        .then(snapshot => {
                            response.send('not a snow day')
                            if (snapshot.exists) {
                                return snapshot.ref.set({
                                    snowDay: false
                                }, {merge: true});
                            } else {
                                console.log('no write snow day')
                                throw new Error('no write snow day')
                            }
                        })
                        .catch(error => {
                            //handle the error
                            console.log(error);
                            response.status(error.status >= 100 && error.status < 600 ? error.code : 500).send("Error accessing firestore: " + error.message);
                        });
                    }
                } else {
                    console.log('first check');
                    response.send('checked and already good');
                }
                return 'done';
            })
            .catch(error => {
                //handle the error
                console.log(error);
                response.status(error.status >= 100 && error.status < 600 ? error.code : 500).send("Error accessing firestore: " + error.message);
            });
        return 'none';
    });
    }).on("error", (err) => {
        response.send("Error checking snow day: " + err.message);
        console.log("Error: " + err.message);
        return err;
    });
});

exports.sendToUser = functions.https.onCall((data, response) => {
    const token = data.token;
    const title = data.title;
    const body = data.body;

    // See the "Defining the message payload" section below for details
    var message = {
        token: token,
        notification: {
            title: title,
            body: body,
        },
        //android not really needed
        android: {
            notification: {
                color: '#d8af1c',
            },
        },
        //apple
        apns: {
            payload: {
            aps: {
                "content-available": 1,
            },
            },
        }
    };

    admin.messaging().send(message)
    .then((response2) => {
        console.log('Successfully sent message:', response2);
        return 'sucess';
    })
    .catch((error) => {
        console.log('Error sending message:', error);
        return 'error';
    });
});

//https://firebase.google.com/docs/cloud-messaging/admin/send-messages#before_you_begin
exports.testTopic = functions.https.onRequest((request, response) => {
    var message = {
        topic: 'alerts',
        notification: {
            title: 'customizing notification payloads',
            body: 'apns and android',
        },
        android: {
            notification: {
                color: '#d8af1c',
            },
        },
        apns: {
            payload: {
            aps: {
                "content-available": 1,
            },
            },
        }
    };
    admin.messaging().send(message)
    .then((response2) => {
        response.send('nice');
        console.log('Successfully sent message:', response2);
        return 'sucess';
    })
    .catch((error) => {
        response.send(error);
        console.log('Error sending message:', error);
        return 'error';
    });
});

exports.deleteSeniors = functions.https.onRequest((req, res) => {

    let user_ref = admin.firestore().collection('users');

    let all_user = user_ref.get()
    .then(snapshot => {

        const senior_ids = [];

        snapshot.forEach(doc => {

            // console.log(doc.id + '=>' + doc.data());
            const usr_data = doc.data();
            
            let usr_email = usr_data.email;

            console.log(usr_email);
            try {
                if(usr_email.includes("19")){
                    senior_ids.push(doc.id);
                }
            } catch (err) {
                console.log(usr_email);
            }

        });

        for(let i = 0; i < senior_ids.length; i++){
            admin.firestore().collection('users').doc(senior_ids[i]).collection('info').doc('vital').delete();
            admin.firestore().collection('users').doc(senior_ids[i]).delete(); 
        }


        res.send(senior_ids);
        return senior_ids;
    })
    .catch( (error) => {
        


    })
    .catch((error) => {
        res.send('Error deleting users' + error);
        return 'error';
    })


});

exports.deleteClubs = functions.https.onRequest( (req, res) => {

    //Get the clubs collection
    let clubs_ref = admin.firestore().collection('clubs');

    let all_clubs = clubs_ref.get()

    .then( snapshot => {

        // const clubs_list = [];

        snapshot.forEach(doc => {
            
            // clubs_list.push_back(doc.id);
            if(doc.id !== '3rk2QdNU21cZ0bEpQJK7')
                admin.firestore().collection('clubs').doc(doc.id).delete();
            // console.log(doc);

        });


        // for(let i = 0; i < clubs_list.length; i++) {

        //     admin.firestore().collection('ClubsTest').doc(clubs_list[i]).delete();

        // }

       res.send('Success');
       return 1; 
    }) .catch(err => {

        res.send(err);
        return err;

    });
});

exports.resetTimeTables = functions.https.onRequest( (req, res) => {

    let users_ref = admin.firestore().collection('users')

    let get_users = users_ref.get()

    .then( snapshot => {

        snapshot.forEach( doc => {

            const usr_data = doc.data();
            const spare_arr = ["SPARE", "SPARE", "SPARE", "SPARE", "SPARE", "SPARE", "SPARE", "SPARE"];

            let update_usr = admin.firestore().collection('users').doc(doc.id).update( {
               "classes" : ["SPARE","SPARE","SPARE","SPARE","SPARE","SPARE","SPARE","SPARE"] 
            });


        });

        res.send("Success");
        return 1;
    }) .catch(err => {

        res.send(err);
        return err;
    });

})

exports.fixJohnsMistake = functions.https.onRequest((req, res) => {

    const usr_ref = admin.firestore().collection('users');

    let all_users = usr_ref.get()

    .then( snapshot => {

        snapshot.forEach( doc => {

            let delete_stuff = admin.firestore().collection('users').doc(doc.id).update( {

                "courses" : FeildValue.delete() 

            })

        })

        res.send("Fixed your mistake")
        return "Success";
    }) .catch(err => {

        console.log(err);
        res.send(err);

    });

})

exports.removeClubsFromUsers = functions.https.onRequest((req, res) => {

    let user_ref = admin.firestore().collection('users');

    let get_users = user_ref.get()

    .then(snapshot => {

        snapshot.forEach(doc => {
            let usr_data = doc.data();

            for(let i = 0; i < usr_data.clubs.length; i++){
                console.log(doc.id);
                admin.firestore().collection('users').doc(doc.id).update({
                    "clubs" : FeildValue.arrayRemove(usr_data.clubs[i])
                    // "clubs" : []
                });
            }
            
            // admin.firestore().collection('usersTEST2').doc(doc.id)
        });

        res.send("Clubs deleted from users");
        return "Success";
    }).catch((err) => {
        console.log(err);
        res.send(err);
        return err;

    })



})