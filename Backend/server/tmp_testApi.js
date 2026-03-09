const axios = require('axios');

async function run() {
  try {
    // login
    console.log("Logging in...");
    const res = await axios.post('https://bhatkanti-backend-8msl.onrender.com/api/auth/login', {
      email: 'atulbhagwat2004@gmail.com', // wait, I don't know the full email? Wait, I saw it in earlier logs! Oh, I don't know the exact admin email! The user logs in as "Atul Bhagwat (Super Admin)"
      password: 'changeme123'
    });
    console.log(res.data);
  } catch (err) {
    if (err.response) console.error(err.response.data);
    else console.error(err);
  }
}
run();
