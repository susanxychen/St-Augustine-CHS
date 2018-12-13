const https = require('https');
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp({ credential: admin.credential.applicationDefault()});
const settings = {timestampsInSnapshots: true};
admin.firestore().settings(settings);



//The Edit Votes Function
exports.changeVote = functions.https.onCall((data, context) => {
    const id = data.id;
    const uservote = data.uservote;
    //console.log('Id: ' + id + ' Vote: ' + uservote);

    admin.firestore().doc('songs/' + id).get()
    .then(snapshot => {
        if (snapshot.exists) {
            const songData = snapshot.data();
            
            //Attempt to update the database
            let votes = songData.upvotes;
            if (!votes) {
                votes = 0;
            }
            
            //Prevent vote from going below 0
            if (votes === 0 && uservote < 0){
                return snapshot.ref.set({
                    upvotes: 0
                }, {merge: true});
            }

            return snapshot.ref.set({
                upvotes: votes + uservote
            }, {merge: true});
            
        } else {
            console.log('id doesnt exist')
            response.send('Song Doesnt exist')
            throw new Error('Song doesn\'t Exist')
        }
    })
    .catch(error => {
        //handle the error
        console.log(error);
        response.status(500).send(error);
    });
});

// exports.changeSpiritPointsHTTP = functions.https.onRequest((request, response) => {
//     const grade = "11";
//     const change = -20;

//     admin.firestore().doc('info/spiritPoints').get()
//     .then(snapshot => {
//         if (snapshot.exists) {
//             const spiritData = snapshot.data();
//             let points;

//             //Get the points of each grade
//             switch(grade) {
//                 case "9":
//                     points = spiritData.nine;
//                     break;
//                 case "10":
//                     points = spiritData.ten;
//                     break;
//                 case "11":
//                     points = spiritData.eleven;
//                     break;
//                 case "12":
//                     points = spiritData.twelve;
//                     break;
//             }

//             //Attempt to update the database
//             if (!points) {
//                 response.send('Cannot get grade points');
//                 throw new Error('Cannot Get Points');
//             } else {
//                 //Set the points of each grade
//                 switch(grade){
//                     case "9":
//                         response.send('success 9!');
//                         return snapshot.ref.set({
//                             nine: points + change
//                         }, {merge: true});
//                     case "10":
//                         response.send('success 10!');
//                         return snapshot.ref.set({
//                             ten: points + change
//                         }, {merge: true});
//                     case "11":
//                         response.send('success 11!');
//                         return snapshot.ref.set({
//                             eleven: points + change
//                         }, {merge: true});
//                     case "12":
//                         response.send('success 12!');
//                         return snapshot.ref.set({
//                             twelve: points + change
//                         }, {merge: true});
//                     default:
//                         throw new Error('Cannot find grade');
//                 }
//             }
//         } else {
//             console.log('spirit doesnt exist');
//             response.send('Cannot find spirit points');
//             throw new Error('spirit doesnt exist');
//         }
//     })
//     .catch(error => {
//         //handle the error
//         console.log(error);
//         response.status(500).send(error);
//     });
// });

exports.deleteTopSongs = functions.https.onRequest((request, response) => {
    var songsRef = admin.firestore().collection('songs');
    var allSongs = songsRef.get()
        .then(snapshot => {
            var votes = []
            var ids = []
            var dates = []
            snapshot.forEach(doc => {
                //console.log(doc.id, ' => ', doc.data())
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

            if (ids.length > 3) {
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

                //Delete songs older than 2 days and under 100 votes
                var daysAgo = new Date().getTime() - (2*24*60*60*1000)
                var oldSongIds = []

                for (let i = 0; i < ids.length; i++){
                    if (dates[i] < daysAgo && votes[i] < 100){
                        oldSongIds.push(ids[i]);
                    }
                }

                //Delete the old songs
                for (let i = 0; i < oldSongIds.length; i++){
                    admin.firestore().collection('songs').doc(oldSongIds[i]).delete();
                }

                response.send(oldSongIds + ' ' + maxIDs);
                return oldSongIds;
            } else {
                response.send('not enough songs');
                return 'not enough songs';
            }
        })
        .catch(error => {
            console.log(error);
            response.status(500).send(error);
        })
});

exports.getDayNumber = functions.https.onRequest((request, response) => {
    https.get({
        host: 'staugustinechs.netfirms.com',
        port: 443,
        path: '/stadayonetwo',
        famliy: 4
    }, (resp) => {
    let data = '';

    // A chunk of data has been recieved.
    resp.on('data', (chunk) => {
        data += chunk;
    });

    // The whole response has been received
    resp.on('end', () => {
        var index = data.lastIndexOf("Day ");
        var dayNum = data.substring(index+4, index + 5)
        response.send(dayNum);
        console.log(dayNum);
    });

    }).on("error", (err) => {
        response.send(err.message);
        console.log("Error: " + err.message);
    });

});

// admin.firestore().doc('info/dayNumber').get()
        // .then(snapshot => {
        //     if (snapshot.exists) {
        //         response.send(dayNum);
        //         return snapshot.ref.set({
        //             dayNumber: dayNum
        //         }, {merge: true});
        //     } else {
        //         console.log('no day number')
        //         response.send('no day number')
        //         throw new Error('no day number')
        //     }
        // })
        // .catch(error => {
        //     //handle the error
        //     console.log(error);
        //     response.status(500).send(error);
        // });