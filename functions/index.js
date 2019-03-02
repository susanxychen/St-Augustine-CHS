const https = require('follow-redirects').http;
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp({ 
    credential: admin.credential.applicationDefault()
});

const {Storage} = require('@google-cloud/storage');
const storage = new Storage();

const settings = {timestampsInSnapshots: true};
admin.firestore().settings(settings);

const {google} = require('googleapis')
const rp = require('request-promise')

exports.backupFirestore = functions.https.onRequest((data, response) => {
    const projectId = 'staugustinechsapp'
    const getAccessToken = new Promise((resolve, reject) => {
      const scopes = ['https://www.googleapis.com/auth/datastore', 'https://www.googleapis.com/auth/cloud-platform']
      const key = require(`./${projectId}.json`)
      const jwtClient = new google.auth.JWT(
        key.client_email,
        undefined,
        key.private_key,
        scopes,
        undefined
      )
      const authorization = new Promise((resolve, reject) => {
        return jwtClient.authorize().then((value) => {
          return resolve(value)
        })
      })
      return authorization.then((value) => {
        return resolve(value.access_token)
      })
    })
    return getAccessToken.then((accessToken) => {
      const url = `https://firestore.googleapis.com/v1beta1/projects/${projectId}/databases/(default):exportDocuments`
      response.send('backed');
      return rp.post(url, {
        headers: {
          Authorization: `Bearer ${accessToken}`
        },
        json: true,
        body: {
          outputUriPrefix: `gs://sta-firestore-backups`
        }
      })
    })
  })

exports.sendEmailToAdmins = functions.https.onCall((data, response) => {
    const adminIDArr = data.adminIDArr;
    const userEmail = data.userEmail;
    const clubName = data.clubName;

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
    admin.firestore().doc('info/dayNumber').get()
    .then(snapshot => {
        var isSnowDay = snapshot.data().snowDay
        if (!isSnowDay) {
            var theCollection = 'songs'
            var songsRef = admin.firestore().collection(theCollection);
            // eslint-disable-next-line promise/no-nesting
            var allSongs = songsRef.get()
            .then(snapshot => {
                var votes = []
                var ids = []
                var dates = []
                snapshot.forEach(doc => {
                    const songData = doc.data();
                    let upvotes = songData.upvotes;
                    if(!upvotes){
                        upvotes = 0;
                    }
                    votes.push(upvotes);
                    ids.push(doc.id);

                    let timestamp = songData.date;
                    const date = new Date(timestamp);
                    dates.push(date);
                });

                //Check if there are songs at all
                if (ids.length >= 1) {
                    var max = 0;
                    var maxID = '';

                    //Go through all the songs
                    for (let i = 0; i < votes.length; i++){
                        //Get new max check if we already did that max
                        if (max <= votes[i]) {
                            max = votes[i];
                            maxID = ids[i];
                        }
                    }

                    //Delete the top song
                    admin.firestore().collection(theCollection).doc(maxID).delete();

                    //Delete songs older than 2 days
                    var daysAgo = new Date().getTime() - (2*24*60*60*1000)
                    var oldSongIds = []

                    for (let i = 0; i < ids.length; i++){
                        if (dates[i] < daysAgo){
                            oldSongIds.push(ids[i]);
                        }
                    }

                    //Delete the old songs
                    for (let i = 0; i < oldSongIds.length; i++){
                        admin.firestore().collection(theCollection).doc(oldSongIds[i]).delete();
                    }

                    response.send(oldSongIds + ' ' + maxID);
                    return oldSongIds;
                } else {
                    response.send('no songs at all');
                    return 'no songs at all';
                }
            })
            .catch(error => {
                console.log(error);
                response.status(500).send(error);
            })
        } else {
            response.send('its a snow day. dont delete songs')
        }
        return 'done';
    })
    .catch(error => {
        //handle the error
        console.log(error);
        response.status(error.status >= 100 && error.status < 600 ? error.code : 500).send("Error accessing firestore: " + error.message);
    });
});

exports.changeAllSongDatesWeekend = functions.https.onRequest((request, response) => {
    var songsRef = admin.firestore().collection('songs');
    songsRef.get()
    .then(snapshot => {
        snapshot.forEach(doc => {
            const id = doc.id
            admin.firestore().collection('songs').doc(id).update({date: Date()});
        });
        response.send('changed dates');
        return 'changed dates';
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
                console.log('Day:' + dayNum);
                response.send(dayNum);
                return snapshot.ref.set({
                    dayNumber: dayNum,
                    snowDay: false,
                    haveFun: false
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

exports.sendToTopicHTTP = functions.https.onRequest((data, response) => {
    const body = data.body;
    const department = data.department;
    const topic = data.topic;

    if (!topic) {
        console.log('No Topic');
    } else {
        console.log(topic)
    }

    if (!department) {
        console.log('No department');
    } else {
        console.log(department)
    }

    if (!body) {
        console.log('No body');
    } else {
        console.log(body)
    }

    // See the "Defining the message payload" section below for details
    var message = {
        topic: topic,
        notification: {
            title: 'New Announcement from ' + department,
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

exports.createUserDocs = functions.https.onRequest((req, response) => {
    // setTimeout(() => {
    var theColleciton = 'users'
    admin.firestore().collection(theColleciton).get()
    .then(snapshot => {
        snapshot.forEach(doc => {
            const uData = doc.data();
            let id = doc.id;

            let msg = uData.msgToken;
            if(!msg){
                msg = 'error'
            }

            let data = {
                email: uData.email,
                profilePic: uData.profilePic,
                name: uData.name,
                msgToken: msg
            };

            // eslint-disable-next-line promise/no-nesting
            admin.firestore().collection(theColleciton).doc(id).collection('info').doc('vital').create(data).catch(error => {
                //lmao
            })
        });
        return 'nice'
    })
    .catch(error => {
        console.log(error);
        response.status(500).send(error);
    })
    // }, 360000); // 6 minute delay

    // var uref = admin.firestore().collection('users').get()
    // var getData = uref.then(snapshot => {
    //     let ids = []
    //     let datas = []
        
    //     snapshot.forEach(doc => {
    //         const uData = doc.data();

    //         let id = doc.id;

    //         ids.push(id);

    //         let msg = uData.msgToken;
    //         if(!msg){
    //             msg = 'error'
    //         }

    //         let data = {
    //             email: uData.email,
    //             profilePic: uData.profilePic,
    //             name: uData.name,
    //             msgToken: msg
    //         };

    //         datas.push(data);
    //     });
    //     return [ids, datas]
    // })
    // .catch(error => {
    //     console.log(error);
    //     response.status(500).send(error);
    // })

    // var setData = getData.then(input => {
    //     let ids = input[0]
    //     let datas = input[1]

    //     for (j = 0; j < ids.length; j++) {
    //         admin.firestore().collection('users').doc(ids[j]).collection('info').doc('vital').set(datas[j]);
    //     }

    //     return 'nice'
    // })
    // .catch(error => {
    //     console.log(error);
    //     response.status(500).send(error);
    // })
    
    // return Promise.all([getData, setData]).then(result => {
    //     response.send(result);
    //     return result;
    // });
});

exports.createFakeUsers = functions.https.onRequest((req, response) => {
    for (let i = 0; i < 850; i++){
        let data = {
            points: 100
        };

        admin.firestore().collection('usersTEST').doc(String(i)).set(data);
    }
});

exports.giveEveryonePoints2 = functions.https.onRequest((req, response) => {
    let db = admin.firestore()
    let theCollection = 'users'
    db.collection(theCollection).get()
    .then(snapshot => {
        snapshot.forEach(doc => {
            let id = doc.id;
            let oldPoints = doc.data().points;


            if (oldPoints === 0) {
                console.log('Had zero: ' + id);
                db.collection(theCollection).doc(id).update({
                    points: 20
                })
            }

            else if (!oldPoints) {
                console.log('Error points: ' + id);
            } 
            
            else {
                // Initialize document
                db.collection(theCollection).doc(id).update({
                    points: oldPoints + 20
                })
            }

            //OR TRANSACTIONS
            // Initialize document
            // var uRef = db.collection(theCollection).doc(id);

            // // eslint-disable-next-line promise/no-nesting
            // db.runTransaction(t => {
            // // eslint-disable-next-line promise/no-nesting
            // return t.get(uRef)
            //     .then(doc => {
            //     var newPoints = doc.data().points + 25;
            //     t.update(uRef, {points: newPoints});
            //     return 'done'
            //     });
            // }).catch(err => {
            //     console.log(id, 'Transaction failure: ', err);
            // });
        });
        //response.send('done points');
        return 'done';
    })
    .catch(error => {
        console.log(error);
        response.status(500).send(error);
    })
});

//Please be super fucking careful. Use usersTEST please for the love of god oh god that was a bad night
//Dont touch this. Ever.
// exports.giveEveryonePoints = functions.https.onRequest((req, response) => {
//     let db = admin.firestore()
//     db.collection('users').get()
//     .then(snapshot => {
//         snapshot.forEach(doc => {
//             let id = doc.id;
//             let oldPoints = doc.data().points;

//             if (!oldPoints) {
//                 console.log('Error points: ' + id);
//                 oldPoints = 500;
//             }

//             // Initialize document
//             db.collection('users').doc(id).update({
//                 points: oldPoints + 25
//             })
//         });
//         response.send('done');
//         return 'done';
//     })
//     .catch(error => {
//         console.log(error);
//         response.status(500).send(error);
//     })
// });

exports.stealSchoolData = functions.https.onRequest((req, response) => {
    admin.firestore().collection('users').get()
    .then(snapshot => {
        let ids = []
        let datas = []

        snapshot.forEach(doc => {
            const uData = doc.data();
            let id = doc.id;

            let msg = uData.msgToken;
            if(!msg){
                msg = 'error'
            }

            let data = {
                email: uData.email,
                profilePic: uData.profilePic,
                name: uData.name,
                msgToken: msg
            };

            ids.push(id);
            datas.push(data);            
        });
        response.send([ids,datas]);
        return 'stolen';
    })
    .catch(error => {
        console.log(error);
        response.status(500).send(error);
    })
});