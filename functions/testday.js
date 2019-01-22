const https = require('follow-redirects').http;

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
    //console.log(data);
    if (data.includes("All school buses, vans and taxis servicing the YORK CATHOLIC and YORK REGION DISTRICT SCHOOL BOARD&nbsp; are cancelled")) {
        console.log('snow day');
        
    } else {
        console.log('not snow day');
    }
});
}).on("error", (err) => {
    response.send("Error checking snow day: " + err.message);
    console.log("Error: " + err.message);
});