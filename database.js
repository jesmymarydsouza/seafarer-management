const mysql = require('mysql2');

const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'abc123',       // <-- change to your MySQL password
  database: 'seafarer_db',
  multipleStatements: true
});

db.connect(err => {
  if (err) { console.error('DB connection failed:', err); process.exit(1); }
  console.log('MySQL connected.');
});

module.exports = db;
