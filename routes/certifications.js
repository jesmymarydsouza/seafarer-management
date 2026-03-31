const express = require('express');
const router = express.Router();
const db = require('../database');

router.get('/', (req, res) => {
  const msg = req.query.msg || null;
  const detail = req.query.detail || null;
  db.query('SELECT * FROM certification_status ORDER BY full_name', (err, rows) => {
    db.query('SELECT c.cert_id, s.full_name, c.cert_name, c.issued_date, c.expiry_date, c.issuing_authority, c.seafarer_id FROM certifications c JOIN seafarers s ON c.seafarer_id=s.seafarer_id', (e2, full) => {
      db.query('SELECT seafarer_id, full_name FROM seafarers ORDER BY full_name', (e3, seafarers) => {
        res.render('certifications', { certs: rows || [], fullCerts: full || [], seafarers: seafarers || [], msg, detail });
      });
    });
  });
});

router.post('/add', (req, res) => {
  const { seafarer_id, cert_name, issued_date, expiry_date, issuing_authority } = req.body;
  db.query('INSERT INTO certifications (seafarer_id,cert_name,issued_date,expiry_date,issuing_authority) VALUES (?,?,?,?,?)',
    [seafarer_id, cert_name, issued_date, expiry_date, issuing_authority],
    (err) => {
      if (err) return res.redirect('/certs?msg=error&detail=' + encodeURIComponent(err.sqlMessage));
      res.redirect('/certs?msg=added');
    });
});

router.post('/delete', (req, res) => {
  db.query('DELETE FROM certifications WHERE cert_id=?', [req.body.cert_id],
    (err) => {
      if (err) return res.redirect('/certs?msg=error&detail=' + encodeURIComponent(err.sqlMessage));
      res.redirect('/certs?msg=deleted');
    });
});

module.exports = router;
