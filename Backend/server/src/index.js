const app = require('./app');
const config = require('./config');

const PORT = config.PORT;

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Bhatkanti Backend running on port ${PORT} (0.0.0.0)`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});
