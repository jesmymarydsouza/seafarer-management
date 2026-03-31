const express = require('express');
const bodyParser = require('body-parser');
const db = require('./database');
const app = express();

app.set('view engine', 'ejs');
app.set('views', './views');
app.use(express.static('public'));
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

app.use('/seafarers', require('./routes/seafarers'));
app.use('/vessels',   require('./routes/vessels'));
app.use('/contracts', require('./routes/contracts'));
app.use('/certs',     require('./routes/certifications'));
app.use('/reports',   require('./routes/reports'));

app.get('/', (req, res) => {
  const queries = {
    totalSeafarers: 'SELECT COUNT(*) AS cnt FROM seafarers',
    totalVessels:   'SELECT COUNT(*) AS cnt FROM vessels',
    activeContracts:'SELECT COUNT(*) AS cnt FROM contracts WHERE contract_status="Active"',
    recentLogs:     'SELECT * FROM audit_log ORDER BY action_time DESC LIMIT 5'
  };
  const results = {};
  const keys = Object.keys(queries);
  let done = 0;
  keys.forEach(key => {
    db.query(queries[key], (err, rows) => {
      results[key] = err ? [] : rows;
      if (++done === keys.length) res.render('dashboard', results);
    });
  });
});

app.listen(3000, () => console.log('Seafarer Management System running at http://localhost:3000'));
