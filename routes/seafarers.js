const express = require('express');
const router = express.Router();
const db = require('../database');

router.get('/', (req, res) => {
  const msg = req.query.msg || null;
  const detail = req.query.detail || null;
  db.query('SELECT * FROM seafarer_details ORDER BY seafarer_id', (err, rows) => {
    db.query('SELECT * FROM ranks', (e2, ranks) => {
      res.render('seafarers', { seafarers: rows || [], ranks: ranks || [], error: err, msg, detail });
    });
  });
});

router.post('/add', (req, res) => {
  const { full_name, date_of_birth, nationality, passport_no, email, phone, rank_id } = req.body;
  db.query('INSERT INTO seafarers (full_name,date_of_birth,nationality,passport_no,email,phone,rank_id) VALUES (?,?,?,?,?,?,?)',
    [full_name, date_of_birth, nationality, passport_no, email, phone, rank_id],
    (err) => {
      if (err) return res.redirect('/seafarers?msg=error&detail=' + encodeURIComponent(err.sqlMessage));
      res.redirect('/seafarers?msg=added');
    });
});

router.post('/update', (req, res) => {
  const { seafarer_id, full_name, nationality, email, phone, rank_id, status } = req.body;
  db.query('UPDATE seafarers SET full_name=?,nationality=?,email=?,phone=?,rank_id=?,status=? WHERE seafarer_id=?',
    [full_name, nationality, email, phone, rank_id, status, seafarer_id],
    (err) => {
      if (err) return res.redirect('/seafarers?msg=error&detail=' + encodeURIComponent(err.sqlMessage));
      res.redirect('/seafarers?msg=updated');
    });
});

router.post('/delete', (req, res) => {
  db.query('DELETE FROM seafarers WHERE seafarer_id=?', [req.body.seafarer_id],
    (err) => {
      if (err) return res.redirect('/seafarers?msg=error&detail=' + encodeURIComponent(err.sqlMessage));
      res.redirect('/seafarers?msg=deleted');
    });
});

module.exports = router;
