const express = require('express');
const bodyParser = require('body-parser');
const session = require('express-session');
const db = require('./database');
const app = express();

app.use(session({ secret: 'seafarer_secret', resave: false, saveUninitialized: false }));

const requireLogin = (req, res, next) => {
  if (req.session.loggedIn) return next();
  res.redirect('/login');
};

app.set('view engine', 'ejs');
app.set('views', './views');
app.use(express.static('public'));
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

app.get('/login',  (req, res) => res.render('login', { error: null }));
app.post('/login', (req, res) => {
  const { username, password } = req.body;
  if (username === 'admin' && password === '1234') {
    req.session.loggedIn = true;
    res.redirect('/');
  } else {
    res.render('login', { error: 'Invalid username or password!' });
  }
});
app.get('/logout', (req, res) => { req.session.destroy(); res.redirect('/login'); });

app.use('/seafarers', requireLogin, require('./routes/seafarers'));
app.use('/vessels',   requireLogin, require('./routes/vessels'));
app.use('/contracts', requireLogin, require('./routes/contracts'));
app.use('/certs',     requireLogin, require('./routes/certifications'));
app.use('/reports',   requireLogin, require('./routes/reports'));

app.get('/', requireLogin, (req, res) => {
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
