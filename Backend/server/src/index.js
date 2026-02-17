const app = require('./app');
const config = require('./config');

const PORT = config.PORT;

app.listen(PORT, () => {
    console.log(`Bhatkanti Backend running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});
